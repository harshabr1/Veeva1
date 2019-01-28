trigger Sample_Transaction_Before_Delete_vod on Sample_Transaction_vod__c (before delete) {

    for (Sample_Transaction_vod__c tran : Trigger.old) 
        if (tran.Status_vod__c == 'Submitted_vod') 
            tran.Id.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_SAMP_TRAN','TriggerError'), false);
            
}