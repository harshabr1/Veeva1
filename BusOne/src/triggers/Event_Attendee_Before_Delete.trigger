trigger Event_Attendee_Before_Delete on Event_Attendee_vod__c (before delete) {
    
    VOD_Utils.setTriggerEventAttendee(true);
    VOD_ERROR_MSG_BUNDLE bnd = new VOD_ERROR_MSG_BUNDLE ();
    
    Set<Id> emIds = new Set<Id>();
    for (Event_Attendee_vod__c attendee : Trigger.old) {
        if (attendee.Signature_Datetime_vod__c != null){
            attendee.addError(System.Label.NO_DEL_SIGNED_ATTENDEE, false);
            return;
        }
        if(attendee.EM_Attendee_vod__c != null) {
            emIds.add(attendee.EM_Attendee_vod__c);
        }
    }
    
    
    if(!emIds.isEmpty() && !VOD_Utils.isTriggerEmAttendee()) {
    	List<EM_Attendee_vod__c> emAttendees = new List<EM_Attendee_vod__c>();
        for(Id attendeeId: emIds) {
            emAttendees.add(new EM_Attendee_vod__c(Id = attendeeId));
        }
        delete emAttendees;
    }
}