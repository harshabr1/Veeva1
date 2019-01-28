/******************************************************************************
 *                                                                              
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 *  Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of  Veeva Systems, Inc.
 * 
 * Copyright (c) 2010 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
trigger VOD_CALL_OBJECTIVE_BEFORE_UPDATE on Call_Objective_vod__c (before update, before insert) {
    if (VEEVA_CALL_OBJECTIVE_TRIG.invoked)
    {
        return;
    }
    
    Map<Id, RecordType> recordTypes = new Map<Id, RecordType>([SELECT Id, DeveloperName FROM RecordType WHERE SobjectType='Call_Objective_vod__c']);

    Map<Id,Integer> prerequisitesToBeCheckedForCompletedMap = new Map<Id,Integer>();
    Set<Call_Objective_vod__c> callObjectivesToSetEsecutableSet = new Set<Call_Objective_vod__c>();
    
    for (Integer i = 0; i < Trigger.new.size(); i++) {

      if(Trigger.isInsert) {

          System.debug('Trigger.isInsert');
          if(Trigger.new[i].Prerequisite_vod__c != null ) {

          System.debug('Trigger.new[i].Prerequisite_vod__c != null');
          prerequisitesToBeCheckedForCompletedMap.put(Trigger.new[i].Prerequisite_vod__c, i);

        }

        continue;
      }

      // The case update
        if(Trigger.new[i].Non_Executable_vod__c) {
            Trigger.new[i].Completed_Flag_vod__c = false;
        }

        boolean hasCallAssociated = (Trigger.new[i].Call2_vod__c != null); 
        boolean isCompleted = Trigger.new[i].Completed_Flag_vod__c;

        if(!hasCallAssociated && !isCompleted && Trigger.new[i].To_Date_vod__c != null){
            String recordType = recordTypes.get(Trigger.new[i].RecordTypeId).DeveloperName;

            if(recordType == 'EPPV_vod' || recordType == 'PI_vod') {
                Trigger.new[i].Date_vod__c = datetime.newInstanceGmt(Trigger.new[i].To_Date_vod__c.year(),
                                                Trigger.new[i].To_Date_vod__c.month(), Trigger.new[i].To_Date_vod__c.day(),12,0,0);
            }            
        }

        if(Trigger.new[i].Recurring_vod__c != Trigger.old[i].Recurring_vod__c && Trigger.new[i].Parent_Objective_vod__c == null){
            boolean updRecurringToTrue = Trigger.new[i].Recurring_vod__c && !Trigger.old[i].Recurring_vod__c;  
            boolean updRecurringToFalse = !Trigger.new[i].Recurring_vod__c && Trigger.old[i].Recurring_vod__c;  

            List<Call_Objective_vod__c> cObjs = [select Id, Business_Event_Target_vod__c,Date_vod__c
                                                  from Call_Objective_vod__c
                                                  where Parent_Objective_vod__c = :Trigger.new[i].Id];
            
            boolean hasChild = (cObjs != null && cObjs.size()>0);

            if (hasChild && updRecurringToFalse){
                Trigger.new[i].addError(VOD_GET_ERROR_MSG.getErrorMsg('CANNOT_CHANGE_RECURRING', 'CallObjectives'));
                return;
            }
            if (updRecurringToTrue && (hasCallAssociated || isCompleted) ){
                Trigger.new[i].addError(VOD_GET_ERROR_MSG.getErrorMsg('CANNOT_CHANGE_RECURRING', 'CallObjectives'));
                return;
            }    
        } 
        
        // The part for Prerequisit
        if(Trigger.new[i].Prerequisite_vod__c == null ) {
            System.debug('Trigger.new[i].Prerequisite_vod__c == null for ' + Trigger.new[i].Id);
            Trigger.new[i].Non_Executable_vod__c = false;
        }

        if((Trigger.new[i].Prerequisite_vod__c != null ) && ((Trigger.new[i].Prerequisite_vod__c != Trigger.old[i].Prerequisite_vod__c ))){
            System.debug('Prerequisite_vod__c switched for ' + Trigger.new[i].Id);
            prerequisitesToBeCheckedForCompletedMap.put(Trigger.new[i].Prerequisite_vod__c, i);
        }
        
        if(Trigger.new[i].Completed_Flag_vod__c && (Trigger.new[i].Completed_Flag_vod__c != Trigger.old[i].Completed_Flag_vod__c)) {
            System.debug('Select children: Completed_Flag_vod__c changed');
            callObjectivesToSetEsecutableSet.add(Trigger.new[i]);
        }
    }

    System.debug('after cycle');
    
    // Check if the field Complete_vod__c not set for new Prerecwisite_vod__c
    if(prerequisitesToBeCheckedForCompletedMap.size() > 0) {
        List<Id> prerequisitesToBeCheckedForCompletedList = new List<Id>();
        prerequisitesToBeCheckedForCompletedList.addAll(prerequisitesToBeCheckedForCompletedMap.keySet());

        List<Call_Objective_vod__c> callObjectivesWithCompleted = [SELECT Id, Completed_Flag_vod__c FROM Call_Objective_vod__c WHERE Id IN :prerequisitesToBeCheckedForCompletedList AND Completed_Flag_vod__c = true];
        System.debug('callObjectivesWithCompleted = ' + callObjectivesWithCompleted);
        if(callObjectivesWithCompleted != null && callObjectivesWithCompleted.size() > 0) {
            Call_Objective_vod__c wrongCallObjective = callObjectivesWithCompleted.get(0);
            Integer idx = prerequisitesToBeCheckedForCompletedMap.get(wrongCallObjective.Id);
            Trigger.new[idx].addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('COMPLETED_CALLOBJECTIVE', 'KAM', 'A completed Call Objective cannot be selected as a prerequisite to another Call Objective.'));
            return;
        }
        
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            if(prerequisitesToBeCheckedForCompletedMap.containsKey(Trigger.new[i].Prerequisite_vod__c)) {
                Trigger.new[i].Non_Executable_vod__c = true;
            }
        }
    }
    
    if(callObjectivesToSetEsecutableSet.size() > 0) {
        List<Call_Objective_vod__c> callObjectivesToSetEsecutableList = new List<Call_Objective_vod__c>();
        callObjectivesToSetEsecutableList.addAll(callObjectivesToSetEsecutableSet);
        List<Call_Objective_vod__c> children = [SELECT Id, Prerequisite_vod__c FROM Call_Objective_vod__c WHERE Prerequisite_vod__c IN :callObjectivesToSetEsecutableList];    
        if(children != null && children.size() > 0 ){
            System.debug('Update ' + children.size() + ' children in if(children != null && children.size()>0) block');
            for(Integer idx = 0; idx < children.size(); idx++) {
                children[idx].Non_Executable_vod__c = false;
            }
            VEEVA_CALL_OBJECTIVE_TRIG.invoked = true;
            // The flag calculateCOProgressOnly is used in Call_Objective_after_upsert_before_delete.trigger
            VEEVA_CALL_OBJECTIVE_TRIG.calculateCOProgressOnly = true;
            update(children);
        }
    }
}