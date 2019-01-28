trigger Sample_Order_Transaction_vod on Sample_Order_Transaction_vod__c (after insert) {
	if (Trigger.isAfter) {
		if (Trigger.isInsert) {
			CallSampleManagement.onSampleOrderTransactionCreated(Trigger.newMap.values());
		}
	}
}