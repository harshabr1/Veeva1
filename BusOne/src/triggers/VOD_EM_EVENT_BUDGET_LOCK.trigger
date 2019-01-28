trigger VOD_EM_EVENT_BUDGET_LOCK on EM_Event_Budget_vod__c (before delete) {
    Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();

    for (EM_Event_Budget_vod__c budget : Trigger.old) {
        if (budget.Event_vod__c != null) {
            associatedEvents.add(budget.Event_vod__c);
        }
    }

    for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                   FROM EM_Event_vod__c
                                   WHERE Id IN :associatedEvents ]) {
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    for (EM_Event_Budget_vod__c budget : Trigger.old) {
        if(budget.Override_Lock_vod__c == true) {
            budget.Override_Lock_vod__c = false;
        } else if (budget.Event_vod__c != null && lockedEvents.contains(budget.Event_vod__c)) {
            budget.addError('Event is locked');
        }
    }
}