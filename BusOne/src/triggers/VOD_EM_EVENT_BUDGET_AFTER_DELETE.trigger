trigger VOD_EM_EVENT_BUDGET_AFTER_DELETE on EM_Event_Budget_vod__c (after delete) {
    List<String> budget_ids = new List<String>();
    if (trigger.old != null){
        for (EM_Event_Budget_vod__c budget : trigger.old){
            budget_ids.add(budget.Id);
        }
    }
    if (budget_ids.size() > 0){
        List<EM_Event_Budget_vod__Share> budgetShares = [SELECT ParentId, UserOrGroupId, AccessLevel, RowCause FROM EM_Event_Budget_vod__Share WHERE ParentId IN :budget_ids];
        List<Database.DeleteResult> deleteResults = Database.delete(budgetShares, false);
        for (Database.DeleteResult result: deleteResults){
            if (!result.isSuccess()){
             system.debug('delete error: ' + result.getErrors()[0]);
           }
        }
    }
}