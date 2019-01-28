trigger VEEVA_BEFORE_SAMPLE_LIMITS on Sample_Limit_vod__c (before insert, before update) {

	if (CallSampleManagement.inSampleManagement) {
		return;
	}
	if (VOD_ACCOUNT_TRIG.accountMergeSampleLimit) {
		return;
	}

	List<String> prodIds = new List<String>();
	for (Sample_Limit_vod__c myLimit : Trigger.new) {
		String product = myLimit.Product_vod__c;
		if ((product != null) && (product != '')) {
			prodIds.add(product);
		}
	}
	Map<Id, Product_vod__c> prods =
			new Map<Id, Product_vod__c>([Select Id, Product_Type_vod__c From Product_vod__c Where Id = :prodIds]);

	for (Sample_Limit_vod__c myLimit : Trigger.new) {
		String account = myLimit.Account_vod__c;
		if (account == null)
			account = '';

		String tmpAccount;
		if (account != null && account.length() > 15)
			tmpAccount = account.substring(0, 15);
		else
			tmpAccount = account;

		String product = myLimit.Product_vod__c;
		if (product == null)
			product = '';

		String user = myLimit.User_vod__c;
		if (user == null)
			user = '';

		//added Type determiniation
		if (user == '' && account == '' && myLimit.Account_Types_vod__c != null && myLimit.Account_Types_vod__c != '')
			account = 'Template_vod';

		myLimit.Group_Id_vod__c = VOD_CALL2_CHILD_COMMON.getLimitId(account, product, user);

		String limitType = '';
		if (myLimit.Account_vod__c != null && myLimit.User_vod__c != null)
			limitType = '1';

		else if (myLimit.Account_vod__c != null ||
						myLimit.Account_Types_vod__c != NULL) //CSABA added 2013.03.22
		{
			Product_vod__c theProd = null;
			if (myLimit.Product_vod__c != null)
				theProd = prods.get(myLimit.Product_vod__c);
			if ((theProd != null) && (theProd.Product_Type_vod__c == 'Sample Product Group'))
				limitType = '4';
			else
				limitType = '2';
		} else
		{

			if (myLimit.Account_Types_vod__c == NULL) //CSABA 2013.03.22. do not do below for Templates
				limitType = '3'; //original
		}
		if (myLimit.Limit_Per_Call_vod__c == true)
			limitType = '0' + limitType;
		myLimit.Sample_Limit_Type_vod__c = limitType;

		//CSABA 2013.03.27. put here the Unique Key calculation
		if (myLimit.Account_Types_vod__c != NULL)
		{
			myLimit.Template_Unique_Key_vod__c = myLimit.Account_Types_vod__c + '_' +
					myLimit.Sample_Limit_Type_vod__c + '_' +
					myLimit.Product_vod__c + '_' +
					myLimit.Start_Date_vod__c + '_' +
					myLimit.End_Date_vod__c + '_' +
					myLimit.Template_Group_vod__c;

		}
		//CSABA 2013.03.27. put here the Unique Key calculation
	}

}