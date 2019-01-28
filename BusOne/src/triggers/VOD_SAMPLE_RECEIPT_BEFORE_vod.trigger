trigger VOD_SAMPLE_RECEIPT_BEFORE_vod on Sample_Receipt_vod__c (before update) {
    VOD_ERROR_MSG_BUNDLE errBundle = new VOD_ERROR_MSG_BUNDLE ();
    
    for (Integer i = 0; i < Trigger.new.size (); i++) {
        if (Trigger.old[i].Received_vod__c == true) {
            Trigger.new[i].Confirmed_Quantity_vod__c.addError(errBundle.getErrorMsg('NO_DOUBLE_CONFIRM'), false);
        } else { 
            if (Trigger.new[i].Confirmed_Quantity_vod__c != null) {
                Trigger.new[i].Received_vod__c = true;
            }
        }
    }

}