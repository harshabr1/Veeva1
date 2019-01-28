trigger VOD_CALL2_BEFORE_DEL_TRIGGER on Call2_vod__c (before delete) {

	Map <Id,Call2_vod__c> callMaps;
	List <String> callIds = new List <String> ();
	String noUpdSub = null;
	String noDelSub = null;
	String noDelCallWithTran = null;
	boolean callArchiveUser = false;
	String ProfileId = UserInfo.getProfileId();
	VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
	Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
	boolean modAllData = false;

	if (pr != null && pr.PermissionsModifyAllData)
		modAllData = true;


	if (Trigger.isDelete) {
		callMaps = new Map<Id, Call2_vod__c> ([SELECT Id, Parent_Call_vod__r.Status_vod__c, (SELECT Id, Call2_vod__c FROM Call_Objectives_vod__r) from Call2_vod__c where ID in :Trigger.old]);
		noDelCallWithTran =  VOD_GET_ERROR_MSG.getErrorMsg('NO_DEL_CALL_W_TRAN','TriggerError');
		noDelSub = VOD_GET_ERROR_MSG.getErrorMsg('NO_DEL_SUB','TriggerError');
		CallSampleManagement.onDeleteCall(Trigger.oldMap);
	}

	Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
	if (vsc !=  null && vsc.CALL_ARCHIVE_USER_vod__c == UserInfo.getUserName())
	{
		callArchiveUser = true;
	}

	for (Integer i = 0 ; i < Trigger.old.size(); i++) {
		Call2_vod__c info =  callMaps.get (Trigger.old[i].Id);
		String parentStatus = info.Parent_Call_vod__r.Status_vod__c;

		if (info.Call_Objectives_vod__r != null) {
			for (Call_Objective_vod__c objective : info.Call_Objectives_vod__r) {
				objective.Call2_vod__c = null;
				VEEVA_CALL_OBJECTIVE_TRIG.objectives.add(objective);
			}
		}

		if (callArchiveUser)
		{
			callIds.add (Trigger.old[i].Id);
		}
		else {
			if (VeevaSettings.isEnableSamplesOnSave() == true &&
							Trigger.old[i].Status_vod__c == 'Saved_vod' &&
					(Trigger.old[i].Sample_Send_Card_vod__c != null ||  Trigger.old[i].Sample_Card_vod__c != null)) {
				Trigger.old[i].Status_vod__c.addError(noDelCallWithTran, false);
			}

			if (Trigger.old[i].Signature_Date_vod__c != null) {
				if (modAllData == false) {
					Trigger.old[i].Signature_Date_vod__c.addError(bundle.getErrorMsg('NO_SIG_DEL'), false);
				}
			}

			if (Trigger.old[i].Status_vod__c == 'Submitted_vod' || parentStatus == 'Submitted_vod') {
				Trigger.old[i].Id.addError (noDelSub, false);
			}
			else {
				callIds.add (Trigger.old[i].Id);
			}
		}

	}

	for (Call2_vod__c[] delCalls : [Select Id from Call2_vod__c where Parent_Call_vod__c in :callIds]) {
		try {
			delete delCalls;
		} catch (System.DmlException e) {
			Integer numErrors = e.getNumDml();
			String error = '';
			for (Integer i = 0; i < numErrors; i++) {
				Id thisId = e.getDmlId(i);
				if (thisId != null)  {
					error += e.getDmlMessage(i) +'\n';
				}
			}

			for (Call2_vod__c errorRec : Trigger.old) {
				errorRec.Id.addError(error, false);
			}
		}
	}
}