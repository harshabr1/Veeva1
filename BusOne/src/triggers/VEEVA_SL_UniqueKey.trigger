/********************************************************************************
Sample Limit Product Template cannot have date overlaps for a same product
********************************************************************************/
trigger VEEVA_SL_UniqueKey on Sample_Limit_vod__c (before insert, before update)
{
	if (CallSampleManagement.inSampleManagement) {
		return;
	}

	Set<String> Acctypes = new set<string>(); //Load here the Account Types from the trigger batch
	Set<ID> ProductIDs = new set<ID>();

	String SLTerrMsg =
			System.Label.SLT_FieldChangedErrMsg; //used in case user wants to change  an existing  and Used Template
	if (SLTerrMsg == NULL)
		SLTerrMsg = 'Field {0} has changed ';

	String SLT_overlapE = System.Label.SLT_OverlapExisting;
	if (SLT_overlapE == NULL)
		SLT_overlapE = ' overlapping with existing {0}';

	String SLT_overlapI = System.Label.SLT_OverlapInside;
	if (SLT_overlapI == NULL)
		SLT_overlapI = 'Item {0} overlapping inside batch file with item {1}';

//check first if in case of Update they are not trying  to change an existing USED template
	for (Integer i = 0; i < Trigger.new.size(); i++)
		{
			if (trigger.new[i].Account_vod__c != NULL || trigger.new[i].Account_Types_vod__c == NULL)
				continue;

			Acctypes.add(trigger.new[i].Account_Types_vod__c);
			ProductIDs.add(trigger.new[i].Product_vod__c);

			if (trigger.isUpdate && trigger.old[i].Template_In_Use_vod__c == true)
			{
				String errorMsg = VEEVA_CSL.IsTemplateChanging(trigger.old[i], trigger.new[i], SLTerrMsg);
				if (errorMsg.length() > 0)
				{
					trigger.new[i].adderror(errorMsg);
					continue;
				}
			}
		}


	List<String> tempProdIds = new List<String>();
	for (Id i_x : ProductIDs) {
		tempProdIds.add('__' + i_x + '____Template_vod__');
	}

//compare the trigger with itslef  and with the existing                                              
/*********************************************************************************************/
	List<Sample_Limit_vod__c> ExistingSLTs = [select Id,Account_Types_vod__c,
			Product_vod__c,Product_vod__r.Name,
			Template_Group_vod__c,
			Limit_Per_Call_vod__c,
			Limit_Quantity_vod__c,
			Limit_Amount_vod__c,
			Start_Date_vod__c, End_Date_vod__c
			from Sample_Limit_vod__c
			where
	Account_Types_vod__c in :Acctypes
	and
	Product_vod__c in :ProductIDs
	and Group_Id_vod__c in :tempProdIds
	order by createddate desc
	];

	system.Debug('NEW TEMPLATE SIZE = ' + trigger.new.size() + ' EXISTING TEMPLATE SIZE = ' + ExistingSLTs.size());
	for (Integer i = 0; i < Trigger.new.size(); i++)
		{

			if (trigger.new[i].Account_vod__c != NULL || trigger.new[i].Account_Types_vod__c == NULL)
				continue;

			// modify the new key to support amount, quantity templates
			Boolean amountBased = false;
			Boolean bothAmtQty = false;
			if (Trigger.new[i].Limit_Quantity_vod__c != null && Trigger.new[i].Limit_Amount_vod__c != null) {
				bothAmtQty = true;
			} else if (Trigger.new[i].Limit_Amount_vod__c != null) {
				amountBased = true;
			}

			String theNewKey = Trigger.new[i].Product_vod__c +
					Trigger.new[i].Account_Types_vod__c +
					Trigger.new[i].Template_Group_vod__c +
					Trigger.new[i].Limit_Per_Call_vod__c;

			system.Debug('before changing the value the new key value is ' + theNewKey);

			if (bothAmtQty) {
				theNewKey = theNewKey + 'BOTH_AMT_QTY';
			} else if (amountBased) {
				theNewKey = theNewKey + 'AMT';
			} else {
				// this is just a quantity based sample limit template
				theNewKey = theNewKey + 'QTY';
			}

			system.Debug('after changing the value the new key value is ' + theNewKey);

			system.Debug('CHECKING INSIDE FILE START');
			for (Integer j = i + 1; j < Trigger.new.size(); j++)
				{

					// check for the template amount and quantity values
					Boolean amountBasedInner = false;
					Boolean bothAmtQtyInner = false;
					if (Trigger.new[j].Limit_Quantity_vod__c != null && Trigger.new[j].Limit_Amount_vod__c != null) {
						bothAmtQtyInner = true;
					} else if (Trigger.new[j].Limit_Amount_vod__c != null) {
						amountBasedInner = true;
					}

					String theInnerKey = Trigger.new[j].Product_vod__c +
							Trigger.new[j].Account_Types_vod__c +
							Trigger.new[j].Template_Group_vod__c +
							Trigger.new[j].Limit_Per_Call_vod__c;

					if (bothAmtQtyInner) {
						theInnerKey = theInnerKey + 'BOTH_AMT_QTY';
					} else if (amountBasedInner) {
						theInnerKey = theInnerKey + 'AMT';
					} else {
						// this is just a quantity based sample limit template
						theInnerKey = theInnerKey + 'QTY';
					}

					system.Debug('compare the values of both the keys new key is ' + theNewKey + ' the inner key is ' +
							theInnerKey);

					if (theNewKey != theInnerKey)
						continue;

					System.debug('just before calling the isOverLapping function ');
					if (VEEVA_CSL.IsOverlapping(trigger.new[i], trigger.new[j]) == true) {
						System.debug('Overlapping in file!');
						trigger.new[i].adderror(
								String.Format(SLT_overlapI, new string[]{String.valueOf(i), String.Valueof(j)}));
						break;
					}
				}
			system.Debug('CHECKING INSIDE FILE END');


			for (Integer k = 0; k < ExistingSLTs.size(); k++)
				{
					// adding suport for amount and quantity
					Boolean amountBasedExisting = false;
					Boolean bothAmtQtyExisting = false;
					if (ExistingSLTs[k].Limit_Quantity_vod__c != null && ExistingSLTs[k].Limit_Amount_vod__c != null) {
						bothAmtQtyExisting = true;
					} else if (ExistingSLTs[k].Limit_Amount_vod__c != null) {
						amountBasedExisting = true;
					}

					System.debug('COMPARE NEW item: ' + i + ' WITH EXISTING item: ' + k);
					String theExistingKey = ExistingSLTs[k].Product_vod__c +
							ExistingSLTs[k].Account_Types_vod__c +
							ExistingSLTs[k].Template_Group_vod__c +
							ExistingSLTs[k].Limit_Per_Call_vod__c;

					if (bothAmtQtyExisting) {
						theExistingKey = theExistingKey + 'BOTH_AMT_QTY';
					} else if (amountBasedExisting) {
						theExistingKey = theExistingKey + 'AMT';
					} else {
						// this is just a quantity based sample limit template
						theExistingKey = theExistingKey + 'QTY';
					}

					if (theNewKey != theExistingKey)
						continue;

					system.Debug('compare the values of both the keys new key is ' + theNewKey +
							' the exisitng key is ' + theExistingKey);
					system.debug('I = ' + i + '  K = ' + k);
					if (VEEVA_CSL.IsOverlapping(trigger.new[i], ExistingSLTs[k]) == true)
					{
						System.debug('Overlapping with Exisitng!');
						//trigger.new[i].adderror(SLT_overlapE + ' ' + ExistingSLTs[k].id);
						trigger.new[i].adderror(
								String.Format(SLT_overlapE, new string[]{String.Valueof(ExistingSLTs[k].id)}));
						break;
					}
				}

		}


/*********************************************************************************************/

}