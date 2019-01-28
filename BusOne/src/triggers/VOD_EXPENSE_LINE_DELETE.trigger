trigger VOD_EXPENSE_LINE_DELETE on Expense_Line_vod__c (before delete) {
    Set<Id> eventIds = new Set<Id>();

    for (Expense_Line_vod__c line : Trigger.old) {
        if (line.Event_vod__c != null) {
            eventIds.add(line.Event_vod__c);
        }
    }

    Map<Id, EM_Event_vod__c> eventMap = new Map<Id, EM_Event_vod__c>([SELECT Id, Lock_vod__c, Override_Lock_vod__c
                                                                      FROM EM_Event_vod__c
                                                                      WHERE Id IN : eventIds]);
    Set<String> lockedEvents = new Set<String>();
    for (Id eventId : eventMap.keySet()) {
        EM_Event_vod__c event = eventMap.get(eventId);
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    for(Expense_Line_vod__c expense: Trigger.old) {
        Decimal committed = expense.Committed_vod__c == null ? 0: expense.Committed_vod__c;
        Decimal actual = expense.Actual_vod__c == null ? 0: expense.Actual_vod__c;
        
        if(expense.Override_Lock_vod__c) {
            expense.Override_Lock_vod__c = false;
        } else if (expense.Override_Lock_vod__c != true && expense.Event_vod__c != null && lockedEvents.contains(expense.Event_vod__c)) {
            expense.addError('Event is locked');
        }
        
    }
}