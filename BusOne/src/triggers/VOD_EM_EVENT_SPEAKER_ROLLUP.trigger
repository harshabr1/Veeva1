trigger VOD_EM_EVENT_SPEAKER_ROLLUP on EM_Event_Speaker_vod__c (after insert, after update, after delete) {
    Set<Id> speakersToRecalculate = new Set<Id>();
    Set<ID> eventIds = new Set<ID>();
    
    if(Trigger.isDelete) {
    	for(EM_Event_Speaker_vod__c speaker: Trigger.old) {
            eventIds.add(speaker.Event_vod__c);
        }    
    } else if (Trigger.isInsert) {
        for(EM_Event_Speaker_vod__c speaker: Trigger.new) {
            eventIds.add(speaker.Event_vod__c);
        }
    } else if (Trigger.IsUpdate) {
    	for(EM_Event_Speaker_vod__c speaker: Trigger.new) {
            EM_Event_Speaker_vod__c oldSpeaker = Trigger.oldMap.get(speaker.Id);
            if(speaker.Meal_Opt_In_vod__c != oldSpeaker.Meal_Opt_In_vod__c || speaker.Status_vod__c != oldSpeaker.Status_vod__c) {
            	eventIds.add(speaker.Event_vod__c);
            }
        }
    }


    if(Trigger.isDelete) {
	    for(EM_Event_speaker_vod__c speaker: Trigger.old) {
            if(speaker.Speaker_vod__c != null) {
                speakersToRecalculate.add(speaker.Speaker_vod__c);
            }
    	}
    } else if (trigger.isUpdate) {
        for (EM_Event_Speaker_vod__c speaker : Trigger.new) {
            EM_Event_Speaker_vod__c oldSpeaker = Trigger.oldMap.get(speaker.Id);
            if((speaker.Speaker_vod__c != oldSpeaker.Speaker_vod__c) || (speaker.Status_vod__c != oldSpeaker.Status_vod__c)) {
                speakersToRecalculate.add(oldSpeaker.Speaker_vod__c);
                speakersToRecalculate.add(speaker.Speaker_vod__c);
            }
        }
    } else if (Trigger.isInsert) {
    	for (EM_Event_Speaker_vod__c speaker : Trigger.new) {
            if (speaker.Speaker_vod__c != null) {
                speakersToRecalculate.add(speaker.Speaker_vod__c);
            }
        }
    }
    if(!speakersToRecalculate.isEmpty()) {
        SpeakerYTDCalculator.calculate(speakersToRecalculate);
    }

    if(eventIds.size() > 0) {
        List<EM_Event_vod__c> eventsToUpdate = new List<EM_Event_vod__c>();
    	eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);
        update eventsToUpdate;
    }
}