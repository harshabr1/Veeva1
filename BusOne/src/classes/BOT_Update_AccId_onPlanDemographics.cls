/*
Name			: BOT_Update_AccId_onPlanDemographics
Created by 		: Sreenivasulu Adipudi
Created date	: 05-08-2018
Description		: It is a helper class for BOT_Update_AccId_onPlanDemographics tigger
*/
public class BOT_Update_AccId_onPlanDemographics 
{
    public static void m1(List<Account_Plan_vod__c> plans)
    {
        Map<String,Id> accounts = new Map<String,Id>();		//To store related Account BOT Account Ids and SFDC Account IDs
        set<String> accountIds = new set<String>();			//To store uniquee BOT Account Ids from Trigger.new
        
        //Iterating new records and getting BOT Account Ids
        for(Account_Plan_vod__c plan : plans)
        {
            accountIds.add(plan.BOT_Entity_ID__c);
            System.debug('Account IDs : '+accountIds);
        }
        
        //Getting related records from Account and iterating to store the BOT Account ID and SFDC Id into the map
        for(Account acc : [select Id, BOT_Entity_Id__c from Account where BOT_Entity_Id__c in : accountIds])
        {
            accounts.put(acc.BOT_Entity_Id__c, acc.Id);
            System.debug('Map Value : '+accounts);
        }
        
        //Iterating with Trigger.new records
        for(Account_Plan_vod__c plan : plans)
        {        
            //Identifiying where BOT Account Id of plan demographics matches with BOT Account Id of Account 
            if(accounts.containsKey(plan.BOT_Entity_ID__c))
            {
                System.debug('Updating Id : '+accounts.get(plan.BOT_Entity_ID__c));
                //Updating BOT Account Id field of plan demographics with SFDC Account ID
                plan.BOT_Account__c = accounts.get(plan.BOT_Entity_ID__c);
                System.debug('Updated Id : '+plan.BOT_Account__c);
            }
        }
    }
}