trigger Key_Stakeholder_Name_Stamp on Key_Stakeholder_vod__c (before update, before insert) {

    for(Key_Stakeholder_vod__c stakeholder : Trigger.new) {
        if(stakeholder.Key_Stakeholder_vod__c != null) {
		Account acct = [select Formatted_Name_vod__c FROM Account where id = :stakeholder.Key_Stakeholder_vod__c];
		stakeholder.Key_Stakeholder_Name_vod__c = acct.Formatted_Name_vod__c;
        }    
    }

}