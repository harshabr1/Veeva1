trigger Child_Account_Before_UPDINS on Child_Account_vod__c (before insert, before update) {
    List<Child_Account_vod__c> toBeValidated = new List<Child_Account_vod__c>();
    for (Integer i=0; i < Trigger.new.size(); i++) {
        Child_Account_vod__c record = Trigger.new[i];
        Child_Account_vod__c oldRecord = (Trigger.isUpdate ? Trigger.old[i] : null);        
        record.External_ID_vod__c = record.Parent_Account_vod__c + '__' + record.Child_Account_vod__c;
        if (oldRecord == null || oldRecord.Parent_Account_vod__c != record.Parent_Account_vod__c || 
                                                     oldRecord.Child_Account_vod__c != record.Child_Account_vod__c) {
            toBeValidated.add(record);
        }
    }
    if (toBeValidated.size() > 0) {
	    VOD_SHADOW_ACCOUNT.rejectInvalidAccounts(
            toBeValidated, new List<String> {'Parent_Account_vod__c', 'Child_Account_vod__c'});
	}
}