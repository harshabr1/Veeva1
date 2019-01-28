trigger VOD_EM_EVENT_HISTORY_AFTER_DELETE on EM_Event_History_vod__c (after delete) {
    List<String> history_ids = new List<String>();
    if (trigger.old != null){
        for (EM_Event_History_vod__c history : trigger.old){
            history_ids.add(history.Id);
        }
    }
    if (history_ids.size() > 0){
        List<EM_Event_History_vod__Share> historyShares = [SELECT ParentId, UserOrGroupId, AccessLevel, RowCause FROM EM_Event_History_vod__Share WHERE ParentId IN :history_ids];
        List<Database.DeleteResult> deleteResults = Database.delete(historyShares, false);
        for (Database.DeleteResult result: deleteResults){
            if (!result.isSuccess()){
             system.debug('delete error: ' + result.getErrors()[0]);
           }
        }
    }
}