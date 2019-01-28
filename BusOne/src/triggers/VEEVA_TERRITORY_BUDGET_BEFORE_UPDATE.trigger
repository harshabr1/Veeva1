trigger VEEVA_TERRITORY_BUDGET_BEFORE_UPDATE on Territory_Budget_vod__c (before update) {
    for (Territory_Budget_vod__c oldBudget : Trigger.oldMap.values()) {
        Territory_Budget_vod__c newBudget = Trigger.newMap.get(oldBudget.Id);
        if ((oldBudget.Start_Quantity_vod__c != newBudget.Start_Quantity_vod__c) || (oldBudget.Start_Value_vod__c != newBudget.Start_Value_vod__c))
            newBudget.addError(VOD_GET_ERROR_MSG.getErrorMsg('START_VALUES_ERROR', 'BUDGET_MANAGEMENT'), false);
    }
}