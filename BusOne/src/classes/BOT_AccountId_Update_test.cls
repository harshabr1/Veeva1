@isTest(seeAllData=false)
public class BOT_AccountId_Update_test 
{
	public static testmethod void BOT_AccountId_Update()
    {
        Account_Unique__c acc = new Account_Unique__c();
        acc.name = 'Test acc 1';
        acc.BOT_Entity_ID__c = '10001';
        acc.BOT_Account_Type__c = 'Commercial';
        acc.BOT_Entity_Level__c = 'Test level 1';
        acc.BOT_Entity_State__c = 'CA';
        insert acc;
        
        Plan_Product__c plan = new Plan_Product__c();
        plan.Name = 'Test plan 1';
        plan.BOT_Entity_ID__c = '10001';
        plan.BOT_Plan_Product_ID__c = '20001';
        plan.BOT_Product_Lives__c = 500;
        plan.BOT_Product_Lives_Rx__c = 500;
		insert plan;
        
        BOT_Formularies_Unique__c form = new BOT_Formularies_Unique__c();
        form.Name = '30001';
        form.BOT_Formulary_Name__c = 'Test formulary 1';
        form.BOT_Entity_ID__c = '10001';
       	//form.BOT_Formulary_Lives__c = 500;
        form.BOT_Formulary_Lives_Med__c = 500;
        insert form;
        
        Plan_Formulary_JO__c planform = new Plan_Formulary_JO__c();
        planform.Name = '30001';
        planform.BOT_Plan_Demographics_ID__c = '20001';
        insert planform;
    }
}