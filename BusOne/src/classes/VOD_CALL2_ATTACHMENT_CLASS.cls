public class VOD_CALL2_ATTACHMENT_CLASS {

	public static boolean inCallAttachment = false;
	public static void updateReceiptAttachmentsPending(Map<Id, Call2_vod__c> calls) {
		List<Call2_vod__c> toUpdate = new List<Call2_vod__c>();
		List<Attachment> attachments = [select Id, ParentId, Body from Attachment where ParentId in :calls.keySet() and Name LIKE '_Exp%'];
		Map<String, List<Attachment>> callToAttachments = new Map<String, List<Attachment>>();
		for (Attachment att : attachments) {
			if (callToAttachments.get(att.ParentId) == null)
				callToAttachments.put(att.ParentId, new List<Attachment>());
			callToAttachments.get(att.ParentId).add(att);
		}
		boolean missingAttachmentBodies = false;
		for (Id callId : callToAttachments.keySet()) {
			Call2_vod__c call = calls.get(callId);
			if ('Submitted_vod'.equals(call.Status_vod__c)
					&& call.Expense_Amount_vod__c > 0
					&& call.Is_Parent_Call_vod__c == 1.0
					&& (call.Expense_Receipt_Status_vod__c == '' || call.Expense_Receipt_Status_vod__c == null)) {
				missingAttachmentBodies = false;
				if (callToAttachments.containsKey(call.Id)) {
					for (Attachment attach : callToAttachments.get(call.Id)) {
						if (attach.Body == null) {
							missingAttachmentBodies = true;
							break;
						}
					}
				}
				if (!missingAttachmentBodies) {
					toUpdate.add(new Call2_vod__c(Id = call.Id, Expense_Receipt_Status_vod__c = 'Pending'));
				}
			}
		}

		if (toUpdate.size() > 0) {
			inCallAttachment = true;
			update (toUpdate);
			inCallAttachment = false;
		}
	}
}