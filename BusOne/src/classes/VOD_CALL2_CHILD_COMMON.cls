public class VOD_CALL2_CHILD_COMMON {


	public static boolean isLocked(String Id, Map <Id, Call2_vod__c> calls) {
		Call2_vod__c call = calls.get(Id);

		if (call != null) {
			if (call.Parent_Call_vod__r != null) {
				if (call.Parent_Call_vod__r.Status_vod__c == 'Submitted_vod')
					return true;
			}

			if (call.Status_vod__c == 'Submitted_vod')
				return true;
		}
		return false;
	}

	public static Map <Id, Call2_vod__c> getCallMap(List <String> callIds) {
		Map <Id, Call2_vod__c> calls =
				new Map <Id, Call2_vod__c> (
						[Select Id, Name,Parent_Call_vod__r.Status_vod__c, Status_vod__c, Override_Lock_vod__c, OwnerId, Call_Date_vod__c
								From Call2_vod__c
								Where Id in :callIds]);
		return calls;

	}

	public static String getLimitId(String account, String product, String User) {
		String tmpAccount;
		//encapsulating original logic with new condition
		//Condition for Template case
		if (account != null && account.equals('Template_vod')) {
			tmpAccount = '__' + product + '____' + account + '__';

		} else {
			if (account != null && account.length() > 15)
				tmpAccount = account.substring(0, 15);
			else
				tmpAccount = account;

			tmpAccount += '__' + product + '__' + user + '__';
		}
		return tmpAccount;
	}

	public static Sample_Limit_Transaction_vod__c createTransactionRecord(Call2_Sample_vod__c cRow,
																		  Sample_Limit_vod__c checkLimit,
																		  Call2_vod__c myCall,
																		  Boolean isSkipValueLimit) {
		String ownerId = null;
		Date CallDate = null;
		String callName = null;
		String callId = null;
		if (myCall != null) {
			ownerId = myCall.OwnerId;
			CallDate = myCall.Call_Date_vod__c;
			callName = myCall.Name;
			callId = myCall.Id;
		}

		boolean isMultiCurrency = false;

		// check for multicurrency
		SOBject callSampleInterface = (SObject) cRow;
		String currCodeCSample = null;
		try {
			currCodeCSample = (String)callSampleInterface.get('CurrencyIsoCode');
		} catch (System.SObjectException e) {
		}

		if (currCodeCSample != null) {
			isMultiCurrency = true;
		}


		Sample_Limit_Transaction_vod__c slt = new Sample_Limit_Transaction_vod__c();
		System.debug('crow=' + cRow);

		// Call information
		slt.Call2_Id_vod__c = callId;
		slt.Call_Name_vod__c = callName;
		slt.Call2_vod__c = callId;

		slt.Lot_vod__c = cRow.Lot_vod__c;
		slt.Quantity_To_Disperse_vod__c = cRow.Quantity_vod__c;

		if (checkLimit != null) {
			if (checkLimit.Product_vod__c != null) {
				slt.Product_vod__c = checkLimit.Product_vod__c;
				slt.Product_Id_vod__c = checkLimit.Product_vod__c;
				slt.Product_Name_vod__c = checkLimit.Product_vod__r.Name;
			}

			if (checkLimit.Account_vod__c != null) {
				slt.Account_vod__c = checkLimit.Account_vod__c;
				slt.Account_Id_vod__c = checkLimit.Account_vod__c;
				slt.Account_Name_vod__c = checkLimit.Account_vod__r.Formatted_Name_vod__c;
			}

			//add the amount to disperse check if its value based limit only then update the amount
			if (checkLimit.Limit_Amount_vod__c != null && !isSkipValueLimit) {
				slt.Amount_To_Disburse_vod__c = cRow.Amount_vod__c;
				// here check if its multicurrency
				SOBject slInterface = (SObject) checkLimit;
				String currCodeSL = null;
				try {
					currCodeSL = (String)slInterface.get('CurrencyIsoCode');
				} catch (System.SObjectException e) {
				}
				if (isMultiCurrency && currCodeSL != null) {
					slt.put('CurrencyIsoCode', currCodeSL);
				}
				// add the disbursed amnount as well
				slt.Disbursed_Amount_vod__c = checkLimit.Disbursed_Amount_vod__c;
				// limit amount
				slt.Limit_Amount_vod__c = checkLimit.Limit_Amount_vod__c;
				// remaining amount
				slt.Remaining_Amount_vod__c = checkLimit.Remaining_Amount_vod__c;
			}

			slt.Disbursed_Quantity_vod__c = checkLimit.Disbursed_Quantity_vod__c;
			slt.Start_Date_vod__c = checkLimit.Start_Date_vod__c;
			slt.End_Date_vod__c = checkLimit.End_Date_vod__c;
			slt.Group_Id_vod__c = checkLimit.Group_Id_vod__c;
			slt.Enforce_Limit_vod__c = checkLimit.Enforce_Limit_vod__c;
			slt.Limit_Per_Call_vod__c = checkLimit.Limit_Per_Call_vod__c;
			slt.Limit_Quantity_vod__c = checkLimit.Limit_Quantity_vod__c;
			slt.Reason_vod__c = cRow.Name;
			slt.Remaining_Quantity_vod__c = checkLimit.Remaining_Quantity_vod__c;
			slt.Sample_Limit_vod__c = checkLimit.Id;
			slt.Sample_Limit_Id_vod__c = checkLimit.Id;
			slt.Sample_Limit_Name_vod__c = checkLimit.Name;
			slt.Sample_Limit_Type_vod__c = checkLimit.Sample_Limit_Type_vod__c;
			// stamp the call sample id
			slt.Call2_Sample_Id_vod__c = cRow.Id;
			if (checkLimit.User_vod__c != null) {
				slt.User_vod__c = checkLimit.User_vod__c;
				slt.User_Id_vod__c = checkLimit.User_vod__c;
				slt.User_Name_vod__c = checkLimit.User_vod__r.Username;
			}
		}
		System.debug('slt=' + slt);
		return slt;
	}
}