trigger VOD_EM_EVENT_SESSION_ATTENDEE_LOCK on EM_Event_Session_Attendee_vod__c (before delete, before insert, before update) {
    Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();
    Map<String, String> sessionToEvent = new Map<String, String>();
    Set<String> sessions = new Set<String>();

    if (Trigger.isInsert || Trigger.isUpdate) {
        for (EM_Event_Session_Attendee_vod__c attendee : Trigger.new) {
            if (attendee.Event_Session_vod__c != null) {
                sessions.add(attendee.Event_Session_vod__c);
            }
        }
    } else {
        for (EM_Event_Session_Attendee_vod__c attendee : Trigger.old) {
            if (attendee.Event_Session_vod__c != null) {
                sessions.add(attendee.Event_Session_vod__c);
            }
        }
    }

    for (EM_Event_Session_vod__c session : [ SELECT Id, Event_vod__c
                                             FROM EM_Event_Session_vod__c
                                             WHERE Id IN :sessions ]) {
        if (session.Event_vod__c != null) {
            associatedEvents.add(session.Event_vod__c);
            sessionToEvent.put(session.Id, session.Event_vod__c);
        }
    }

    for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                   FROM EM_Event_vod__c
                                   WHERE Id IN :associatedEvents]) {
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    if (Trigger.isInsert || Trigger.isUpdate) {
        for (EM_Event_Session_Attendee_vod__c attendee : Trigger.new) {
            if(attendee.Override_Lock_vod__c == true) {
                attendee.Override_Lock_vod__c = false;
            } else if (attendee.Event_Session_vod__c != null && sessionToEvent.get(attendee.Event_Session_vod__c) != null &&
                lockedEvents.contains(sessionToEvent.get(attendee.Event_Session_vod__c))) {
                attendee.addError('Event is locked');
            }
        }
    } else {
        for (EM_Event_Session_Attendee_vod__c attendee : Trigger.old) {
            if(attendee.Override_Lock_vod__c == true) {
                attendee.Override_Lock_vod__c = false;
            } else if (attendee.Event_Session_vod__c != null && sessionToEvent.get(attendee.Event_Session_vod__c) != null &&
                lockedEvents.contains(sessionToEvent.get(attendee.Event_Session_vod__c))) {
                attendee.addError('Event is locked');
            }
        }
    }
}