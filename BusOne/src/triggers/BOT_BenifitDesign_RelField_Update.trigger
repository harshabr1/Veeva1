//Name         : BOT_BenifitDesign_RelField_Update
//Created  by  : Sreenivasulu Adipudi
//Created date : 24/02/2017
//Description  : While uploading the benefit design records, this trigger will identify the unique account,Plan demographics, Formulary and updtates unique SFDC id
trigger BOT_BenifitDesign_RelField_Update on Benefit_Design_vod__c (before insert) 
{
    BOT_BDesign_RelField_Update_Handler.m1(Trigger.new);
}