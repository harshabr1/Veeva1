trigger VOD_EXPENSE_HEADER_AFTER_DELETE on Expense_Header_vod__c (after delete) {
    List<Expense_Header_vod__Share> headerShares = [SELECT ParentId, UserOrGroupId, AccessLevel, RowCause FROM Expense_Header_vod__Share WHERE ParentId IN :Trigger.OldMap.keyset()];
    List<Database.DeleteResult> deleteResults = Database.delete(headerShares, false);
    for(Database.DeleteResult result: deleteResults){
        if(!result.isSuccess()){
            system.debug('delete error: ' + result.getErrors()[0]);
        }
    }
    
    Map<String, EM_Event_vod__c> eventsMap = new Map<String, EM_Event_vod__c>();
    for(Expense_Header_vod__c oldHeader: Trigger.old) {
        if(oldHeader.Concur_Status_vod__c != null) {
            if(eventsMap.get(oldHeader.Event_vod__c) == null) {
                EM_Event_vod__c event = new EM_Event_vod__c(Id = oldHeader.Event_vod__c,
                                                            Failed_Expense_vod__c = true,
                                                            Override_Lock_vod__c = true);
                eventsMap.put(oldHeader.Event_vod__c, event);
            }
        }
    }


    if(eventsMap.values() != null) {
        update eventsMap.values();
    }
}