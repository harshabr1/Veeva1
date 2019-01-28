trigger VOD_MC_CP_SUMMARY_BEFORE_INSERT on MC_Cycle_Plan_Summary_vod__c (before insert) {

	String profileId = Userinfo.getProfileId();
	Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :profileId];
	boolean profileModAllData = false;
	if (pr != null){
		profileModAllData = pr.PermissionsModifyAllData;
	}

	User user = new Map<Id,User>([Select MCCP_Admin_vod__c from User where User.Id=:Userinfo.getUserId()]).get(Userinfo.getUserId());
	boolean isMccpAdmin = user.MCCP_Admin_vod__c;

	List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='MCCP_LOCK_MSG' AND Category_vod__c='Multichannel' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
	String errorText;
	if(messages.size() != 0){
		errorText = messages[0].Text_vod__c;
	}
	else{
		errorText = 'You do not have sufficient privileges to edit or delete a locked cycle plan.';
	}

	List<Id> cpIds = new List<Id>();
	for(MC_Cycle_Plan_Summary_vod__c summary: Trigger.new){
		cpIds.add(summary.Cycle_Plan_vod__c);        
	}
	Map<Id,MC_Cycle_Plan_vod__c> cyclePlanMap = new Map<Id, MC_Cycle_Plan_vod__c>([SELECT Id, Lock_vod__c FROM MC_Cycle_Plan_vod__c WHERE Id IN :cpIds]);

	for(Integer i = 0; i< Trigger.new.size(); i++){
		MC_Cycle_Plan_Summary_vod__c newPlan = Trigger.new[i];

		//if true, then lock the record
		if(cyclePlanMap.get(newPlan.Cycle_Plan_vod__c).Lock_vod__c && !profileModAllData && !isMccpAdmin){
			newPlan.addError(errorText);
		}    
	}
}