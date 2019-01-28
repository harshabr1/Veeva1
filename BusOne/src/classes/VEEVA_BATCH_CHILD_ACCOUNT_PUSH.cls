/******************************************************************************
*                                                                              
*               Confidentiality Information:
*
* This module is the confidential and proprietary information of
* Verticals onDemand, Inc.; it is not to be copied, reproduced, or transmitted
* in any form, by any means, in whole or in part, nor is it to be used
* for any purpose other than that for which it is expressly provided
* without the written permission of Verticals onDemand.
* 
* Copyright (c) 2011 Veeva Systems, Inc.  All Rights Reserved.
*
*******************************************************************************/

global  with sharing  class VEEVA_BATCH_CHILD_ACCOUNT_PUSH implements Database.Batchable<sObject> {
    
    private final String initialState;
    // Contains the time we started to process the address push. 
    private Datetime starttime;
    // Map to contain the fieldlists by Country Code  
    Map<String,Set<String>> fieldsByCountryCode = new Map<String,Set<String>>();
    Map<String,String> recTypeMap = new Map<String,String> ();
    // List of unique fields thats need to be queried from address
    Set <String> uniqueFields = new Set<String>();
    
    // Contians the time of the last sync
    Datetime lastSync = VeevaSettings.getAddressDatetime();
    
    // Defualt fields to select from address.
    String sAddrSelctField = 'Id,Name,RecordTypeId, RecordType.DeveloperName, Country_vod__c,Account_vod__c,Primary_vod__c';
    
    // Grab shape of address
    Address_vod__c addrShape = new Address_vod__c();
    Schema.sObjectType addrType = addrShape.getSObjectType();
    
    global VEEVA_BATCH_CHILD_ACCOUNT_PUSH() {
        // Need to know when we started so that we can mark the Last Run Time in veeva settings.  
        // We take the start time not the finish time so that we can catch anything that may 
        // have changed while this is running.
        starttime = System.now();
        
        // Fields we have to have to make this work.    
        uniqueFields.add('Id');
        uniqueFields.add('Name');
        uniqueFields.add('Country_vod__c');
        uniqueFields.add('RecordTypeId');
        uniqueFields.add('RecordType.DeveloperName');
        uniqueFields.add('Account_vod__c');
        uniqueFields.add('Primary_vod__c');
        
        for (RecordType rec : [Select Id,DeveloperName from RecordType where SobjectType ='Address_vod__c']) {
            recTypeMap.put (rec.DeveloperName, rec.Id);
        }
        
        // Load messages for fields by country.  Pre processes into easier to use datatypes
        Set<String> excludes = new Set<String>();
        excludes.add('Id');
        excludes.add('RecordTypeId');
        excludes.add('RecordType.DeveloperName');
        for (Message_vod__c msgCat : 
             [Select Name, Text_vod__c 
              from Message_vod__c 
              Where Name 
              like 'ACCT_HIER_ADDR_COPY_FIELDS%' and Active_vod__c = true]) {
                  
                  if (msgCat.Text_vod__c != null) {
                      
                      String[] arrFields =  msgCat.Text_vod__c.split(',');
                      Set<String> fieldsFor = new Set<String> ();
                      
                      for (String fieldname : arrFields) {
                          if (!excludes.contains(fieldname))
                              fieldsFor.add(fieldname);
                          if (uniqueFields.contains(fieldname) == false) {
                              sAddrSelctField += ',' + fieldname;
                              uniqueFields.add(fieldname);
                          }              
                      }           
                      fieldsByCountryCode.put(msgCat.Name,fieldsFor);
                  }
              }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        // This is the base query that dirves the chunking.
        // Basic query logic is to grab accounts where Copy_Address_vod__c is true on Child Account
        // and addresses that have changed since the last run.  We default the first run as
        // 1900-01-01. Any address created before that time will be missed.   
        String selStmt = 'Select Id' +
            ' from Account' + 
            ' where Id in (Select Parent_Account_vod__c ' + 
            ' from Child_Account_vod__c where Copy_Address_vod__c = true) ' + 
            ' and Id in (Select Account_vod__c  from address_vod__c where SystemModstamp >= ' +
            lastSync.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +') ';
        
        System.debug(selStmt);
        return Database.getQueryLocator(selStmt);
        
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
        String accountids = '';
        for (sObject sObj : batch) {
            if (accountids.length() > 0) {
                accountids += ',';
            }
            accountids += '\'' + sObj.Id + '\'';
        }
        
        Map<String, Map<String,List<SObject>>> accountData = new Map<String, Map<String,List<SObject>>>();
        
        String selChildAcct = 'Select Id, Parent_Account_vod__c, Child_Account_vod__c, Primary_vod__c ' + 
            'From Child_Account_vod__c ' + 
            'Where Copy_Address_vod__c = true And Parent_Account_vod__c In (' +
            accountids + 
            ') and Child_Account_vod__c != null';
        String acctFilterIds = '';
        List<Child_Account_vod__c> objects = Database.query(selChildAcct);
        for (Child_Account_vod__c childAcctSObj : objects) {
            Map<String, List<SObject>> acctObj = accountData.get(childAcctSObj.Parent_Account_vod__c);
            if (acctObj == null) {
                acctObj = new Map<String, List<SObject>>();
                accountData.put(childAcctSObj.Parent_Account_vod__c, acctObj);
                if (acctFilterIds.length() > 0) {
                    acctFilterIds += ',';
                }
                acctFilterIds += '\'' + childAcctSObj.Parent_Account_vod__c + '\'';
            }
            List<SObject> childRows = acctObj.get('Child_Account_vod__c');
            if (childRows == null) {
                childRows = new List<SObject>();
                acctObj.put('Child_Account_vod__c', childRows);
            }
            childRows.add(childAcctSObj);
        }
        
        if (acctFilterIds.length() > 0) {
            String selAddrStmt = 'Select ' +
                sAddrSelctField +
                ' From Address_vod__c' + 
                ' Where Account_vod__c In (' +
                acctFilterIds + 
                ') And SystemModstamp >= ' +
                lastSync.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            List<Address_vod__c> addressObjects = Database.query(selAddrStmt);
            for (Address_vod__c addrSObj : addressObjects) {
                Map<String, List<SObject>> acctObj = accountData.get(addrSObj.Account_vod__c);
                List<SObject> addrRows = acctObj.get('Address_vod__c');
                if (addrRows == null) {
                    addrRows = new List<SObject>();
                    acctObj.put('Address_vod__c', addrRows);
                }
                addrRows.add(addrSObj);
            }
        }
             
        List<Address_vod__c> upsertsList = new List<Address_vod__c> ();
        Schema.SObjectField extId = Address_vod__c.External_ID_vod__c;
        VOD_ADDRESS_TRIG.setPush(true);
        // loop through the batch.
        Set<String> acctKeys = accountData.keySet();
        for (String acctId : acctKeys) {
            Map<String, List<SObject>> account = accountData.get(acctId);
            List<Address_vod__c> addresses = account.get('Address_vod__c');
            for (Address_vod__c addr : addresses) {               
                String recId = recTypeMap.get(addr.RecordType.DeveloperName + '_CHILD');         
                if (recId == null) {
                    recId = addr.RecordTypeId;
                }           
                Set<String> countryfields = fieldsByCountryCode.get('ACCT_HIER_ADDR_COPY_FIELDS' + '_' + addr.Country_vod__c);           
                if (countryfields == null) {
                    countryfields = fieldsByCountryCode.get('ACCT_HIER_ADDR_COPY_FIELDS');
                    if (countryfields == null) {
                        fieldsByCountryCode.put('ACCT_HIER_ADDR_COPY_FIELDS', new Set<String> ()); 
                        countryfields = fieldsByCountryCode.get('ACCT_HIER_ADDR_COPY_FIELDS');
                    }
                }
                
                List<Child_Account_vod__c> childAccounts = account.get('Child_Account_vod__c');            
                for (Child_Account_vod__c chldAcc : childAccounts) {
                    Address_vod__c updSobj = new Address_vod__c();              
                    updSobj.put('External_Id_vod__c',chldAcc.Child_Account_vod__c + '_' + addr.Id);
                    updSobj.put('Account_vod__c', chldAcc.Child_Account_vod__c);
                    updSobj.put('Controlling_Address_vod__c', addr.Id);
                    updSobj.put('Controlled_Address_vod__c', true);
                    updSobj.put('Primary_vod__c', addr.Primary_vod__c && chldAcc.Primary_vod__c == System.label.Common_Yes_vod);
                    updSobj.put('RecordTypeId',recId);
                    
                    for (String fieldName : countryfields) {     
                        Object fieldVal = addr.get(fieldName);
                        if (fieldVal == null)
                        {
                            continue;
                        }
                        updSobj.put(fieldName, fieldVal);
                    }                    
                    upsertsList.add(updSobj);
                }
                    
                // We processes the updates 10 at a time.
                if (upsertsList.size () >10) {
                    System.debug(upsertsList);
                    try {                           
                        Database.UpsertResult[] ups = Database.Upsert(upsertsList, extId, true);                         
                    } catch (DmlException e) {
                        // If we fail, we touch the parent so it will be picked up in the next run.
                        List<Address_vod__c> touchControlling = new List<Address_vod__c>();
                        Set<String> errorIds = new Set<String> ();
                        for (Address_vod__c addFail : upsertsList) {
                            String myId = addFail.Controlling_Address_vod__c;
                            String name = addFail.Name;
                            if (errorIds.contains(myId) == false) {
                                Address_vod__c ad = new Address_vod__c (Id = addFail.Controlling_Address_vod__c,Name = name);
                                touchControlling.add(ad);
                                errorIds.add(myId);
                            }
                        }
                        
                        try {                               
                            System.debug('Array of failed addresses ' + touchControlling);
                            VOD_ADDRESS_TRIG.setAddressTrig(true);
                            Database.update (touchControlling,false);
                        } catch (DmlException e2) {
                            // We ignore errors but here is some debug
                            System.debug ('Veeva Error' + e2);                          
                        } finally {
                            VOD_ADDRESS_TRIG.setAddressTrig(false);
                        }
                    }                     
                    upsertsList.clear(); 
                }
            }
        }
        
        if (upsertsList.size () > 0) {
            try {   
                System.debug(upsertsList);
                Database.UpsertResult[] ups = Database.upsert(upsertsList, extId, true);
            } catch (DmlException e) {
                System.debug('Array of failed child addresses ' + upsertsList);
                List<Address_vod__c> touchControlling = new List<Address_vod__c>();
                Set<String> errorIds = new Set<String> ();
                for (Address_vod__c addFail : upsertsList) {
                    String myId = addFail.Controlling_Address_vod__c;
                    String name = addFail.Name;
                    if (errorIds.contains(myId) == false) {
                        Address_vod__c ad = new Address_vod__c (Id = addFail.Controlling_Address_vod__c,Name = name);
                        touchControlling.add(ad);
                        errorIds.add(myId);
                    }
                }
                
                try {
                    System.debug('Array of parent addresses ' + touchControlling);
                    VOD_ADDRESS_TRIG.setAddressTrig(true);
                    Database.update (touchControlling,false);
                    
                } catch (DmlException e2) {                   
                    // We ignore errors but here is some debug
                    System.debug('Array of failed parent addresses ' + touchControlling);
                    System.debug ('Veeva Error' + e2);  
                } finally {
                    VOD_ADDRESS_TRIG.setAddressTrig(false);
                    VOD_ADDRESS_TRIG.setPush(false);
                }
            }
        }
        VOD_ADDRESS_TRIG.setPush(false);
    }
    
    global void finish(Database.BatchableContext BC) {
        // update the runtime.
        VeevaSettings.setAddressDatetime(starttime);
    }
    
}