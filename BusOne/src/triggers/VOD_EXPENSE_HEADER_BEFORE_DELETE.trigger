trigger VOD_EXPENSE_HEADER_BEFORE_DELETE on Expense_Header_vod__c (before delete) {
    Set<Id> headerIds = Trigger.oldMap.keySet();
    List<Expense_Line_vod__c> relatedExpenseLines = [SELECT Id FROM Expense_Line_vod__c WHERE Expense_Header_vod__c IN :headerIds];
    List<Expense_Attribution_vod__c> attributions = [SELECT Id FROM Expense_Attribution_vod__c WHERE Expense_Line_vod__r.Expense_Header_vod__c IN :headerIds];

    try {
        if(attributions.size() > 0) {
            delete attributions;
        }
        if(relatedExpenseLines.size() > 0) {
        	delete relatedExpenseLines;
        }
    } catch (DmlException e) {
        for (Integer i = 0; i < e.getNumDml(); i++) {
            // Print out the error message for each failed deletion
            System.debug(e.getDmlMessage(i));
        }
    }
}