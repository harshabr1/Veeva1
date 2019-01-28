trigger Stakeholder_Owner_Name_Stamp on Key_Stakeholder_vod__c (before update, before insert) {
    for(Key_Stakeholder_vod__c stakeholder : Trigger.new) {
	if(stakeholder.Stakeholder_Owner_vod__c != null) {
            User user = [select Name FROM User where id = :stakeholder.Stakeholder_Owner_vod__c];
            stakeholder.Stakeholder_Owner_Name_vod__c = user.Name;
        }    
    }
}