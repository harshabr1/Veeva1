trigger VOD_EXPENSE_LINE_UPDATE on Expense_Line_vod__c (before update) {
    Map<Id, Expense_Line_vod__c > afterExpenses = Trigger.newMap;
    Set<Id> eventIds = new Set<Id>();
    Set<Id> typeIds = new Set<Id>();
    for (Id expenseId : afterExpenses.keySet()) {
        Expense_Line_vod__c afterExpense = afterExpenses.get(expenseId);
        if (afterExpense.Event_vod__c != null) {
            eventIds.add(afterExpense.Event_vod__c);
        }
        if (afterExpense.Expense_Type_vod__c != null) {
            typeIds.add(afterExpense.Expense_Type_vod__c);
        }
        if (Trigger.oldMap.get(afterExpense.Id).Expense_Type_vod__c != null) {
            typeIds.add(Trigger.oldMap.get(afterExpense.Id).Expense_Type_vod__c);
        }
    }
    Map<Id, EM_Event_vod__c> eventMap = new Map<Id, EM_Event_vod__c>([SELECT Id, Lock_vod__c, Override_Lock_vod__c
                                                                      FROM EM_Event_vod__c
                                                                      WHERE Id IN : eventIds]);
    Map<Id, Expense_Type_vod__c> typeMap = new Map<Id, Expense_Type_vod__c>([SELECT Id, Name, Expense_Code_vod__c, Parent_Expense_Type_vod__r.Name, Parent_Expense_Type_vod__r.Expense_Code_vod__c,
                                                                                 Meal_Expense_vod__c, Included_In_Speaker_Cap_vod__c
                                                                                 FROM Expense_Type_vod__c
                                                                                 WHERE Id IN : typeIds]);
    Set<String> lockedEvents = new Set<String>();
    for (Id eventId : eventMap.keySet()) {
        EM_Event_vod__c event = eventMap.get(eventId);
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    for(Expense_Line_vod__c  beforeExpense: Trigger.old) {
        Expense_Line_vod__c  afterExpense = afterExpenses.get(beforeExpense.id);
        if(afterExpense.Override_Lock_vod__c) {
            afterExpense.Override_Lock_vod__c = false; 
        } else if (afterExpense.Event_vod__c != null && lockedEvents.contains(afterExpense.Event_vod__c)) {
            afterExpense.addError('Event is locked');
        }
        if(afterExpense.Expense_Type_vod__c != beforeExpense.Expense_Type_vod__c && afterExpense.Expense_Type_vod__c != null) {
            Expense_Type_vod__c expenseType = typeMap.get(afterExpense.Expense_Type_vod__c);
            
            afterExpense.Expense_Type_Name_vod__c = expenseType.Name;
            afterExpense.Expense_Type_Code_vod__c = expenseType.Expense_Code_vod__c;
            afterExpense.Parent_Expense_Type_Name_vod__c = expenseType.Parent_Expense_Type_vod__r.Name;
            afterExpense.Parent_Expense_Type_Code_vod__c = expenseType.Parent_Expense_Type_vod__r.Expense_Code_vod__c;            
        }
    }
}