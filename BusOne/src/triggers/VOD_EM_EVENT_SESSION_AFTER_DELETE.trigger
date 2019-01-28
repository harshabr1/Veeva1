trigger VOD_EM_EVENT_SESSION_AFTER_DELETE on EM_Event_Session_vod__c (after delete) {
    List<String> session_ids = new List<String>();
    if(trigger.old != null){
        for(EM_Event_Session_vod__c session : trigger.old){
            session_ids.add(session.Id);
        }
    }
    if(session_ids.size() > 0){
        List<EM_Event_Session_vod__Share> sessionShares = [SELECT ParentId, UserOrGroupId, AccessLevel, RowCause FROM EM_Event_Session_vod__Share WHERE ParentId IN :session_ids];
        List<Database.DeleteResult> deleteResults = Database.delete(sessionShares, false);
        for(Database.DeleteResult result: deleteResults){
            if(!result.isSuccess()){
             system.debug('delete error: ' + result.getErrors()[0]);
           }
        }
    }

}