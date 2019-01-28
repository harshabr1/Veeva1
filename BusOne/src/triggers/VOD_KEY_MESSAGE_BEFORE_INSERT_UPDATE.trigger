trigger VOD_KEY_MESSAGE_BEFORE_INSERT_UPDATE on Key_Message_vod__c (before insert, before update) {
    for(Integer i = 0; i < Trigger.new.size(); i++) {
        if(String.isNotBlank(Trigger.new[i].Media_File_Name_vod__c) && String.isBlank(Trigger.new[i].CLM_ID_vod__c)) {
        	if(Trigger.isUpdate) {
                if(String.isBlank(Trigger.old[i].CLM_ID_vod__c)) {
            		Trigger.new[i].CLM_ID_vod__c = 'CLM ID';
                }
            } else {
            	Trigger.new[i].CLM_ID_vod__c = 'CLM ID';
            }
        }
    }
}