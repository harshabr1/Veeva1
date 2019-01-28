/*
Name        : BOT_RelFormulary_On_Account_VF
Created by    : Sreenivasulu Adipudi
Created Date    : 08/MAR/2017
Overview    : It is a controller class for BOT_RelFormulary_On_Account VF Page
*/
public with sharing class BOT_RelFormulary_On_Account_VF 
{
    public Account accountId {get;set;}
    Public set<String> channel=new set<String>();
    public List<Formulary_Products_vod__c> allchannel = new List<Formulary_Products_vod__c>();
    Public List<Formulary_Products_vod__c> allformulary {get;set;}
    public List<Formulary_Products_vod__c> selectedformulary = new List<Formulary_Products_vod__c>();
    public BOT_RelFormulary_On_Account_VF(Apexpages.StandardController controller)
    {
        this.accountId=(Account)controller.getRecord();
        allchannel = [select ID,BOT_Account__c,BOT_Channel__c from Formulary_Products_vod__c where BOT_Account__c =: accountId.id];
        for(Formulary_Products_vod__c form:allchannel)
        {
            channel.add(form.BOT_Channel__c);
        }
        allformulary=[select ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Account_Plan__c,BOT_Formulary_Name__c,BOT_Formulary_Lives__c from Formulary_Products_vod__c where BOT_Channel__c =: channel and BOT_Account__c =: accountId.id];
     }
    
}