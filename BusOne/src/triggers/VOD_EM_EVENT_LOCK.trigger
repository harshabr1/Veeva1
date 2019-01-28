trigger VOD_EM_EVENT_LOCK on EM_Event_vod__c (before delete, before insert, before update) {
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (EM_Event_vod__c newEvent : Trigger.new) {
            if (newEvent.Override_Lock_vod__c == true) {
                newEvent.Override_Lock_vod__c = false;
            } else if (VOD_Utils.isEventLocked(newEvent)) {
            // Need to check old version to allow for lock button
                for (EM_Event_vod__c oldEvent : Trigger.old) {
                    if (oldEvent.Id.equals(newEvent.Id) &&
                        VOD_Utils.isEventLocked(oldEvent)) {
                        newEvent.addError('Event is locked');
                    }
                }
            }
        }
    } else {
        for (EM_Event_vod__c event : Trigger.old) {
            if(event.Override_Lock_vod__c == true) {
                event.Override_Lock_vod__c = false;
            } else if (VOD_Utils.isEventLocked(event)) {
                event.addError('Event is locked');
            }
        }
    }
}