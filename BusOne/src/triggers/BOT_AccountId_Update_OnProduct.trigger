/*
Name			: BOT_AccountId_Update_OnProduct
Created by 		: Sreenivasulu Adipudi
Created date	: 05-14-2018
Description		: To update the related SFDC Account Id on BOT_Account__c field of Plan product unique object
*/
trigger BOT_AccountId_Update_OnProduct on Plan_Product__c (before insert) 
{
	BOT_AccountId_Update.BOT_Update_Product(Trigger.new);
}