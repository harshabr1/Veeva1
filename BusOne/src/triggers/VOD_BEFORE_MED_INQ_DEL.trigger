trigger VOD_BEFORE_MED_INQ_DEL on Medical_Inquiry_vod__c (before delete) {
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
    for (Integer i = 0; i <Trigger.old.size(); i++) {
        Medical_Inquiry_vod__c medInqOld = Trigger.old[i];
        
        if (medInqOld.Lock_vod__c == true) {
            medInqOld.Id.addError(bundle.getErrorMsg('CANNOT_DEL_INQ'), false);
        } 
        else if (medInqOld.Signature_Date_vod__c != null) {
            medInqOld.Id.addError(System.Label.NO_DEL_MED_INQ_WITH_SIG, false);
        } 
    }
}