trigger VOD_EM_EVENT_TEAM_MEMBER_LOCK on EM_Event_Team_Member_vod__c (before delete, before insert, before update) {
    Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();

    if(trigger.isDelete) {
		for (EM_Event_Team_Member_vod__c member : Trigger.old) {
            if (member.Event_vod__c != null) {
                associatedEvents.add(member.Event_vod__c);
            }
        }       
    } else{
		for (EM_Event_Team_Member_vod__c member : Trigger.new) {
            if (member.Event_vod__c != null) {
                associatedEvents.add(member.Event_vod__c);
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

    if(Trigger.isUpdate || Trigger.isInsert) {
    	for (EM_Event_Team_Member_vod__c member : Trigger.new) {
            if(member.Override_Lock_vod__c == true) {
                member.Override_Lock_vod__c = false;
            } else if (member.Event_vod__c != null && lockedEvents.contains(member.Event_vod__c)) {
                member.addError('Event is locked');
            }
        }  
    } else {
		for (EM_Event_Team_Member_vod__c member : Trigger.old) {
            if(member.Override_Lock_vod__c == true) {
                member.Override_Lock_vod__c = false;
            } else if (member.Event_vod__c != null && lockedEvents.contains(member.Event_vod__c)) {
                member.addError('Event is locked');
            }
        }        
    }       
}