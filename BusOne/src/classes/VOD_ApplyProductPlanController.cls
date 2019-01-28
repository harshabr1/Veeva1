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
 * Copyright (c) 2009 Verticals onDemand, Inc.  All Rights Reserved.
 *
 ******************************************************************************/
public with sharing class VOD_ApplyProductPlanController {
        
            private List<ProductStrategyRow> theSList = null;
            private List<ProductTacticRow> theTList = null;
            private Integer mode = -1;
            private Account_Plan_vod__c acctPlan = null;
            
            /* Javascript include */
            public String getInclude() {
                SControl vsession = [Select HtmlWrapper From Scontrol Where Name = 'VSESSION'];
        
                String vod_server_url = null;
                String vod_version = null;
                String[] lines = vsession.HtmlWrapper.split(';');
                for (Integer i = 0; i < lines.size(); i++) {
                    String[] splits = lines[i].split('=');
                    String name = '';
                    if (splits != null && splits.size() >= 2) {
                        Integer index = splits[0].indexOf('var ');
                        if (index >= 0) {
                            name = splits[0].substring(index + 4);
                        }
                    }
                    if (name == 'VOD_SERVER_URL')
                        vod_server_url = splits[1].replaceAll('"', '');
                    else if (name == 'VOD_VERSION') {
                        vod_version = splits[1].replaceAll('"', '');
                    }
                }
                
                return vod_server_url + '/' + vod_version + '/js/vodvfcommon.js';
            }
            
            /* Cancel navigation */
            public PageReference cancel() {
                String acctPlanId = ApexPages.currentPage().getParameters().get('id');
                if ((acctPlanId == null) || (acctPlanId == ''))
                    return null;
                    
                PageReference pageRef = new PageReference('/' + acctPlanId);
                return pageRef;
            }
        
            /* Save navigation */
            public PageReference save() {
                Account_Plan_vod__c thePlan = loadAccountPlan();
                if (thePlan == null) {
                    return null;
                }
                
                if (theSList != null) {
                    // create Account Tactics based off selected Product Strategies
                    String stratIdList = '';
                    for (ProductStrategyRow strat : theSList) {
                        if (strat.selected) {
                            if (stratIdList.length() > 0)
                                stratIdList += ',';
                            stratIdList += '\'' + strat.Id + '\'';
                        }
                    }
        
                    // if strategies were selected, continue save processing
                    if (stratIdList.length() > 0) {
                        // find same name fields and copy over
                        Map<String,Schema.SObjectField> acctTacticFields = Schema.sObjectType.Account_Tactic_vod__c.fields.getMap();
                        Map<String,Schema.SObjectField> prodTacticFields = Schema.sObjectType.Product_Tactic_vod__c.fields.getMap();
            
                        List<String> prdTacticFldList = new List<String>();
                        String prdTacticFlds = '';
                        if (acctTacticFields != null) {
                            for (Schema.SObjectField atFldToken : acctTacticFields.values()) {
                                Schema.DescribeFieldResult atDescrFld = atFldToken.getDescribe();
                                if (atDescrFld.isUpdateable() && (atDescrFld.getName() != 'RecordTypeId')) {
                                    Schema.SObjectField ptFldToken = prodTacticFields.get(atDescrFld.getName());
                                    if (ptFldToken != null) {
                                        Schema.DescribeFieldResult ptDescrFld = ptFldToken.getDescribe();
                                        if (ptDescrFld.isAccessible()) {
                                            prdTacticFldList.add(ptDescrFld.getName());
                                            if (prdTacticFlds.length() > 0)
                                                prdTacticFlds += ',';
                                            prdTacticFlds += ptDescrFld.getName();
                                        }
                                    }
                                }
                            }
                        }
                        
                        // retrieve values and create new account tactics
                        List<SObject> qTactics = Database.query('Select '+prdTacticFlds+' From Product_Tactic_vod__c Where Product_Strategy_vod__c In (' +
                                stratIdList + ') And Active_vod__c=true');
                        
                        if ((qTactics != null) && (qTactics.size() > 0)) {
                            List<Account_Tactic_vod__c> newAcctTactics = new List<Account_Tactic_vod__c>();
        
                            for (SObject qTactic : qTactics) {
                                Account_Tactic_vod__c newAcctTactic = new Account_Tactic_vod__c();
                                for (String fldName : prdTacticFldList) {
                                    Object value = qTactic.get(fldName);
                                    if (value != null) {
                                        newAcctTactic.put(fldName, value);
                                    }
                                }
                                newAcctTactic.put('Account_Plan_vod__c', thePlan.Id);
                                newAcctTactic.put('Account_vod__c', acctPlan.Account_vod__c);
                                newAcctTactic.put('Product_Tactic_vod__c', qTactic.Id);
        
                                newAcctTactics.add(newAcctTactic);
                            }
            
                            if ((newAcctTactics != null) && (newAcctTactics.size() > 0)) {
                                try {
                                    insert newAcctTactics;
                                }
                                catch (DmlException e) {
                                    for (Integer i=0; i<e.getNumDml(); i++) {
                                        String logMsg = e.getDmlType(i) + ': ' + e.getDmlMessage(i);
                                        String[] errFlds = e.getDmlFieldNames(i);
                                        if (errFlds != null) {
                                            logMsg += '(';
                                            for (Integer j=0; j<errFlds.size(); j++) {
                                                if (j>0)
                                                    logMsg += ', ';
                                                logMsg += errFlds[j];
                                            }
                                            logMsg += ')';
                                        }
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, logMsg));
                                    }
                                    // Error found, keep user on same page to display messages
                                    return null;
                                }
                            }
                        }
                    }
                }
                
                if (theTList != null) {
                    // create Account Tactics based off selected Product Tactics
                    String tacticIdList = '';
                    for (ProductTacticRow tactic : theTList) {
                        if (tactic.selected) {
                            if (tacticIdList.length() > 0)
                                tacticIdList += ',';
                            tacticIdList += '\'' + tactic.Id + '\'';
                        }
                    }
                    
                    // if tactics were selected, continue save processing
                    if (tacticIdList.length() > 0) {
                        // find same name fields and copy over
                        Map<String,Schema.SObjectField> acctTacticFields = Schema.sObjectType.Account_Tactic_vod__c.fields.getMap();
                        Map<String,Schema.SObjectField> prodTacticFields = Schema.sObjectType.Product_Tactic_vod__c.fields.getMap();
            
                        List<String> prdTacticFldList = new List<String>();
                        String prdTacticFlds = '';
                        if (acctTacticFields != null) {
                            for (Schema.SObjectField atFldToken : acctTacticFields.values()) {
                                Schema.DescribeFieldResult atDescrFld = atFldToken.getDescribe();
                                String fieldName = atDescrFld.getName();
                                if (fieldName == 'RecordTypeId')
                                	continue;
                                if (atDescrFld.isCreateable()) {
                                    Schema.SObjectField ptFldToken = prodTacticFields.get(fieldName);
                                    if (ptFldToken != null) {
                                        Schema.DescribeFieldResult ptDescrFld = ptFldToken.getDescribe();
                                        if (ptDescrFld.isAccessible()) {
                                            prdTacticFldList.add(ptDescrFld.getName());
                                            if (prdTacticFlds.length() > 0)
                                                prdTacticFlds += ',';
                                            prdTacticFlds += ptDescrFld.getName();
                                        }
                                    }
                                }
                            }
                        } 
            
                        // retrieve values and create new account tactics
                        List<SObject> qTactics = Database.query('Select '+prdTacticFlds+' From Product_Tactic_vod__c Where Id In (' +
                                tacticIdList + ')');
                                    
                        if ((qTactics != null) && (qTactics.size() > 0)) {
                            List<Account_Tactic_vod__c> newAcctTactics = new List<Account_Tactic_vod__c>();            
                            for (SObject qTactic : qTactics) {
                                Account_Tactic_vod__c newAcctTactic = new Account_Tactic_vod__c();
                                for (String fldName : prdTacticFldList) {
                                    Object value = qTactic.get(fldName);
                                    if (value != null) {
                                        newAcctTactic.put(fldName, value);
                                    }
                                }
                                newAcctTactic.put('Account_Plan_vod__c', thePlan.Id);
                                newAcctTactic.put('Account_vod__c', acctPlan.Account_vod__c);
                                newAcctTactic.put('Product_Tactic_vod__c', qTactic.Id);
        
                                newAcctTactics.add(newAcctTactic);
                            }
            
                            if ((newAcctTactics != null) && (newAcctTactics.size() > 0)) {
                                try {
                                    insert newAcctTactics;
                                }
                                catch (DmlException e) {
                                    for (Integer i=0; i<e.getNumDml(); i++) {
                                        String logMsg = e.getDmlType(i) + ': ' + e.getDmlMessage(i);
                                        String[] errFlds = e.getDmlFieldNames(i);
                                        if (errFlds != null) {
                                            logMsg += '(';
                                            for (Integer j=0; j<errFlds.size(); j++) {
                                                if (j>0)
                                                    logMsg += ', ';
                                                logMsg += errFlds[j];
                                            }
                                            logMsg += ')';
                                        }
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, logMsg));
                                    }
                                    // Error found, keep user on same page to display messages
                                    return null;
                                }
                            }
                        }
                    }
                }
                
                // return user back to account plan
                PageReference pageRef = new PageReference('/' + thePlan.Id);
                return pageRef;
            }
        
            /* Details of account plan */
            private Account_Plan_vod__c loadAccountPlan() {
                if (acctPlan == null) {
                    String acctPlanId = ApexPages.currentPage().getParameters().get('id');
                    if ((acctPlanId == null) || (acctPlanId == '')) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Account plan id is not specified'));
                        return null;
                    }
                    try {
                        acctPlan = [Select Id,Name,Account_vod__c From Account_Plan_vod__c where Id=:acctPlanId];
                    }
                    catch (System.QueryException e) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Account plan cannot be found'));
                        return null;
                    }
                }
                return acctPlan;
            }
            
            /* Configuration parameter to determine whether tactics should be displayed individually or not */
            private Integer loadMode() {
                if (mode < 0) {
                    Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
                    if (settings != null) {
                        if (settings.ENABLE_TACTIC_LIST_vod__c)
                            mode = 1;
                        else
                            mode = 0;
                    } else {
                        try {
                            Message_vod__c config = [Select Text_vod__c From Message_vod__c Where Category_vod__c='ProductPlan' And 
                                    Name='ENABLE_TACTIC_LIST' And Active_vod__c=true And Language_vod__c=:UserInfo.getLocale()];
                            if ('true'.equalsIgnoreCase(config.Text_vod__c))
                                mode = 1;
                            else
                                mode = 0;
                        }
                        catch (System.QueryException e) {
                            if (!'en_US'.equalsIgnoreCase(UserInfo.getLocale())) {
                                try {
                                    Message_vod__c config = [Select Text_vod__c From Message_vod__c Where Category_vod__c='ProductPlan' And 
                                            Name='ENABLE_TACTIC_LIST' And Active_vod__c=true And Language_vod__c='en_US'];
                                    if ('true'.equalsIgnoreCase(config.Text_vod__c))
                                        mode = 1;
                                    else
                                        mode = 0;
                                }
                                catch (System.QueryException e1) {
                                }
                            }
                        }
                    }
                }
                return mode;
            }
            
            public boolean getShowTactics() {
                return (loadMode() > 0);
            }
            
            public boolean getHideTactics() {
                return (loadMode() <= 0);
            }
        
            /* Get list of product strategies to apply */
            public List<ProductStrategyRow> getProductStrategies() {
        
                if (theSList == null) {
                    theSList = new List<ProductStrategyRow>();
        
                    String prodId = ApexPages.currentPage().getParameters().get('pid');
                    List<Product_Strategy_vod__c> qStrategies = null;
                    
                    if ((prodId == null) || (prodId == '')) {
                        qStrategies = [Select Id,Description_vod__c,Name,Product_Plan_vod__c,Product_Plan_vod__r.Name 
                                From Product_Strategy_vod__c
                                Where Product_Plan_vod__r.Active_vod__c=true And Active_vod__c=true
                                Order By Product_Plan_vod__r.Name,Name];            
                    }
                    else {
                        qStrategies = [Select Id,Description_vod__c,Name,Product_Plan_vod__c,Product_Plan_vod__r.Name 
                                From Product_Strategy_vod__c
                                Where Product_Plan_vod__r.Active_vod__c=true And Active_vod__c=true And Product_Plan_vod__r.Product_vod__c=:prodId
                                Order By Product_Plan_vod__r.Name,Name];
                    }
                    
                    List<Id> stratIds = new List<String>();
                    for (Product_Strategy_vod__c qStrat : qStrategies) {
                        stratIds.add(qStrat.Id);
                    }
                    
                    List<Product_Tactic_vod__c> qTactics = [Select Id,Product_Strategy_vod__c From Product_Tactic_vod__c where Product_Strategy_vod__c In :stratIds And Active_vod__c=true];
                    for (Product_Strategy_vod__c qStrat : qStrategies) {
                        ProductStrategyRow aRow = new ProductStrategyRow ();
                        aRow.id = qStrat.Id;
                        aRow.plan = qStrat.Product_Plan_vod__r.Name;
                        aRow.strategy = qStrat.Name;
                        if (qStrat.Description_vod__c != null)
                            aRow.description = qStrat.Description_vod__c;
                        else
                            aRow.description = System.Label.Common_None_vod;
        
                        aRow.numberOfTactics = 0;
                        for (Product_Tactic_vod__c qTactic : qTactics) {
                            if (qTactic.Product_Strategy_vod__c == qStrat.Id)
                                aRow.numberOfTactics++;
                        }
                            
                        aRow.selected = false;
                        theSList.add(aRow);
                    }
                }
                
                return theSList;
            }
            
            /* Get list of individual product tactics to apply */
            public List<ProductTacticRow> getProductTactics() {
        
                if (theTList == null) {
                    theTList = new List<ProductTacticRow>();
                    
                    List<Product_Plan_vod__c> qPlans = [Select Id,Name,Product_vod__r.Name,Product_vod__c,(Select Id,Name,Description_vod__c From Product_Strategy_vod__r Where Active_vod__c=true Order By Name)
                            From Product_Plan_vod__c
                            Where Active_vod__c=true 
                            Order By Product_vod__r.Name,Name];
                    List<Id> stratIds = new List<Id>();
                    for (Product_Plan_vod__c qPlan : qPlans) {
                        List<Product_Strategy_vod__c> strats = qPlan.Product_Strategy_vod__r;
                        if (strats != null) {
                            for (Product_Strategy_vod__c strat : strats) {
                                stratIds.add(strat.Id);
                            }
                        }
                    }
                    
                    Map<Id,Product_Strategy_vod__c> qStrats = new Map<Id,Product_Strategy_vod__c>([Select Id,(Select Id,Name From Product_Tactic_vod__r Where Active_vod__c=true Order By Name)
                            From Product_Strategy_vod__c Where Id In :stratIds]);
        
                    for (Product_Plan_vod__c qPlan : qPlans) {
                        List<Product_Strategy_vod__c> strats = qPlan.Product_Strategy_vod__r;
                        if (strats != null) {
                            for (Product_Strategy_vod__c strat : strats) {
                                Product_Strategy_vod__c qStrat = qStrats.get(strat.Id);
                                if (qStrat != null) {
                                    List<Product_Tactic_vod__c> qTactics = qStrat.Product_Tactic_vod__r;
                                    for (Product_Tactic_vod__c qTactic : qTactics) {
                                        ProductTacticRow aRow = new ProductTacticRow();
                                        aRow.id = qTactic.Id;
                                        aRow.plan = qPlan.Name;
                                        aRow.strategyId = strat.Id;
                                        aRow.strategyName = strat.Name;
                                        aRow.product = qPlan.Product_vod__r.Name;
                                        aRow.tactic = qTactic.Name;
                                        if (strat.Description_vod__c != null)
                                            aRow.description = strat.Description_vod__c;
                                        else
                                            aRow.description = System.Label.Common_None_vod;
                                        aRow.selected = false;
                                        theTList.add(aRow);
                                    }
                                }
                            }
                        }
                    }
                }
            
                return theTList;
            }
            
            /* Page subtitle */
            public String getSubtitle() {
                Account_Plan_vod__c thePlan = loadAccountPlan();
                if (thePlan == null)
                    return '';
                return acctPlan.Name;
            }
            
            // Helper class to represent a product strategy row
            public class ProductStrategyRow {
                public String id{get;set;}
                public boolean selected{get;set;}
                public String plan{get;set;}
                public String strategy{get;set;}
                public String description{get;set;}
                public Integer numberOfTactics{get;set;}
            }
        
            // Helper class to represent a product tactic row    
            public class ProductTacticRow {
                public String id{get;set;}
                public boolean selected{get;set;}
                public String plan{get;set;}
                public String strategyId{get;set;}
                public String strategyName{get;set;}
                public String product{get;set;}
                public String tactic{get;set;} 
                public String description{get;set;}
            }
        }