trigger VOD_MC_CP_TARGET_BEFORE_INSERT_UPDATE on MC_Cycle_Plan_Target_vod__c (before insert, before update) {

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
	for(MC_Cycle_Plan_Target_vod__c cyclePlanTarget: Trigger.new){
		cpIds.add(cyclePlanTarget.Cycle_Plan_vod__c);
	}
	Map<Id,MC_Cycle_Plan_vod__c> cyclePlanMap = new Map<Id, MC_Cycle_Plan_vod__c>([SELECT Id, Lock_vod__c FROM MC_Cycle_Plan_vod__c WHERE Id IN :cpIds]);
	Map<String, List<MC_Cycle_Plan_Target_vod__c>> vExternalToTargets = new Map<String, List<MC_Cycle_Plan_Target_vod__c>>();

	//for both insert and update 
	for(MC_Cycle_Plan_Target_vod__c target: Trigger.New){
		if(target.Cycle_Plan_vod__c != null && target.Target_vod__c != null){
			target.VExternal_Id_vod__c = target.Cycle_Plan_vod__c + '__' + target.Target_vod__c + '__'+ target.Status_vod__c; 
			target.Child_Account_vod__c = null;
			if (target.Location_vod__c != null) {
				target.VExternal_Id_vod__c += '__' + target.Location_vod__c;
				if (vExternalToTargets.get(target.Location_vod__c+'__'+target.Target_vod__c) == null) 
					vExternalToTargets.put(target.Location_vod__c+'__'+target.Target_vod__c, new List<MC_Cycle_Plan_Target_vod__c>());
				vExternalToTargets.get(target.Location_vod__c+'__'+target.Target_vod__c).add(target);
            }

			if(Trigger.isInsert){
				//if true, then lock the record
				if(cyclePlanMap.get(target.Cycle_Plan_vod__c).Lock_vod__c && !profileModAllData && !isMccpAdmin){
					target.addError(errorText);
				}
			}
		}
	}
	if (vExternalToTargets.keySet().size() > 0) {
		List<Child_Account_vod__c> childAccounts = [SELECT Id, External_ID_vod__c FROM Child_Account_vod__c WHERE External_ID_vod__c IN :vExternalToTargets.keySet()];
		for (Child_Account_vod__c childAccount : childAccounts) {
			if (vExternalToTargets.get(childAccount.External_ID_vod__c) != null) {
				for (MC_Cycle_Plan_Target_vod__c target : vExternalToTargets.get(childAccount.External_ID_vod__c)) {
					target.Child_Account_vod__c = childAccount.Id;
				}
			}
		}
	}
}