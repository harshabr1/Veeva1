trigger VOD_EXPENSE_LINE_INSERT on Expense_Line_vod__c (before insert) {
    Set<Id> eventIds = new Set<Id>();
    Set<Id> typeIds = new Set<Id>();
    Set<Id> headerIds = new Set<Id>();
    for (Expense_Line_vod__c line : Trigger.new) {
        if (line.Event_vod__c != null) {
            eventIds.add(line.Event_vod__c);
        }
        if (line.Expense_Type_vod__c != null) {
            typeIds.add(line.Expense_Type_vod__c);
        }
        if (line.Expense_Header_vod__c != null) {
            headerIds.add(line.Expense_Header_vod__c);
        }        
    }
    Map<Id, EM_Event_vod__c> eventMap = new Map<Id, EM_Event_vod__c>([SELECT Id, Lock_vod__c, Override_Lock_vod__c
                                                                      FROM EM_Event_vod__c
                                                                      WHERE Id IN : eventIds]);
    Map<Id, Expense_Type_vod__c> typeMap = new Map<Id, Expense_Type_vod__c>([SELECT Id, Name, Expense_Code_vod__c, Parent_Expense_Type_vod__r.Name, Parent_Expense_Type_vod__r.Expense_Code_vod__c,
                                                                                 Meal_Expense_vod__c, Included_In_Speaker_Cap_vod__c
                                                                                 FROM Expense_Type_vod__c
                                                                                 WHERE Id IN : typeIds]);
    Map<Id, Expense_Header_vod__c> headerMap = new Map<Id, Expense_Header_vod__c>([Select Id, Event_vod__c, Incurred_Expense_Account_vod__c, Incurred_Expense_Attendee_vod__r.Account_vod__c,
                                                                                   Incurred_Expense_Speaker_vod__r.Speaker_vod__c
                                                                                   FROM Expense_Header_vod__c
                                                                                   WHERE Id IN : headerIds]);      
        
    Set<String> lockedEvents = new Set<String>();
    for (Id eventId : eventMap.keySet()) {
        EM_Event_vod__c event = eventMap.get(eventId);
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }
    
    for (Expense_Line_vod__c expense: Trigger.new) {
        if(expense.Override_Lock_vod__c == true) {
            expense.Override_Lock_vod__c = false;
        } else if (expense.Event_vod__c != null && lockedEvents.contains(expense.Event_vod__c)) {
            expense.addError('Event is locked');
        }
        
        Expense_Header_vod__c header = headerMap.get(expense.Expense_Header_vod__c);
        if(header != null) {
            expense.Event_vod__c = header.Event_vod__c;
        }

        if (expense.Event_vod__c != null) {
            eventIds.add(expense.Event_vod__c);
        }
        
        Expense_Type_vod__c expenseType = null;
        if(expense.Expense_Type_vod__c != null) {
            expenseType = typeMap.get(expense.Expense_Type_vod__c);
        }
        if(expenseType != null) {
            expense.Expense_Type_Name_vod__c = expenseType.Name;
            expense.Expense_Type_Code_vod__c = expenseType.Expense_Code_vod__c;
            expense.Parent_Expense_Type_Name_vod__c = expenseType.Parent_Expense_Type_vod__r.Name;
            expense.Parent_Expense_Type_Code_vod__c = expenseType.Parent_Expense_Type_vod__r.Expense_Code_vod__c;
        }
    }   
}