/* 
Name            : BOT_BenifitDesign_RelField_Update_Test
Created by      : Sreenivasulu Adipudi
Created Date    : 06/Mar/2017
Description     : This test class is used to test the trigger class (BOT_BDesign_RelField_Update_Handler) 
*/
@isTest(seeAllData=False)
public class BOT_BenifitDesign_RelField_Update_Test 
{
    public static testMethod void BOT_BenifitDesign_RelField_Update()
    {
        //inserting a record into account object
        Account acc = new Account();
        acc.name = 'Test Acc1';
        insert acc;
        //inserting a record into plan demographics object with account id
        Account_Plan_vod__c plan = new Account_Plan_vod__c();
        plan.name = 'Test Plan1';
        plan.Account_vod__c=acc.id;
        insert plan;
        //inserting a record into formulary object with account id and plan id
        Formulary_Products_vod__c form = new Formulary_Products_vod__c();
        form.name='form1';
        form.BOT_Account__c=plan.Account_vod__c;
        form.BOT_Account_Plan__c=plan.id;
        insert form;
        ID tempformularyID=form.Id;
        //inserting a record into Benefit design object with account id,plan id and formulary name (BOT formulary Id)
        Benefit_Design_vod__c ben = new Benefit_Design_vod__c();
        ben.name='ben1';
        ben.Account_vod__c=form.BOT_Account__c;
        ben.BOT_Product_Plan__c=form.BOT_Account_Plan__c;
        ben.BOT_Formulary_ID__c=form.name;
        insert ben;
        //Comparing the BOT formulary Id with formulary Id in Benefit disign
        System.assertEquals('form1', ben.BOT_Formulary_ID__c);
        System.assertEquals(tempformularyID, ben.BOT_Formulary__c);
        System.debug('Formulary Record ID'+tempformularyID);
        System.debug('BenefitDesign Formulary ID'+ben.BOT_Formulary__c);
    }
}