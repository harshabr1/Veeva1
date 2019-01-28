/*
Name:BOT_Account_Extn
Created By :Harsha BR
Created Date:03/09/2017
Overview:Used to display the Accounts data. 
*/
public class BOT_Account_Extn
{
    Public List<Account> lstAccs{get;set;}				//To display all the Accounts
    Public ID pharID{get;set;}							//To store the pharmacy record ID
    Public string selected{get;set;}            		//To store the selected Account Type
    String botId;										//To store the PBM BOT Entity ID
    Public Set<String> setAcctype=new Set<String>();	//TO store the Account type
    
    //Constructor
    Public BOT_Account_Extn(ApexPages.StandardController controller) 
    {
		pharID = controller.getRecord().Id;
        fetchAccountDetails();
    }
    
    Public void fetchAccountDetails()
    {
        String firstAccType;								//To store the Account type
        List<Account> lstAccounts =new List<Account>();		//To store the Accounts
        
        //Retrieving the pharmacy Service records
     	List<BOT_Pharamcy_Service__c> lstPharmacy =[SELECT Id,BOT_Account__r.BOT_PBM_ID__c 
                                                    FROM BOT_Pharamcy_Service__c 
                                                    WHERE Id=:pharID 
                                                    LIMIT 1];
        
        if(lstPharmacy[0].BOT_Account__r.BOT_PBM_ID__c!='')
        {
        	 botId=lstPharmacy[0].BOT_Account__r.BOT_PBM_ID__c; 
        }
        
        //Retrieving all the Accounts
        lstAccounts=[Select Id,Name,Account_Type__c
                     FROM Account
                     WHERE BOT_PBM_ID__c=:botId
                     ORDER BY Account_Type__c
                     LIMIT 50000]; 
            
       for(Account objAcc:lstAccounts)
       {
           if(objAcc.Account_Type__c!='')
           {
           		setAcctype.add(objAcc.Account_Type__c);    
           }
       		
       }
            
       if(!setAcctype.isEmpty())
       {
        	firstAccType= new List<String> (setAcctype)[0];    
       }
        
       lstAccs=[SELECT Id,Name,Account_Type__c,Entity_Level__c,BOT_Street_Address__c,BOT_State__c,BOT_City__c,BOT_Zip__c
                FROM Account
                WHERE BOT_PBM_ID__c=:botId AND Account_Type__c=:firstAccType AND ID IN (SELECT BOT_Account__c from BOT_Pharamcy_Service__c WHERE Name != '')
                ORDER BY Account_Type__c
                LIMIT 50000];
    }
    
    //Used to store the therapeutic class values
    public List<SelectOption> getdynamiclist()
    {
        List<SelectOption> options = new List<SelectOption>();

        for(String value : setAcctype)
        {
            options.add(new SelectOption(value,value));
        }
        return options;
    }
   
    //Retrieving the accounts based on the selected Account Type
    Public void fetchResults()
    {
     	lstAccs=[SELECT Id,Name,Account_Type__c,Entity_Level__c,BOT_Street_Address__c,BOT_State__c,BOT_City__c,BOT_Zip__c
                 FROM Account
                 WHERE BOT_PBM_ID__c=:botId AND Account_Type__c=:selected AND ID IN (SELECT BOT_Account__c from BOT_Pharamcy_Service__c WHERE Name != '')
                 ORDER BY Account_Type__c
                 LIMIT 50000];   
    }
}