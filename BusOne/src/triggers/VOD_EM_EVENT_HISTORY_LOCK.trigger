trigger VOD_EM_EVENT_HISTORY_LOCK on EM_Event_History_vod__c (before delete) {
    Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();

    for (EM_Event_History_vod__c history : Trigger.old) {
        if (history.Event_vod__c != null) {
            associatedEvents.add(history.Event_vod__c);
        }
    }

    for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                   FROM EM_Event_vod__c
                                   WHERE Id IN :associatedEvents ]) {
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    for (EM_Event_History_vod__c history : Trigger.old) {
        if(history.Override_Lock_vod__c == true) {
        	history.Override_Lock_vod__c = false;	    
        } else if (history.Event_vod__c != null && lockedEvents.contains(history.Event_vod__c)) {
            history.addError('Event is locked');
        }
    }
}