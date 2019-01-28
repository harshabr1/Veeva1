trigger VOD_MEDICAL_EVENT_LOCK on Medical_Event_vod__c (before insert, before update, before delete) {
	Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();

    if(trigger.isDelete) {
		for (Medical_Event_vod__c medEvent : Trigger.old) {
            if (medEvent.EM_Event_vod__c != null) {
                associatedEvents.add(medEvent.EM_Event_vod__c);
        	}
    	}        
    } else {
    	for (Medical_Event_vod__c medEvent : Trigger.new) {
            if (medEvent.EM_Event_vod__c != null) {
                associatedEvents.add(medEvent.EM_Event_vod__c);
        	}
    	}      
    }
    
    if(associatedEvents.size() > 0) {
    	for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                   FROM EM_Event_vod__c
                                   WHERE Id IN :associatedEvents ]) {
            if (VOD_Utils.isEventLocked(event)) {
                lockedEvents.add(event.Id);
            }
        }    
    }
    
    if(Trigger.isUpdate || Trigger.isInsert) {
		for (Medical_Event_vod__c medEvent : Trigger.new) {
            if(medEvent.Override_Lock_vod__c == true) {
                medEvent.Override_Lock_vod__c = false;
            } else if (medEvent.EM_Event_vod__c != null && lockedEvents.contains(medEvent.EM_Event_vod__c)) {
                medEvent.addError('Event is locked');
            }
        }        
    } else {
 		for (Medical_Event_vod__c medEvent : Trigger.old) {
            if(medEvent.Override_Lock_vod__c == true) {
                medEvent.Override_Lock_vod__c = false;
            } else if (medEvent.EM_Event_vod__c != null && lockedEvents.contains(medEvent.EM_Event_vod__c)) {
                medEvent.addError('Event is locked');
            }
        }       
    }     
}