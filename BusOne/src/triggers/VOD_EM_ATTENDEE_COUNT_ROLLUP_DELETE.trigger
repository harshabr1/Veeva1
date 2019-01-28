trigger VOD_EM_ATTENDEE_COUNT_ROLLUP_DELETE on EM_Attendee_vod__c (after delete) {
    Set<ID> eventIds = new Set<ID>();
    for(EM_Attendee_vod__c attendee: Trigger.old) {
        if(attendee.Event_vod__c != null) {
            eventIds.add(attendee.Event_vod__c);
        }
    }

    List<EM_Event_vod__c> eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);

    if(eventsToUpdate.size() > 0) {
    	update eventsToUpdate;
    }
}