/*
Name        	: BOT_BDesign_RelField_Update_Handler
Created by    	: Sreenivasulu Adipudi
Created Date    : 07/MAR/2017
Overview    	: It is a trigger handler class written for BOT_BDesign_RelField_Update trigger
*/
public class BOT_BDesign_RelField_Update_Handler 
{
    public static void m1(List<Benefit_Design_vod__c>beforeInsert)
    {
        set <ID> botformid = new set<ID>();                                 //To store unique BOT formulary id values.
        List <Benefit_Design_vod__c> benefit = new List<Benefit_Design_vod__c>();   //To store the Benefit design records.
        for(Benefit_Design_vod__c ben:beforeInsert)
        {
            botformid.add(ben.BOT_Formulary_ID__c);                                 
        }
        //Retrieving the Formulary product records which is related with given benefit design records
        List <Formulary_Products_vod__c> formularyid = [select id,BOT_Account__c,BOT_Account_Plan__c,name,BOT_Formulary_Lives__c from Formulary_Products_vod__c where name in:botformid];
        //Iterating the loop to gen benefit design records
        for(Benefit_Design_vod__c ben:beforeInsert)                         
        {
            //Iterating the loop to get the related Formulary product records
            for(Formulary_Products_vod__c form:formularyid)
            {
                //Identifiying the Unique fromulary id which is related to Benefit design and populating that formulary id and lives into Benefit design record
                if(ben.Account_vod__c==form.BOT_Account__c&&ben.BOT_Product_Plan__c==form.BOT_Account_Plan__c&&ben.BOT_Formulary_ID__c==form.name)
                {
                    ben.BOT_Formulary__c=form.id;
                    ben.Lives_vod__c=form.BOT_Formulary_Lives__c;
                    benefit.add(ben);
                }
            }
        }
    }
}