trigger Sample_Limit_Transaction_vod on Sample_Limit_Transaction_vod__c (After insert, After delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CallSampleManagement.onSampleLimitTransactionCreated(Trigger.newMap.values());
        }        
    }
}