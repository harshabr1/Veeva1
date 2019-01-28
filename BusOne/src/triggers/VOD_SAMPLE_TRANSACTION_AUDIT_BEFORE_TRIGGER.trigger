trigger VOD_SAMPLE_TRANSACTION_AUDIT_BEFORE_TRIGGER on Sample_Transaction_Audit_vod__c (before delete, before update) {
    Sample_Transaction_Audit_vod__c [] records = null;
    
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE ();
    
    if (Trigger.isUpdate) {
        records = Trigger.new;
    } else {
        records = Trigger.old;  
    } 
    
    // This is a hard block.  The only way to delete or update is to disable the trigger.
    for (Sample_Transaction_Audit_vod__c rec : records) {
        rec.Id.addError(bundle.getErrorMsg ('NO_TOUCH_SAMP_TRAN_AUD'), false);
    }
    
}