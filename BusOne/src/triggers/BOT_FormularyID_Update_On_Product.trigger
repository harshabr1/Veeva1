/*
Name    : BOT_FormularyID_Update_On_Product
Created by  : Sreenivasulu Adipudi
Created date    : 20-MAR-2017
Description : To populate related Formulary id on Drug level record by comparing the account id,Plan demographics id and BOT formulary Id
*/
trigger BOT_FormularyID_Update_On_Product on Product_vod__c (before insert) 
{
    BOT_FormularyID_Update_Handler.m1(Trigger.new);
}