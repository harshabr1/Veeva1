/*
Name:BOT_Account_Test
Created By :Harsha BR
Created Date:03/10/2017
Overview:Test class for the BOT_Account_Extn and BOT_Pharmacy_View_Extn classes. 
*/
@isTest(SeeAllData=False)
Public class BOT_Account_Test
{
	private static testMethod void validateAccDispaly()
    {
     	//Inserting Account
     	List<account> lstAccs=new List<Account>();
        Account objAcc = new Account(Name = 'TestAccountName',
                                     BOT_PBM_ID__c='22',
                                     Account_Type__c='MCO');
        lstAccs.add(objAcc);
        Account objAcc1 = new Account(Name = 'TestAccountName1',
                                     BOT_Entity_Id__c='22',
                                     Account_Type__c='MCO');
        lstAccs.add(objAcc1);
        
        insert lstAccs;
        
        //Inserting Pharmacy records
        List<BOT_Pharamcy_Service__c> lstPharmacy=new List<BOT_Pharamcy_Service__c>(); 
        
        BOT_Pharamcy_Service__c objPhar=new BOT_Pharamcy_Service__c(Name='Pharmmacy',
                                                                    BOT_Account__c=objAcc.Id,
                                                                    BOT_PBM_Name__c='TestAccountName');
        lstPharmacy.add(objPhar);
        BOT_Pharamcy_Service__c objPhar1=new BOT_Pharamcy_Service__c(Name='Pharmmacy1',
                                                                     BOT_Account__c=objAcc1.Id,
                                                                     BOT_PBM_Name__c='TestAccountName');
        lstPharmacy.add(objPhar1);
        insert lstPharmacy;
        
        //To cover BOT_Account_Extn class
        ApexPages.StandardController sc = new ApexPages.standardController(objPhar);
        BOT_Account_Extn controller = new BOT_Account_Extn(sc);
        controller.getdynamiclist();
        controller.fetchResults();
        
        //To cover BOT_Pharmacy_View_Extn class
        ApexPages.StandardController sc1 = new ApexPages.standardController(objAcc);
        BOT_Pharmacy_View_Extn accCont = new BOT_Pharmacy_View_Extn(sc1);
        accCont.getdynamiclist();
        accCont.fetchResults();
        
    }
}