trigger VOD_EM_EVENT_SESSION_LOCK on EM_Event_Session_vod__c (before delete, before insert, before update) {
    Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();

    if (Trigger.isInsert || Trigger.isUpdate) {
        for (EM_Event_Session_vod__c session : Trigger.new) {
            if (session.Event_vod__c != null) {
                associatedEvents.add(session.Event_vod__c);
            }
        }
    } else {
        for (EM_Event_Session_vod__c session : Trigger.old) {
            if (session.Event_vod__c != null) {
                associatedEvents.add(session.Event_vod__c);
            }
        }
    }

    for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                   FROM EM_Event_vod__c
                                   WHERE Id IN :associatedEvents ]) {
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    if (Trigger.isInsert || Trigger.isUpdate) {
        for (EM_Event_Session_vod__c session : Trigger.new) {
            if(session.Override_Lock_vod__c == true) {
                session.Override_Lock_vod__c = false;
            } else if (session.Event_vod__c != null && lockedEvents.contains(session.Event_vod__c)) {
                session.addError('Event is locked');
            }
        }
    } else {
        for (EM_Event_Session_vod__c session : Trigger.old) {
            if(session.Override_Lock_vod__c == true) {
                session.Override_Lock_vod__c = false; 
            } else if (session.Event_vod__c != null && lockedEvents.contains(session.Event_vod__c)) {
                session.addError('Event is locked');
            }
        }
    }
}