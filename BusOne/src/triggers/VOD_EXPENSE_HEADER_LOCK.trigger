trigger VOD_EXPENSE_HEADER_LOCK on Expense_Header_vod__c (before delete) {
    Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();

    for (Expense_Header_vod__c header : Trigger.old) {
        if (header.Event_vod__c != null) {
            associatedEvents.add(header.Event_vod__c);
        }
    }

    for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                   FROM EM_Event_vod__c
                                   WHERE Id IN :associatedEvents ]) {
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    for (Expense_Header_vod__c header : Trigger.old) {
        if (header.Override_Lock_vod__c == true) {
            header.Override_Lock_vod__c = false;
        } else if (header.Event_vod__c != null && lockedEvents.contains(header.Event_vod__c)) {
            header.addError('Event is locked');
        }
    }
}