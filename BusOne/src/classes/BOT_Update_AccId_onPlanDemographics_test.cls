@isTest(seeAllData=false)
public class BOT_Update_AccId_onPlanDemographics_test {
	public static TestMethod void BOT_Update_AccId_onPlanDemographics()
    {
        //Creating Account record
        Account acc = new Account();
        acc.name = 'Test Account1';
        acc.BOT_Entity_Id__c = '1001';
        insert acc;
        //Creating Plan Demographics record
       	Account_Plan_vod__c plan = new Account_Plan_vod__c();
        plan.name = 'Test Plan1';
        plan.BOT_Entity_Id__c = '1001';
        insert plan;
        //System.assertEquals(plan.BOT_Account__c, acc.Id);
    }
}