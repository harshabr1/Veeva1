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

global  with sharing  class VEEVA_ASYNC_ADDRESS_PUSH {

  // Map to contain the fieldlists by Country Code  
  static Map<String,List<String>> fieldsByCountryCode = new Map<String,List<String>>();
  static Map<String,String> recTypeMap = new Map<String,String> ();
  // List of unique fields thats need to be queried from address
  static Set <String> uniqueFields = new Set<String>();
  
 
  // Defualt fields to select from address.
  static String sAddrSelctField = 'Id,Name,RecordTypeId,RecordType.DeveloperName,Country_vod__c,Account_vod__c';
  
  // Grab shape of address
  static Address_vod__c addrShape = new Address_vod__c();
  static Schema.sObjectType addrType = addrShape.getSObjectType();
  
   
  private static void initClass() {


    // Fields we have to have to make this work.    
    uniqueFields.add('Id');
    uniqueFields.add('Name');
    uniqueFields.add('Country_vod__c');
    uniqueFields.add('RecordTypeId');
    uniqueFields.add('RecordType.DeveloperName');
    uniqueFields.add('Account_vod__c');
    
    for (RecordType rec : [Select Id,DeveloperName from RecordType where SobjectType ='Address_vod__c']) {
        recTypeMap.put (rec.DeveloperName, rec.Id);
    }
    
    // Load messages for fields by country.  Pre processes into easier to use datatypes
    for (Message_vod__c msgCat : 
         [Select Name, Text_vod__c 
         from Message_vod__c 
         Where Name 
         like 'ACCT_HIER_ADDR_COPY_FIELDS%' and Active_vod__c = true]) {
         
         if (msgCat.Text_vod__c != null) {
            
            String[] arrFields =  msgCat.Text_vod__c.split(',');
            List<String> fieldsFor = new List<String> ();
            
            for (String fieldname : arrFields) {
                fieldsFor.add(fieldname);
                if (uniqueFields.contains(fieldname) == false)
                    sAddrSelctField += ',' + fieldname;
                uniqueFields.add(fieldname);
                
            }
            
            fieldsByCountryCode.put(msgCat.Name,fieldsFor);
         }
     }
  }
  
  @future
  global static void  start(String accountids) {
    System.debug ('Starting ' + accountids);
    initClass();
    String acctFilterIds = '';
    Map<String, Map<String,List<SObject>>> accountData = new Map<String, Map<String,List<SObject>>>();
    
    String selChildAcct = 'Select Id, Parent_Account_vod__c, Child_Account_vod__c ' + 
                            'From Child_Account_vod__c ' + 
                            'Where Copy_Address_vod__c = true And Parent_Account_vod__c In (' +
                            accountids + 
                            ')';
    
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
                            ')';
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
        
        execute(accountData);           
    }  
  }
  
  private static void execute(Map<String, Map<String,List<SObject>>>  batch) {
    List<Address_vod__c> upsertsList = new List<Address_vod__c> ();
    Schema.SObjectField extId = Address_vod__c.External_ID_vod__c;
    VOD_ADDRESS_TRIG.setPush(true);
    // loop through the batch.
    Set<String> acctKeys = batch.keySet();
    for (String acctId : acctKeys) {
        Map<String, List<SObject>> account = batch.get(acctId);
        List<SObject> addresses = account.get('Address_vod__c');
        for (SObject addrSobj : addresses) {
            Address_vod__c addr = (Address_vod__c)addrSobj;
            String RecordTypeName = addr.RecordType.DeveloperName;
            String childRecordTypeName = addr.RecordType.DeveloperName + '_CHILD';
            
            String recId = recTypeMap.get(childRecordTypeName);
            
            if (recId == null) {
                recId = addr.RecordTypeId;
            }
            
            String country  = addr.Country_vod__c;
            String addressKey = 'ACCT_HIER_ADDR_COPY_FIELDS' + '_' + addr.Country_vod__c;
            String [] countryfields = fieldsByCountryCode.get(addressKey);
            
            if (countryfields == null)
                countryfields = fieldsByCountryCode.get('ACCT_HIER_ADDR_COPY_FIELDS');
            
            List<SObject> childAccounts = account.get('Child_Account_vod__c');            
            for (SObject chldAccSobj : childAccounts) {
                Child_Account_vod__c chldAcc = (Child_Account_vod__c)chldAccSobj;
                sObject updSobj = addrType.newSObject();
                String externalId = chldAcc.Child_Account_vod__c + '_' + addr.Id;
                
                updSobj.put('External_Id_vod__c',externalId);
                updSobj.put('Account_vod__c', chldAcc.Child_Account_vod__c);
                updSobj.put('Controlling_Address_vod__c', addr.Id);
                updSobj.put('Controlled_Address_vod__c', true);
                updSobj.put('RecordTypeId',recId);
                if (countryfields != null) {
                    for (String fieldName : countryfields) {
                        if ('Id'.equals(fieldName))
                            continue;
                        if ('RecordTypeId'.equals(fieldName))
                            continue;   
                        if ('RecordType.DeveloperName'.equals(fieldName))
                            continue;
                            
                        Object fieldVal = addrSobj.get(fieldName);
                        if (fieldVal == null)
                        {
                            continue;
                        }
                        if (fieldVal instanceOf String)
                        {
                            updSobj.put(fieldName, (String) fieldVal);
                        }
                        else
                        {
                            updSobj.put(fieldName, fieldVal);
                        }
                    }
                }
            
                upsertsList.add((Address_vod__c)updSobj);
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

  global static void deletePushedAccounts (String csIdlist) {
         if (System.isBatch() || System.isFuture()) {
             deletePushedAddress(csIdlist);
         } else {
             deletePushedAddressFuture(csIdlist);
         }
  }

 @future
 global static void deletePushedAddressFuture (String csIdlist) {
    deletePushedAddress(csIdlist);
 }

 global static void deletePushedAddress(String csIdlist) {
     String [] ids = csIdlist.split(',');
     List<Address_vod__c> addList = new List<Address_vod__c>();
     for (String id : ids ) {
     Address_vod__c delAddr = new Address_vod__c(Id = id);
     addList.add(delAddr);
     }
     try {
         delete addList;
     } catch (System.Dmlexception e) {
     }
 }
}