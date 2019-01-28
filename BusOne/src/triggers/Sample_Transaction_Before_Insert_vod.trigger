trigger Sample_Transaction_Before_Insert_vod on Sample_Transaction_vod__c (before insert) {
    RecordType [] recType  = VOD_SAMPLE_TRANSACTION.recType;
	String tranRecordId = null;
	VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
	for (Integer k = 0; k < recType.size (); k++) {
    	if (recType[k].Name == 'Transfer_vod') {
        	tranRecordId = recType[k].Id;
		}   
	} 
    for (Sample_Transaction_vod__c tran : Trigger.new) { 
        if (tran.Status_vod__c == 'Submitted_vod') 
            tran.Submitted_Date_vod__c = System.today();
            
        if (tranRecordId == tran.RecordTypeId) {
             if (tran.Transfer_To_vod__c == null) {
                	tran.Id.addError(bundle.getErrorMsg('TRANSFER_TO_REQ'), false);
             }
        }
    }
}