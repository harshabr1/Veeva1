/*
Name			: BOT_AccountId_Update
Cteated by		: Sreenivasulu Adipudi
Created date	: 05-14-2018
Description		: It is a helper class for BOT_AccountId_Update_OnProduct, BOT_AccountId_Update_OnFormulary and BOT_Update_ProductId_and_FormularyId Triggers
*/
public class BOT_AccountId_Update 
{
	//To handle the BOT_AccountId_Update_OnProduct trigger
    public static void BOT_Update_Product(List<Plan_Product__c> plans) 
    {
        set<String> AccountIds = new set<String>();             //To store the unique BOT Account IDs
        Map<String,Id> Accounts = new Map<String,Id>();         //To store retrived Account BOT Ids and SFDC Ids
        
        //Iterating through Trigger.new records and getting all Entity Ids into a set
        for(Plan_Product__c plan : plans)
        {
            AccountIds.add(plan.BOT_Entity_ID__c);            
        }
        
        //Iterating Account Qunique records and getting records into the Map
        for(Account_Unique__c acc : [select Id, BOT_Entity_ID__c from Account_Unique__c where BOT_Entity_ID__c in : AccountIds])
        {
            Accounts.put(acc.BOT_Entity_ID__c, acc.Id);
        }
        
        //Iterating Trigger.new records
        for(Plan_Product__c plan : plans)
        {
            //Comparing the BOT Entity ID value of Accounts Unique object with BOT Entity ID value of Plan demographics unique object
            if(Accounts.containsKey(plan.BOT_Entity_ID__c))
            {
                //Assigning the related SFDC Account ID to BOT_Account field of Plan demographics unique object
                plan.BOT_Account__c = Accounts.get(plan.BOT_Entity_ID__c);
            }
        }
    }
    
    //To hanlde the BOT_AccountId_Update_OnFormulary trigger
    public static void BOT_Update_Formulary(List<BOT_Formularies_Unique__c> form)
    {
    	set<String> AccountIds = new set<String>();             //To store the unique BOT Account IDs
        Map<String,Id> Accounts = new Map<String,Id>();         //To store retrived Account BOT IDs and SFDC Ids
        
        //Iterating through Trigger.new records and getting all Entity Ids into a set
        for(BOT_Formularies_Unique__c f : form)
        {
            AccountIds.add(f.BOT_Entity_ID__c);            
        }
        
        //Iterating Account Qunique records and getting records into the Map
        for(Account_Unique__c acc : [select Id, BOT_Entity_ID__c from Account_Unique__c where BOT_Entity_ID__c in : AccountIds])
        {
            Accounts.put(acc.BOT_Entity_ID__c, acc.Id);
        }
        
        //Iterating Trigger.new records
        for(BOT_Formularies_Unique__c f : form)
        {
            //Comparing the BOT Entity ID value of Accounts Unique object with BOT Entity ID value of Formulary unique object
            if(Accounts.containsKey(f.BOT_Entity_ID__c))
            {
                //Assigning the related SFDC Account ID to BOT_Account field of Formulary unique object
                f.BOT_Account__c = Accounts.get(f.BOT_Entity_ID__c);
            }
        }    
    }
    
    //To hanle the BOT_Update_ProductId_and_FormularyId trigger
    public static void BOT_Update_Product_and_Formulary(List<Plan_Formulary_JO__c> Ids)
    {
    	set<String> productIds = new set<String>();				//To store BOT unique product Ids
        set<String> formularyIds = new set<String>();			//To store BOT unique formulary Ids		
        map<String,Id> products = new map<String,Id>();			//To store retrieved products BOT Ids and SFDC Ids
        map<String,Id> formularies = new map<String,Id>();		//To store retrieved formulary BOT Ids and SFDC Ids
        
        //Iterating Trigger.new and getting BOT product Ids and BOT formulary Ids
        for(Plan_Formulary_JO__c i : ids)
        {
        	productIds.add(i.BOT_Plan_Demographics_ID__c);
            formularyIds.add(i.name);
        }
        
        //Iterating Product unique records and getting records into the map
        for(Plan_Product__c plan : [select Id, BOT_Plan_Product_ID__c from Plan_Product__c where BOT_Plan_Product_ID__c in : productIds])
        {
        	products.put(plan.BOT_Plan_Product_ID__c, plan.Id);            
        }
        
        //Iterating Formulary unique records and getting records into the map
        for(BOT_Formularies_Unique__c form: [select Id, name from BOT_Formularies_Unique__c where name in : formularyIds])
        {
            formularies.put(form.name, form.Id);
        }
        
        //Iterating trigger.new
        for(Plan_Formulary_JO__c i : ids)
        {
        	//Comparing the BOT Product ID value of Product Unique object with BOT Product ID value of Plan formulary Junction object
            if(products.containsKey(i.BOT_Plan_Demographics_ID__c))
            {
                //Assigning the related SFDC Product ID to BOT_Plan_Demographics_Unique__c field of Plan Formulary object
                i.BOT_Plan_Demographics_Unique__c = products.get(i.BOT_Plan_Demographics_ID__c);
            }
            //Comparing the BOT Formulary ID value of Formulary Unique object with BOT Formulary ID value of Plan formulary Junction object
            if(formularies.containsKey(i.Name))
            {
                //Assigning the related SFDC formulary ID to Formularies_Unique__c field of Plan Formulary object
                i.Formularies_Unique__c = formularies.get(i.Name);
            }
        }
    }
}