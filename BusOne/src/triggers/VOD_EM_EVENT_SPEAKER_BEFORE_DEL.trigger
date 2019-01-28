trigger VOD_EM_EVENT_SPEAKER_BEFORE_DEL on EM_Event_Speaker_vod__c (before delete) {
    Set<String> associatedEvents = new Set<String>();
    Set<String> lockedEvents = new Set<String>();
    
    for (EM_Event_Speaker_vod__c speaker : Trigger.old) {
        if (speaker.Event_vod__c != null) {
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
    
    for (EM_Event_Speaker_vod__c speaker : Trigger.old) {
        if (speaker.Event_vod__c != null && lockedEvents.contains(speaker.Event_vod__c)) {
            speaker.addError('Event is locked');
        }
    }
    
    for (Event_Attendee_vod__c[] deleteAttStubs :
        [SELECT Id FROM Event_Attendee_vod__c 
         WHERE EM_Event_Speaker_vod__c IN :Trigger.oldMap.keySet()]) {
        try {
            delete deleteAttStubs;
        } catch (System.DmlException e) {
            Integer numErrors = e.getNumDml();
            String error = '';
            for (Integer i = 0; i < numErrors; i++) {
                  Id thisId = e.getDmlId(i);
                  if (thisId != null)  {
                        error += e.getDmlMessage(i) +'\n';
                  }
            }
    
            for (EM_Event_Speaker_vod__c errorRec : Trigger.old) {
                errorRec.Id.addError(error);    
            }   
                    
        }
    }   
}