trigger VOD_EM_EVENT_SPEAKER_BEFORE_INS_UPD on EM_Event_Speaker_vod__c (before delete, before insert, before update) {
    Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();

    List<EM_Event_Speaker_vod__c> speakers;

    if (Trigger.isInsert || Trigger.isUpdate) {
        speakers = Trigger.new;

        if (Trigger.isInsert) {
            Map<String, EM_Event_Speaker_vod__c> eventSpeakers = new Map<String, EM_Event_Speaker_vod__c>();
            Map<String, List<String>> speakerToEventSpeakers = new Map<String, List<String>>();

            for(EM_Event_Speaker_vod__c speaker: speakers) {
                if(speaker.Speaker_vod__c != null) {
                    eventSpeakers.put(speaker.Id, speaker);
                    if(speakerToEventSpeakers.get(speaker.Speaker_vod__c ) == null) {
                        speakerToEventSpeakers.put(speaker.Speaker_vod__c , new List<String>());
                    }
                    speakerToEventSpeakers.get(speaker.Speaker_vod__c ).add(speaker.Id);
                }
            }
            for(EM_Speaker_vod__c speaker : [ SELECT Id, Tier_vod__c FROM EM_Speaker_vod__c WHERE Id IN :speakerToEventSpeakers.keySet() ]) {
                for(String eventSpeakerId : speakerToEventSpeakers.get(speaker.Id)) {
                    EM_Event_Speaker_vod__c eventSpeaker = eventSpeakers.get(eventSpeakerId);
                    if(eventSpeaker != null) {
                        eventSpeaker.Tier_vod__c = speaker.Tier_vod__c;
                    }
                }
            }
        }
    } else {
        speakers = Trigger.old;
    }

    for(EM_Event_Speaker_vod__c speaker: speakers) {
        if(speaker.Event_vod__c != null) {
            associatedEvents.add(speaker.Event_vod__c);
        }
    }

    for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                   FROM EM_Event_vod__c
                                   WHERE Id IN :associatedEvents ]) {
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    for (EM_Event_Speaker_vod__c speaker : speakers) {
        if (speaker.Event_vod__c != null && lockedEvents.contains(speaker.Event_vod__c)) {
            speaker.addError('Event is locked');
        }
    }
}