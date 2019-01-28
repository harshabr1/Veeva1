trigger VOD_EM_ATTENDEE_COUNT_ROLLUP_INSERT on EM_Attendee_vod__c (after insert) {
    Set<ID> eventIds = new Set<ID>();
    for(EM_Attendee_vod__c attendee: Trigger.new) {
        if(attendee.Event_vod__c != null) {
	          eventIds.add(attendee.Event_vod__c);
        }
    }

    List<EM_Event_vod__c> eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);

    if(eventsToUpdate.size() > 0) {
    	update eventsToUpdate;
    }
}