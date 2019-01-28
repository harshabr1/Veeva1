trigger VOD_EM_EVENT_MATERIAL_LOCK on EM_Event_Material_vod__c (before insert, before update, before delete) {
	Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();

    if(trigger.isDelete) {
		for (EM_Event_Material_vod__c material : Trigger.old) {
            if (material.Event_vod__c != null) {
                associatedEvents.add(material.Event_vod__c);
            }
        }         
    } else {
		for (EM_Event_Material_vod__c material : Trigger.new) {
            if (material.Event_vod__c != null) {
                associatedEvents.add(material.Event_vod__c);
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
		for (EM_Event_Material_vod__c material : Trigger.new) {
            if(material.Override_Lock_vod__c == true) {
                material.Override_Lock_vod__c = false;
            } else if (material.Event_vod__c != null && lockedEvents.contains(material.Event_vod__c)) {
                material.addError('Event is locked');
            }
        }        
    } else {
 		for (EM_Event_Material_vod__c material : Trigger.old) {
            if(material.Override_Lock_vod__c == true) {
                material.Override_Lock_vod__c = false;
            } else if (material.Event_vod__c != null && lockedEvents.contains(material.Event_vod__c)) {
                material.addError('Event is locked');
            }
        }       
    } 
}