/*
Name:BOT_specialtyProvider_Test
Created By :Harsha BR
Created Date:03/07/2017
Overview:Test class for the BOT_specialtyProvider_View. 
*/

@isTest(SeeAllData=False)
public class BOT_specialtyProvider_Test 
{
	private static testMethod void validateSpecialtyDispaly()
    {
      	//Inserting account
        Account objPlan = new Account(Name = 'TestAccountName');
        insert objPlan;
        
        //Inserting Specialty Providers records
        List<BOT_Specialty_Provider__c> lstSpecialties=new List<BOT_Specialty_Provider__c>();
        
        BOT_Specialty_Provider__c objSpecialty=new BOT_Specialty_Provider__c(Name='Specialty Provider',
                                                                             BOT_Account__c=objPlan.Id);
        lstSpecialties.add(objSpecialty);
        BOT_Specialty_Provider__c objSpecialty1=new BOT_Specialty_Provider__c(Name='Specialty Provider1',
                                                                             BOT_Account__c=objPlan.Id);
        lstSpecialties.add(objSpecialty1);  
        
        insert lstSpecialties;
        
        //Inserting Thera Class records
        List<BOT_Thera_Class__c> lstTheraClass=new List<BOT_Thera_Class__c>();
        BOT_Thera_Class__c objThera=new BOT_Thera_Class__c(Name='Thera',
                                                           BOT_Specialty__c=objSpecialty.Id,
                                                           BOT_Account__c=objPlan.Id);
        lstTheraClass.add(objThera);
        
        BOT_Thera_Class__c objThera1=new BOT_Thera_Class__c(Name='Thera1',
                                                           BOT_Specialty__c=objSpecialty.Id,
                                                           BOT_Account__c=objPlan.Id);
        lstTheraClass.add(objThera1);
        insert lstTheraClass;
        
        ApexPages.StandardController sc = new ApexPages.standardController(objThera);
        BOT_Specialty_View_Extn controller = new BOT_Specialty_View_Extn(sc);
    }
}