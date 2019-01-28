trigger VOD_EM_ATTENDEE_COUNT_ROLLUP_UPDATE on EM_Attendee_vod__c (after update) {
	Set<ID> eventIds = new Set<ID>();
    for(EM_Attendee_vod__c attendee: Trigger.new) {
        EM_Attendee_vod__C oldAttendee = Trigger.oldMap.get(attendee.Id);
        if(attendee.Meal_Opt_In_vod__c != oldAttendee.Meal_Opt_In_vod__c || attendee.Status_vod__c != oldAttendee.Status_vod__c) {
						if(attendee.Event_vod__c != null) {
								eventIds.add(attendee.Event_vod__c);
						}
        }
    }

    if(eventIds.size() > 0) {
        List<EM_Event_vod__c> eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);
    	update eventsToUpdate;
    }
}