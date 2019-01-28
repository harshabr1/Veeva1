trigger VOD_EM_EVENT_BEFORE_DEL on EM_Event_vod__c (before delete) {
    for (Medical_Event_vod__c[] deleteEventStubs :
        [SELECT Id FROM Medical_Event_vod__c 
         WHERE EM_Event_vod__c IN :Trigger.oldMap.keySet()]) {
        try {
            delete deleteEventStubs;
        } catch (System.DmlException e) {
            Integer numErrors = e.getNumDml();
            String error = '';
            for (Integer i = 0; i < numErrors; i++) {
                  Id thisId = e.getDmlId(i);
                  if (thisId != null)  {
                        error += e.getDmlMessage(i) +'\n';
                  }
            }
    
            for (EM_Event_vod__c errorRec : Trigger.old) {
                errorRec.Id.addError(error);    
            }   
                    
        }
    }   
}