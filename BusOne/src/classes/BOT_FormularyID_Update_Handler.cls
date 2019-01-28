/*
Name    	: BOT_FormularyID_Update_Handler
Created by  : Sreenivasulu Adipudi
Created date: 21-MAR-2017
Description	: It is a helper class for BOT_FormularyID_Update_On_Product trigger
*/
public class BOT_FormularyID_Update_Handler 
{
    public static void m1(List<Product_vod__c>beforeinsert)
    {
        set<String> botformularyid = new set<String>();	//To store the products object unique formulary IDs
        //Iterating and getting the unique formulary IDs
        for(Product_vod__c prod : beforeinsert)
        {
            botformularyid.add(prod.BOT_Formulary_ID__c);
        }
        //Getting formulary records which is related to the given formulary IDs
        List<Formulary_Products_vod__c> selectedformularyid = [select ID,Name,BOT_Account__c,BOT_Account_Plan__c,BOT_Formulary_Name__c from Formulary_Products_vod__c where Name in : botformularyid];
        //Iterating Product object records
        for(Product_vod__c prod: beforeinsert)
        {
            //Iterating the formulary records
            for(Formulary_Products_vod__c formulary : selectedformularyid)
            {
                //Comparing Product records with formulary records
                if(formulary.BOT_Account__c==prod.BOT_Account__c&&formulary.BOT_Account_Plan__c==prod.BOT_Plan_Demographics__c&&formulary.Name == prod.BOT_Formulary_ID__c)
                {
                    //populating SFDC formulary ID in Formulary_Product__c field of Product object
                    prod.Formulary_Product__c = formulary.id;                                                       
                }
            }
        }
    }
}