/*
Name			: BOT_Update_AccId_onPlanDemographics
Created by 		: Sreenivasulu Adipudi
Created date	: 05-08-2018
Description		: Updating related Account Id on Plan demographics object while doing data insert
*/
trigger BOT_Update_AccId_onPlanDemographics on Account_Plan_vod__c (before insert) 
{
    BOT_Update_AccId_onPlanDemographics.m1(Trigger.new);
}