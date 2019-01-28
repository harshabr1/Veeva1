trigger VEEVA_BEFORE_SAMPLE_LIMIT_AUDIT on Sample_Limit_vod__c (before delete, before update)
{
	if (CallSampleManagement.inSampleManagement) {
		return;
	}
	//CSABA  fire this trigger only  for regular  Sample Liit records not for templates too.

	Map<Id, Sample_Limit_vod__c> getImportantInfo =
			new Map<Id, Sample_Limit_vod__c> ([
					Select Id, User_vod__r.Username, User_vod__c,
					Product_vod__r.Name, Product_vod__c,
					Account_vod__r.Formatted_Name_vod__c, Account_vod__c
					From Sample_Limit_vod__c
					where Id in :Trigger.old]);

	List<Sample_Limit_Transaction_vod__c> auditRecs = new List<Sample_Limit_Transaction_vod__c> ();
	for (Integer i = 0; i < Trigger.old.size(); i++)
		{

			//CSABA  Skip  Templates from this
			if (Trigger.old[i].Account_Types_vod__c != NULL)// Trigger.new[i].Account_Types_vod__c != NULL)
				continue; //check if this is OK

			Sample_Limit_vod__c myLimit = Trigger.old[i];
			if (Trigger.isDelete || (Trigger.isUpdate && Trigger.new[i].Disable_Txn_Create_vod__c != true)) {

				Sample_Limit_vod__c myInfo = getImportantInfo.get(myLimit.Id);
				Sample_Limit_Transaction_vod__c slt = new Sample_Limit_Transaction_vod__c();

				slt.Account_vod__c = myLimit.Account_vod__c;
				slt.Account_Id_vod__c = myLimit.Account_vod__c;

				if (myInfo != null && myInfo.Account_vod__c != null) {
					slt.Account_Name_vod__c = myInfo.Account_vod__r.Formatted_Name_vod__c;
				}

				slt.Disbursed_Quantity_vod__c = myLimit.Disbursed_Quantity_vod__c;
				slt.End_Date_vod__c = myLimit.End_Date_vod__c;
				slt.Enforce_Limit_vod__c = myLimit.Enforce_Limit_vod__c;
				slt.External_Id_vod__c = myLimit.External_Id_vod__c;
				slt.Group_Id_vod__c = myLimit.Group_Id_vod__c;
				slt.Limit_Per_Call_vod__c = myLimit.Limit_Per_Call_vod__c;
				slt.Limit_Quantity_vod__c = myLimit.Limit_Quantity_vod__c;
				// adding the new fields for sample limit value
				slt.Limit_Amount_vod__c = myLimit.Limit_Amount_vod__c;
				slt.Disbursed_Amount_vod__c = myLimit.Disbursed_Amount_vod__c;
				slt.Product_vod__c = myLimit.Product_vod__c;
				slt.Product_Id_vod__c = myLimit.Product_vod__c;
				if (myInfo != null && myInfo.Product_vod__c != null) {
					slt.Product_Name_vod__c = myInfo.Product_vod__r.Name;
				}

				if (Trigger.isUpdate) {
					slt.Reason_vod__c = 'Update';
				} else {
					slt.Reason_vod__c = 'Delete';
				}

				slt.Remaining_Quantity_vod__c = myLimit.Remaining_Quantity_vod__c;
				// add the remaining amount as well
				slt.Remaining_Amount_vod__c = myLimit.Remaining_Amount_vod__c;
				slt.Sample_Limit_vod__c = myLimit.Id;
				slt.Sample_Limit_Id_vod__c = myLimit.Id;
				slt.Sample_Limit_Name_vod__c = myLimit.Name;
				slt.Sample_Limit_Type_vod__c = myLimit.Sample_Limit_Type_vod__c;
				slt.Start_Date_vod__c = myLimit.Start_Date_vod__c;
				slt.User_vod__c = myLimit.User_vod__c;
				slt.User_Id_vod__c = myLimit.User_vod__c;
				if (myInfo != null && myInfo.User_vod__c != null) {
					slt.User_Name_vod__c = myInfo.User_vod__r.Username;
				}

				auditRecs.add(slt);

			} else
			{
				Trigger.new[i].Disable_Txn_Create_vod__c = false;
			}
		}

	if (auditRecs.size() > 0) {
		insert auditRecs;
	}

}