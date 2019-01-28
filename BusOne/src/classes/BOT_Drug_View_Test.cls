/*
Name:BOT_Drug_View_Test
Created By :Harsha BR
Created Date:02/27/2017
Overview:Test class for the BOT_Drug_View_Extn. 
*/

@isTest(SeeAllData=True)
public class BOT_Drug_View_Test 
{
	private static testMethod void validateDrugDispaly()
    {
        //Inserting Plan Demography
        Account_Plan_vod__c objPlan = new Account_Plan_vod__c(Name = 'TestAccountName');
        insert objPlan;
        
        //Inserting Formulary Product
        Formulary_Products_vod__c objForm = new Formulary_Products_vod__c(Name = 'Test',BOT_Account_Plan__c=objPlan.Id);
        insert objForm;
        
        //Inserting Benefit Designs
        List<Benefit_Design_vod__c> lstDesigns=new List<Benefit_Design_vod__c>();
        Benefit_Design_vod__c objDesign=new Benefit_Design_vod__c(Name='sample Design');
        lstDesigns.add(objDesign);
        
        Benefit_Design_vod__c objDesign1=new Benefit_Design_vod__c(Name='sample Design1');
        lstDesigns.add(objDesign1);
        insert lstDesigns;
        
        //Inserting Drug level data
        List<Product_vod__c> lstDrugs =new List<Product_vod__c>();
        Product_vod__c objDrug=new Product_vod__c(Name='Xtandi',
                                                  BOT_Formulary_ID__c=objForm.Name,
                                                  Therapeutic_Class_vod__c='Overactive Bladder');
        lstDrugs.add(objDrug);
        
        Product_vod__c objDrug1=new Product_vod__c(Name='Mybritriq',
                                                   BOT_Formulary_ID__c=objForm.Name,
                                                   Therapeutic_Class_vod__c='Overactive Bladder');
        lstDrugs.add(objDrug1);
        insert lstDrugs;
        
        ApexPages.StandardController sc = new ApexPages.standardController(objForm);
        BOT_Drug_View_Extn controller = new BOT_Drug_View_Extn(sc);
        controller.fetchResults();
        controller.getdynamiclist();
    }
}