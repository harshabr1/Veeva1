trigger VOD_EVENT_ATTENDEE_LOCK on Event_Attendee_vod__c (before delete, before update, before insert) {
    Map<String, String> attendeeToEvent = new Map<String, String>();
    Set<String> attendees = new Set<String>();
    Map<String, String> speakerToEvent = new Map<String, String>();
    Set<String> speakers = new Set<String>();

    if (Trigger.isUpdate || Trigger.isInsert) {
        for (Event_Attendee_vod__c eventAttendee : Trigger.new) {
            if (eventAttendee.EM_Attendee_vod__c != null) {
                attendees.add(eventAttendee.EM_Attendee_vod__c);
            } else if (eventAttendee.EM_Event_Speaker_vod__c != null) {
                speakers.add(eventAttendee.EM_Event_Speaker_vod__c);
            }
        }
    } else {
        for (Event_Attendee_vod__c eventAttendee : Trigger.old) {
            if (eventAttendee.EM_Attendee_vod__c != null) {
                attendees.add(eventAttendee.EM_Attendee_vod__c);
            } else if (eventAttendee.EM_Event_Speaker_vod__c != null) {
                speakers.add(eventAttendee.EM_Event_Speaker_vod__c);
            }
        }
    }

    Set<Id> lockedEvents = new Set<Id>();
    for (EM_Attendee_vod__c attendee : [ SELECT Id, Event_vod__c, Event_vod__r.Override_Lock_vod__c, Event_vod__r.Lock_vod__c
                                         FROM EM_Attendee_vod__c
                                         WHERE Id IN :attendees ]) {
        if (attendee.Event_vod__c != null) {
            attendeeToEvent.put(attendee.Id, attendee.Event_vod__c);
            if (attendee.Event_vod__r.Lock_vod__c && !attendee.Event_vod__r.Override_Lock_vod__c) {
                lockedEvents.add(attendee.Event_vod__c);
            }
        }
    }

    for (EM_Event_Speaker_vod__c speaker : [ SELECT Id, Event_vod__c, Event_vod__r.Override_Lock_vod__c, Event_vod__r.Lock_vod__c
                                             FROM EM_Event_Speaker_vod__c
                                             WHERE Id IN :speakers ]) {
        if (speaker.Event_vod__c != null) {
            speakerToEvent.put(speaker.Id, speaker.Event_vod__c);
            if (speaker.Event_vod__r.Lock_vod__c && !speaker.Event_vod__r.Override_Lock_vod__c) {
                lockedEvents.add(speaker.Event_vod__c);
            }
        }
    }

    if (Trigger.isUpdate || Trigger.isInsert) {
        for (Event_Attendee_vod__c eventAttendee : Trigger.new) {
            String id = null;
            if (eventAttendee.EM_Attendee_vod__c != null) {
                id = attendeeToEvent.get(eventAttendee.EM_Attendee_vod__c);
            } else if (eventAttendee.EM_Event_Speaker_vod__c != null) {
                id = speakerToEvent.get(eventAttendee.EM_Event_Speaker_vod__c);
            }
            if(eventAttendee.Override_Lock_vod__c == true) {
                eventAttendee.Override_Lock_vod__c = false;
            } else if (id != null && lockedEvents.contains(id)) {
                eventAttendee.addError('Event is locked');
            }
        }
    } else {
        for (Event_Attendee_vod__c eventAttendee : Trigger.old) {
            String id = null;
            if (eventAttendee.EM_Attendee_vod__c != null) {
                id = attendeeToEvent.get(eventAttendee.EM_Attendee_vod__c);
            } else if (eventAttendee.EM_Event_Speaker_vod__c != null) {
                id = speakerToEvent.get(eventAttendee.EM_Event_Speaker_vod__c);
            }
            if(eventAttendee.Override_Lock_vod__c == true) {
                eventAttendee.Override_Lock_vod__c = false;
            } else if (id != null && lockedEvents.contains(id)) {
                eventAttendee.addError('Event is locked');
            }
        }
    }
}