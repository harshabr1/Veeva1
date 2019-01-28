trigger VOD_EM_ATTENDEE_BEFORE_DEL on EM_Attendee_vod__c (before delete) {
    VOD_Utils.setTriggerEmAttendee(true);
    if(!VOD_Utils.isTriggerEventAttendee()) {
		for (Event_Attendee_vod__c[] deleteAttStubs :[SELECT Id FROM Event_Attendee_vod__c 
              WHERE EM_Attendee_vod__c IN :Trigger.oldMap.keySet()]) {
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
                
                for (EM_Attendee_vod__c errorRec : Trigger.old) {
                    errorRec.Id.addError(error);    
                }   
                
            }
    	}         
    }    
}