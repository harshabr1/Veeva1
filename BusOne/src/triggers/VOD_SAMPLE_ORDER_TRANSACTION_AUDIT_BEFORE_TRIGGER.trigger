trigger VOD_SAMPLE_ORDER_TRANSACTION_AUDIT_BEFORE_TRIGGER on Sample_Order_Transaction_Audit_vod__c (before delete, before update) {
    Sample_Order_Transaction_Audit_vod__c [] records = null;
    
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE ();
    
    if (Trigger.isUpdate) {
        records = Trigger.new;
    } else {
        records = Trigger.old;  
    }
    
    // retrieve the error message before the for loop
    String sampOrdError = bundle.getErrorMsg ('NO_TOUCH_SAMP_ORDER_TRAN_AUD'); 
    System.Debug('the error message fetched from the new trigger is ' + sampOrdError);
    
    // This is a hard block.  The only way to delete or update is to disable the trigger.
    for (Sample_Order_Transaction_Audit_vod__c rec : records) {
        rec.Id.addError(sampOrdError, false);
    }

}