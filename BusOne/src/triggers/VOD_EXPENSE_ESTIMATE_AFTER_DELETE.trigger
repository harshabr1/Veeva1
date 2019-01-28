trigger VOD_EXPENSE_ESTIMATE_AFTER_DELETE on EM_Expense_Estimate_vod__c (after delete) {
    List<String> expense_ids = new List<String>();
    if(trigger.old != null){
        for(EM_Expense_Estimate_vod__c expense : trigger.old){
            expense_ids.add(expense.Id);
        }
    }
    if(expense_ids.size() > 0){
        List<EM_Expense_Estimate_vod__Share> expenseShares = [SELECT ParentId, UserOrGroupId, AccessLevel, RowCause FROM EM_Expense_Estimate_vod__Share WHERE ParentId IN :expense_ids];
        List<Database.DeleteResult> deleteResults = Database.delete(expenseShares, false);
        for(Database.DeleteResult result: deleteResults){
            if(!result.isSuccess()){
             system.debug('delete error: ' + result.getErrors()[0]);
           }
        }
    }

}