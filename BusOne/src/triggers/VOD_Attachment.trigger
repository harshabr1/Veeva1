trigger VOD_Attachment on Attachment (after insert, after update) {
    Set<String>pIds  =  new Set<String> ();
    
    for(Attachment att: Trigger.new){
    	pIds.add(att.ParentId);
    }
    
    Map<Id, Call2_vod__c> callMap= new Map<Id, Call2_vod__c>([select Id, Expense_Receipt_Status_vod__c, Override_Lock_vod__c, Status_vod__c, Expense_Amount_vod__c, Is_Parent_Call_vod__c from Call2_vod__c where Id in :pIds]);
    VOD_CALL2_ATTACHMENT_CLASS.updateReceiptAttachmentsPending(callMap);

}