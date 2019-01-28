trigger VOD_BEFORE_MED_INQ_UPD on Medical_Inquiry_vod__c (before update) {
    
    String ProfileId = UserInfo.getProfileId();
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
    Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
    boolean modAllData = false;
    if (pr != null && pr.PermissionsModifyAllData)
        modAllData = true;
    
    for (Integer i = 0; i <Trigger.new.size(); i++) {
        Medical_Inquiry_vod__c medInqNew = Trigger.new[i];
        
        Medical_Inquiry_vod__c medInqOld = Trigger.old[i];
        
        // here continue if override lock is true
        if (medInqNew.Override_Lock_vod__c == true) {
            medInqNew.Override_Lock_vod__c = false;
            continue;
        }
        
        
        if (medInqNew.Lock_vod__c == true && modAllData != true) {
            medInqNew.Id.addError(bundle.getErrorMsg('CANNOT_UPD_INQ'), false);
        }       
        
        if (medInqOld.Lock_vod__c == true && medInqNew.Lock_vod__c == false) {
            medInqNew.Status_vod__c = 'Saved_vod';
        }
        
        if (medInqNew.Status_vod__c == 'Submitted_vod') {
            medInqNew.Lock_vod__c = true;            
        }
        
        if (medInqOld.Status_vod__c == 'Submitted_vod') {
            medInqNew.Previously_Submitted_vod__c = true;  
        } else if (medInqNew.Status_vod__c == 'Submitted_vod') {
            medInqNew.Previously_Submitted_vod__c = true;      
        } else if (medInqOld.Previously_Submitted_vod__c && !medInqNew.Previously_Submitted_vod__c) {
            medInqNew.Previously_Submitted_vod__c = true;    
        }
    }   
}