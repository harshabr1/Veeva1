trigger VOD_SAMPLE_ORDER_TRANSACTION_BEFORE_INSERT on Sample_Order_Transaction_vod__c (before insert) {
     RecordType [] recType  = VOD_SAMPLE_ORDER_TRANSACTION.recType;
     String tranRecordId = null;
     VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
     for (Integer k = 0; k < recType.size (); k++) {
          if (recType[k].Name == 'Transfer_vod') {
              tranRecordId = recType[k].Id;
              break;
          }   
     }
     
     String errMsg = bundle.getErrorMsg('TRANSFER_TO_REQ'); 
     for (Sample_Order_Transaction_vod__c tran : Trigger.new) { 
        if (tran.Status_vod__c == 'Submitted_vod') 
            tran.Submitted_Date_vod__c = System.today();
            
        if (tranRecordId == tran.RecordTypeId) {
             if (tran.Transfer_To_vod__c == null) {
                  tran.Id.addError(errMsg , false);
             }
        }
    }

}