trigger VOD_SAMPLE_ORDER_TRANSACTION_BEFORE on Sample_Order_Transaction_vod__c (before update,before delete) {
    String ProfileId = UserInfo.getProfileId();
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
    Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
    boolean modAllData = false;
    if (pr != null && pr.PermissionsModifyAllData)
       modAllData = true;
    if (Trigger.isUpdate) {
        boolean isUnlocked = false;            
        for (Sample_Order_Transaction_vod__c so : Trigger.new) {
            if (so.Unlock_vod__c == true) {
                so.Status_vod__c = 'Saved_vod';
                so.Unlock_vod__c = false;
                isUnlocked = true;
            } else {
                if (modAllData == false && Trigger.oldMap.get(so.Id).Status_vod__c == 'Submitted_vod') {
                	if (VEEVA_SAMPLE_CANCEL.isSampleCancel == false) 
                       so.Id.addError(bundle.getErrorMsg('UPD_SAMPORDER'), false);
                }
            }
        }
    } else {
        //  
        for (Sample_Order_Transaction_vod__c so : Trigger.old) {
            if ( so.Status_vod__c == 'Submitted_vod') {
                so.Id.addError(bundle.getErrorMsg('DEL_SAMPORDER'), false);
            }
        }
    }
}