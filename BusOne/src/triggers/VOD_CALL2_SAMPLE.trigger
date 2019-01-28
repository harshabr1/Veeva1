trigger VOD_CALL2_SAMPLE on Call2_Sample_vod__c (after insert, after update, after delete) {
    if (CallSampleManagement.inSampleManagement) {
        return;
    }
    
	// sample limit transaction
	if (Trigger.isAfter) {
		if (Trigger.isInsert || Trigger.isUpdate) {
			CallSampleManagement.applySampleLimit();
		}
        if (Trigger.isUpdate){
            Call2_Sample_vod__c [] cRow = Trigger.new;
            List<Call2_Sample_vod__c> toDelete = new List<Call2_Sample_vod__c>();
            Map<Id, Call2_Sample_vod__c> samplesToRevert = new Map<Id, Call2_Sample_vod__c>();
            for (Integer k = 0; k < cRow.size(); k++) {
                if (cRow[k].Mobile_ID_vod__c != null && cRow[k].Mobile_ID_vod__c.indexOf('REVERT') != -1){
                    samplesToRevert.put(cRow[k].Id, cRow[k]);
                    toDelete.add(new Call2_Sample_vod__c(Id = cRow[k].Id));
                }
            }
            if (!samplesToRevert.isEmpty()){
                delete toDelete;
                CallSampleManagement.onDeleteCallSample(samplesToRevert);
            }
        }
	}
}