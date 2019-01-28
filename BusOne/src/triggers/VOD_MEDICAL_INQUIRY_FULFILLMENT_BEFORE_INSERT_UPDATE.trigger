trigger VOD_MEDICAL_INQUIRY_FULFILLMENT_BEFORE_INSERT_UPDATE on Medical_Inquiry_Fulfillment_vod__c (before insert, before update) {
    for(Medical_Inquiry_Fulfillment_vod__c mif: Trigger.new) {        
        if (mif.Entity_Reference_Id_vod__c != null) {
            mif.Account_vod__c = mif.Entity_Reference_Id_vod__c;
            mif.Entity_Reference_Id_vod__c = null;
        }
    }

}