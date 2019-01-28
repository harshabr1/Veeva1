trigger VOD_MC_CP_BEFORE_INSERT_UPDATE on MC_Cycle_Plan_vod__c (before insert, before update) {

    for(MC_Cycle_Plan_vod__c plan: Trigger.new){
        if(plan.Cycle_vod__c != null){
            plan.VExternal_Id_vod__c = plan.Cycle_vod__c + '__' + plan.Territory_vod__c;
        }
    }
}