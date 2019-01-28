@isTest(seeAllData=false)
public class BOT_Account_Detail_Page_test 
{
	public static testmethod void BOT_Account_Detail_Page()
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
        List<Plan_Product__c> plans = [select Id, BOT_Account__c from Plan_Product__c limit 1];
        System.assertEquals(acc.Id, plans[0].BOT_Account__c);
        
        BOT_Formularies_Unique__c form = new BOT_Formularies_Unique__c();
        form.Name = '30001';
        form.BOT_Formulary_Name__c = 'Test formulary 1';
        form.BOT_Entity_ID__c = '10001';
       	//form.BOT_Formulary_Lives__c = 500;
        form.BOT_Formulary_Lives_Med__c = 500;
        insert form;
        List<BOT_Formularies_Unique__c> formulary = [select Id, BOT_Account__c from BOT_Formularies_Unique__c limit 1];
        System.assertEquals(acc.Id, formulary[0].BOT_Account__c);
        
        Apexpages.StandardController controller = new Apexpages.StandardController(acc);
        BOT_Account_Detail_Page_extn accUnique = new BOT_Account_Detail_Page_extn(controller);
        accUnique.initialRetrieve();
        accUnique.channelFilterRetrieve();
        accUnique.firstPlan();
        accUnique.firstFormulary();
        accUnique.selectedChannel = '--ALL--';
        accUnique.channelFilterRetrieve();
        accUnique.selectedText = 'Test';
       	accUnique.getPlansByName();
        accUnique.selectedType = 'Test';
        accUnique.getPlansByType();
        accUnique.firstPlan();
        accUnique.firstFormulary();
        accUnique.planPage = 2;
        accUnique.previousPlan();
        accUnique.formularyPage = 2;
        accUnique.previousFormulary();
        accUnique.planPage = 0;
        accUnique.nextPlan();
        accUnique.planPages = 1;
        accUnique.lastPlan();
        accUnique.formularyPage = 0;
        accUnique.nextFormulary();
        accUnique.formularyPages = 1;
        accUnique.lastFormulary();
		List<selectOption> options = accUnique.getDynamicChannels(); 
    }
}