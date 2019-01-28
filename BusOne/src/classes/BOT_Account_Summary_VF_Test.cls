/* 
Name			: BOT_Account_Summary_VF_Test
Created by		: Sreenivasulu Adipudi
Created Date	: 02/27/2017
Description		: This test class is used to test the VF Page controller class (BOT_Account_Summary_VF") 
*/
@isTest(seeAllData=false)
public class BOT_Account_Summary_VF_Test 
{
    public static testMethod void BOT_Account_Summary_Method()
    {
        Integer i;
        //inserting a record into account object
        Account acc = new Account(name='TestAccount1', BOT_Entity_Id__c = '1001');
        insert acc;
        
        //inserting a record into plan demographics object with account id
        Account_Plan_vod__c plan = new Account_Plan_vod__c(); 
        plan.BOT_Account__c = acc.id;
        plan.Name = 'Test Plan1';
        plan.BOT_Plan_ID__c = '2002';
        plan.BOT_Channel__c = 'Commercial';
        plan.BOT_Formulary_Used__c = 'Test Formulary used';
        plan.BOT_Product_Lives_Rx__c = 100;
        plan.BOT_PBM__c = 'Test PBM';
        insert plan;
        
        //inserting a record into plan formulary object with account id and plan demographics id
       	Formulary_Products_vod__c form = new Formulary_Products_vod__c();
        form.name = 'Test Formulary 1';
		form.BOT_Account__c = acc.id;
        form.BOT_Account_Plan__c = plan.id;
        form.BOT_Formulary_ID__c = '3003';
        insert form;
        
        //inserting a record into pharmacy service object with account id
        BOT_Pharamcy_Service__c pharm = new BOT_Pharamcy_Service__c();
        pharm.name = 'Test Pharm 1';
        pharm.BOT_Service_ID__c = '4004';
        pharm.BOT_Channel__c = 'Commercial';
        pharm.BOT_Account__c = acc.id;
        insert pharm;
        
        //inserting a record into coverage policy object with account id
        for(i = 1; i <= 10; i++)
        {
        	BOT_Coverage_Policy__c policy = new BOT_Coverage_Policy__c();
        	policy.name = 'Test policy '+ i;
        	policy.BOT_Channel__c = 'Commercial';
        	policy.BOT_Plan_Name__c = acc.id;
        	insert policy;
        }
        
        apexpages.StandardController controller = new apexpages.StandardController(acc);
        BOT_Account_Summary_VF ac = new BOT_Account_Summary_VF(controller);
        
        ac.initialRetrieve();
        ac.Get_Accout_Summary();
        ac.selected = '--All--';
        ac.firstPolicy();
        //ac.lastPolicy();
        //ac.previousPolicy();
        //ac.nextPolicy();
        ac.firstPlan();
        //ac.lastPlan();
        //ac.PreviousPlan();
        //ac.NextPlan();
        ac.firstForm();
        //ac.lastForm();
        //ac.NextForm();
        //ac.lastForm();
        ac.firstPhar();
        //ac.lastPhar();
        //ac.PreviousPhar();
        //ac.NextPhar();
        ac.selected = 'Commercial';
        ac.firstPolicy();
        
        // OpportunityOptions.add(new SelectOption(record.Id,record.Name))
        List<selectOption> op = new List<selectOption>();
        op.add(new selectOption('--None--','--None--'));
    }
}