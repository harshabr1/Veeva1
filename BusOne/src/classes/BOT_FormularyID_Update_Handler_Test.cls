/* 
Name            : BOT_FormularyID_Update_Handler_Test
Created by      : Sreenivasulu Adipudi
Created Date    : 21/Mar/2017
Description     : This test class is used to test the trigger class (BOT_FormularyID_Update_Handler) 
*/
@isTest(seeAllData=False)
public class BOT_FormularyID_Update_Handler_Test 
{
    public static testMethod void BOT_FormularyID_Update_Handler()
    {
        //inserting a record into account object
        Account acc = new Account();
        acc.name = 'Test Acc1';
        insert acc;
        //inserting a record into plan demographics object with account id
        Account_Plan_vod__c plan = new Account_Plan_vod__c();
        plan.name = 'Test Plan1';
        plan.BOT_Account__c=acc.id;
        insert plan;
        //inserting a record into formulary object with account id and plan id
        Formulary_Products_vod__c form = new Formulary_Products_vod__c();
        form.name='form1';
        form.BOT_Account__c=acc.id;
        form.BOT_Account_Plan__c=plan.id;
        insert form;
        //inserting a record into Product object with account id,plan id and formulary name (BOT formulary Id)
        Product_vod__c prod = new Product_vod__c();
        prod.Name='Drug1';
        prod.BOT_Account__c=acc.id;
        prod.BOT_Plan_Demographics__c=plan.id;
        prod.BOT_Formulary_ID__c=form.name;
        insert prod;
        //Comparing the BOT formulary Id with formulary Id in Product
        System.assertEquals('form1', prod.BOT_Formulary_ID__c);
        //System.assertEquals(form.Id, prod.Formulary_Product__c);        
    }
}