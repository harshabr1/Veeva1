//Name         : BOT_SPPID_In_Theraclass_Update
//Created  by  : Sreenivasulu Adipudi
//Created date : 20/02/2017
//Description  : While uploading the benefit design records, this trigger will identify the unique account,Plan demographics, Formulary and updtates unique SFDC id
trigger BOT_SPPID_In_Theraclass_Update on BOT_Thera_Class__c (before insert) 
{
	BOT_SPPID_In_Theraclass_Update_Handler.m1(Trigger.new);
}