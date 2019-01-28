trigger VOD_EM_EVENT_SPEAKER_LOCK on EM_Event_Speaker_vod__c (before delete, before insert, before update) {
    Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();

    if (Trigger.isInsert || Trigger.isUpdate) {
        for (EM_Event_Speaker_vod__c speaker : Trigger.new) {
            if (speaker.Event_vod__c != null) {
                associatedEvents.add(speaker.Event_vod__c);
            }
        }
    } else {
        for (EM_Event_Speaker_vod__c speaker : Trigger.old) {
            if (speaker.Event_vod__c != null) {
                associatedEvents.add(speaker.Event_vod__c);
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
        for (EM_Event_Speaker_vod__c speaker : Trigger.new) {
            if (speaker.Event_vod__c != null && lockedEvents.contains(speaker.Event_vod__c)) {
                speaker.addError('Event is locked');
            }
        }
    } else {
        for (EM_Event_Speaker_vod__c speaker : Trigger.old) {
            if (speaker.Event_vod__c != null && lockedEvents.contains(speaker.Event_vod__c)) {
                speaker.addError('Event is locked');
            }
        }
    }
}