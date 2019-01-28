trigger VOD_BEFORE_MED_INQ_INS on Medical_Inquiry_vod__c (before insert) {
    for (Integer i = 0; i <Trigger.new.size(); i++) {
        Medical_Inquiry_vod__c medInqNew = Trigger.new[i];
        if (medInqNew.Status_vod__c == 'Submitted_vod') {
            medInqNew.Lock_vod__c = true;
            medInqNew.Previously_Submitted_vod__c = true;
        }
                
        if (medInqNew.Entity_Reference_Id_vod__c != null && 
            medInqNew.Entity_Reference_Id_vod__c.length() > 0) {
            
            medInqNew.Account_vod__c = medInqNew.Entity_Reference_Id_vod__c;
            medInqNew.Entity_Reference_Id_vod__c = null;
                
        }
    }
}