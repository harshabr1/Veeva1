/* 
Name            : BOT_SPPID_In_TheraClass_Update_Test
Created by      : Sreenivasulu Adipudi
Created Date    : 06/Mar/2017
Description     : This test class is used to test the VF Page controller class (BOT_SPPID_In_Theraclass_Update_Handler) 
*/
@isTest(seeAllData=False)
public class BOT_SPPID_In_TheraClass_Update_Test 
{
    public static TestMethod void BOT_SPPID_In_TheraClass()
    {
        //inserting a record into account object
        Account acc = new Account();
        acc.name = 'Test Acc1';
        insert acc;
        //inserting a record into speciality provider object with account id
        BOT_Specialty_Provider__c spp = new BOT_Specialty_Provider__c();
        spp.BOT_Account__c=acc.id;
        spp.BOT_Specialty_ID__c='test1';
        insert spp;
        //inserting a record into Thera class object with account id and BOT speciality ID
        BOT_Thera_Class__c thera = new BOT_Thera_Class__c();
        thera.BOT_Account__c=acc.id;
        thera.BOT_SPP_ID__c=spp.BOT_Specialty_ID__c;
        thera.name='Test TheraName1';
        insert thera;
        //comparing the BOT speciality id with bot_spp_id in thera class
        System.assertEquals('test1', thera.BOT_SPP_ID__c);
    }

}