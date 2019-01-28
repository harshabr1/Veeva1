/*
Name			: BOT_AccountId_Update_OnFormulary
Created by 		: Sreenivasulu Adipudi
Created date	: 05-14-2018
Description		: To update the related SFDC Account Id on BOT_Account__c field of BOT Formularies Unique object
*/
trigger BOT_AccountId_Update_OnFormulary on BOT_Formularies_Unique__c (before insert) 
{
	BOT_AccountId_Update.BOT_Update_Formulary(Trigger.new);
}