trigger Server_Job_Before_Update on Server_Job_Status_vod__c (before update) {
    for (Integer i = 0; i < Trigger.old.size(); i++) {
        if (Trigger.new[i].Rows_Processed_vod__c != 0) {
             if (Trigger.new[i].Rows_Processed_vod__c < Trigger.old[i].Rows_Processed_vod__c){
                 String errMsg = VOD_GET_ERROR_MSG.getErrorMsg('ERROR_ROWS_PROCESSED', 'Common');
                 Trigger.new[i].Rows_Processed_vod__c.addError(errMsg, false);
             }
        }
    }
}