/*
Name            : BOT_Update_ProductId_and_FormularyId
Created by      : Sreenivasulu Adipudi
Created date    : 05-14-2018
Description     : To update the SFDC Product Id and SFDC Formulary Id on Prodcut formulary junction object
*/
trigger BOT_Update_ProductId_and_FormularyId on Plan_Formulary_JO__c (before insert) 
{
    BOT_AccountId_Update.BOT_Update_Product_and_Formulary(Trigger.new);
}