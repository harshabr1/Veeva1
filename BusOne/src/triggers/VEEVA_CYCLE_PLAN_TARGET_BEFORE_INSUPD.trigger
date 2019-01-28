trigger VEEVA_CYCLE_PLAN_TARGET_BEFORE_INSUPD on Cycle_Plan_Target_vod__c (before update, before insert) {
    
    for (Cycle_Plan_Target_vod__c cpt : Trigger.new) {
        cpt.External_ID_vod__c = cpt.Cycle_Plan_vod__c+'__' + cpt.Cycle_Plan_Account_vod__c;
    }

}