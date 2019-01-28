trigger VOD_MEDICAL_INQUIRY_AUDIT_BEFORE_TRIGGER on Medical_Inquiry_Audit_vod__c (before delete, before update) {
    Medical_Inquiry_Audit_vod__c [] records = null;
     
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE ();
     
    if (Trigger.isUpdate) {
        records = Trigger.new;
    } else {
        records = Trigger.old; 
    }
     
    // retrieve the error message before the for loop
    String medInqError = VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_MED_INQ_AUDIT','MEDICAL_INQUIRY');         

    // This is a hard block.  The only way to delete or update is to disable the trigger.
    for (Medical_Inquiry_Audit_vod__c rec : records) {
        rec.Id.addError(medInqError , false);
        }
    }