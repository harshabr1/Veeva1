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
 * Copyright (c) 2011 Veeva Systems , Inc.  All Rights Reserved.
 *
 *******************************************************************************/
 
trigger VEEVA_CHILD_ACCOUNT_ADDRESS_CLEAN on Child_Account_vod__c (before insert, before update, before delete) {
    
    Set <Id> accIds = new Set<Id>();
    Set <Id> parentId = new Set<Id>();
    Integer size=0;
    Set<String> childToParenSet = new Set<String>();
  
    if (Trigger.isInsert)
        size = Trigger.new.size();
    else 
        size = Trigger.old.size();
    
     for (Integer i = 0 ; i < size; i++) {
        if (Trigger.isUpdate || Trigger.isInsert) {
            if (Trigger.isUpdate && Trigger.new[i].Copy_Address_vod__c == false && Trigger.old[i].Copy_Address_vod__c == true) {
                accIds.add(Trigger.new[i].Child_Account_vod__c);
                childToParenSet.add(Trigger.new[i].Child_Account_vod__c +'__' + Trigger.new[i].Parent_Account_vod__c);
            }
            if ((Trigger.isInsert && Trigger.new[i].Copy_Address_vod__c == true)  || (Trigger.isUpdate && Trigger.new[i].Copy_Address_vod__c == true && Trigger.old[i].Copy_Address_vod__c == false))
                parentId.add( Trigger.new[i].Parent_Account_vod__c);
       } else {
              
              //if merge then do not delete address on delete of the child account record on trigger.isDelete
              if (!VOD_Utils.getisMergeAccountProcess()){
           accIds.add(Trigger.old[i].Child_Account_vod__c);
           childToParenSet.add(Trigger.old[i].Child_Account_vod__c +'__' + Trigger.old[i].Parent_Account_vod__c);
           }
        
       }

    }
    
    if (accIds.size() > 0) {
     List<Address_vod__c> listDelAddr = [Select Id, Account_vod__c, Controlling_Address_vod__c, Controlling_Address_vod__r.Account_vod__c from Address_vod__c where Account_vod__c in :accIds and Controlling_Address_vod__c != null];
        try {
            List<Address_vod__c> deleteList = new List<Address_vod__c>();
            
            for (Address_vod__c vodaddr : listDelAddr) {
                String parentAccount = vodaddr.Controlling_Address_vod__r.Account_vod__c;
                String childAccount = vodaddr.Account_vod__c;
                
                if (childToParenSet.contains(childAccount +'__'+ parentAccount)) {
                    deleteList.add(vodaddr);
                }
            }
            
            VOD_ADDRESS_TRIG.setChildAccount(true);
            if (deleteList.size() > 0)
                delete deleteList;
        } catch (System.DmlException e) {
           Integer numErrors = e.getNumDml();
            String error = '';
            for (Integer i = 0; i < numErrors; i++) {
                Id thisId = e.getDmlId(i);
                if (thisId != null)  {
                    error += thisId + ' - ' + e.getDmlMessage(i) + '\n';
                }
            }
            Child_Account_vod__c [] chAcc = null;
            if (Trigger.isDelete) 
                chAcc = Trigger.old;
            else
                chAcc = Trigger.new;  
            
            for (Child_Account_vod__c errorRec : chAcc) {
                errorRec.Id.addError(error, false);
            }
            
        } finally {
            VOD_ADDRESS_TRIG.setChildAccount(false);
        }
    }
    
    if (parentId.size() > 0) {
        List<Address_vod__c> touchList = [Select Id From Address_vod__c where Account_vod__c in :parentId];
        if (touchlist.size() > 0) {
            try {        
                update touchlist;
            }  catch (System.DmlException e) {
           Integer numErrors = e.getNumDml();
            String error = '';
            for (Integer i = 0; i < numErrors; i++) {
                Id thisId = e.getDmlId(i);
                if (thisId != null)  {
                    error += thisId + ' - ' + e.getDmlMessage(i) + '\n';
                }
            }
            Child_Account_vod__c [] chAcc = null;
            if (Trigger.isDelete) 
                chAcc = Trigger.old;
            else
                chAcc = Trigger.new;  
            
            for (Child_Account_vod__c errorRec : chAcc) {
                errorRec.Id.addError(error, false);
            }
            
        } finally {
            VOD_ADDRESS_TRIG.setChildAccount(false);
        }
        }
    }
    
}