/*
Name			: BOT_Account_Detail_Page_extn
Created by		: Sreenivasulu Adipudi
Created date	: 05-15-2018
Description		: It is controller class of BOT_Account_Detail_Page Visualforce page
*/
public class BOT_Account_Detail_Page_extn 
{
    public set<String> channels {get;set;}			//To store unique channels for disply on picklist
    public String selectedChannel {get;set;}		//To store a channel selected by the user
    private Id accountId;							//To store current account record Id
    public List<Plan_Product__c> plans {get;set;}	//To store list of related plan demographics records
    //public Integer planPage {get;set;}				//To store current page number for plan demograhics pagination purpose
    //public Integer planPages {get;set;}				//To store total of pages for plan demograhics pagination purpose
    //public Integer planTotal {get;set;}				//To store the plan demographics records total pagination purpose
	//Integer planOffset;								//To store plan demographics records to hide
    public List<BOT_Formularies_Unique__c> formularies {get;set;}	//To store list of related formulary records
    //public Integer formularyPage {get;set;}			//To store current page number for formulary pagination purpose
    //public Integer formularyPages {get;set;}		//To store total of pages for formulary pagination purpose
    //public Integer formularyTotal {get;set;}		//To store the formulary records total pagination purpose
    //Integer formularyOffset;						//To store formulary records to hide
    public String selectedText {get;set;}			//It stores user entered text to filer plans by name
    public String selectedType {get;set;}			//It stores user entered text to filer plans by type
    public String selectedFormulary {get;set;}		//It stores user entered text to filer formulary by name
    String queryString;								//It stores query string which is used to filter plans by name or type
    
    //Constructor
    public BOT_Account_Detail_Page_extn(Apexpages.StandardController controller)
    {
        accountId = controller.getId();			//Uncomment when this page added to Account pagelayout
        //accountId = 'a423C0000001DsO';		//Comment when this page added to Account pagelayout
        channels = new set<String>();				
        
        if(accountId != Null)
        {
        	//Calling this function to get all related records of selected Account
        	initialRetrieve();
        }
        
        if(plans != Null && plans.size() > 0)
        {
            //Getting unique channels
        	for(Plan_Product__c plan : plans)
        	{
        		channels.add(plan.BOT_Account__r.BOT_Account_Type__c);	    
        	}
        }
    }
    
    //It retrieves all plan demographcis, formulary records related to selected account
    public void initialRetrieve()
    {
    	//Retrieving list of demographics records	
        plans = [select Id, name, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives__c, BOT_Product_Lives_Rx__c, 
                 BOT_Product_Type__c from Plan_Product__c where BOT_Account__c =: accountId order by Name];
        
        //Retrieving list of demographics records
        formularies = [select Id, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Name__c, BOT_Formulary_Lives__c, BOT_Formulary_Lives_Med__c 
                       from BOT_Formularies_Unique__c where BOT_Account__c =: accountId order by BOT_Formulary_Name__c];
    }
    
    //It retrieves all plan demographcis, formulary records related to selected account
    /*
    public void initialRetrieve()
    {
    	//Intially assign planPage as 1
        planPage = 1;
        //Retrieving plan demographics records count
        planTotal = [select count() from Plan_Product__c where BOT_Account__c =: accountId];
       	//Retrieving list of demographics records	
        plans = [select Id, name, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives__c, BOT_Product_Lives_Rx__c, 
                 BOT_Product_Type__c from Plan_Product__c where BOT_Account__c =: accountId order by Name];
        //Calculating total no of pages
        planPages = (Integer)Math.ceil(Decimal.valueOf(planTotal).divide(5,1));
    
        //Intially assign planPage as 1
        formularyPage = 1;
        //Retrieving plan demographics records count
        formularyTotal = [select count() from BOT_Formularies_Unique__c where BOT_Account__c =: accountId];
        //Retrieving list of demographics records
        formularies = [select Id, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Name__c, BOT_Formulary_Lives__c, BOT_Formulary_Lives_Med__c 
                       from BOT_Formularies_Unique__c where BOT_Account__c =: accountId order by BOT_Formulary_Name__c];
        //Calculating total no of pages
        formularyPages = (Integer)Math.ceil(Decimal.valueOf(formularyTotal).divide(5,1));
    }
	*/
    
    //It retrieves plan demographcis, formulary records related to selected account filtered by channel
    public void channelFilterRetrieve()
    {
    	//If the selected channel is all or blank get all records
        if(selectedChannel == '--ALL--' || selectedChannel == '')
        {
        	initialRetrieve();	
        }
        //If slected channel is something like Commercial, Medicate etc.
        else
        {
        	//Retrieving list of demographics records filtered by channel
            plans = [select Id, name, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives__c, BOT_Product_Lives_Rx__c, 
                 	BOT_Product_Type__c from Plan_Product__c where BOT_Account__c =: accountId and BOT_Account__r.BOT_Account_Type__c =: 
                    selectedChannel order by Name];
        	
            //Retrieving list of formulary records filtered by channel
            formularies = [select Id, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Name__c, BOT_Formulary_Lives__c, BOT_Formulary_Lives_Med__c 
                           from BOT_Formularies_Unique__c where BOT_Account__c =: accountId and BOT_Account__r.BOT_Account_Type__c =: selectedChannel 
                           order by BOT_Formulary_Name__c];
       	}
    }

    //It retrieves plan demographcis, formulary records related to selected account filtered by channel
    /*
    public void channelFilterRetrieve()
    {
    	//If the selected channel is all or blank get all records
        if(selectedChannel == '--ALL--' || selectedChannel == '')
        {
        	initialRetrieve();	
        }
        //If slected channel is something like Commercial, Medicate etc.
        else
        {
        	//Intially assign planPage as 1
            planPage = 1;
        	//Retrieving plan demographics records count filtered by channel
            planTotal = [select count() from Plan_Product__c where BOT_Account__c =: accountId and BOT_Account__r.BOT_Account_Type__c =: selectedChannel];
			//Retrieving list of demographics records filtered by channel
            plans = [select Id, name, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives__c, BOT_Product_Lives_Rx__c, 
                 	BOT_Product_Type__c from Plan_Product__c where BOT_Account__c =: accountId and BOT_Account__r.BOT_Account_Type__c =: 
                    selectedChannel order by Name];
        	//Calculating total no of pages
            planPages = (Integer)Math.ceil(Decimal.valueOf(planTotal).divide(5,1));    

        	//Intially assign formularyPage as 1
            formularyPage = 1;
        	//Retrieving formulary records count filtered by channel
            formularyTotal = [select count() from BOT_Formularies_Unique__c where BOT_Account__c =: accountId and BOT_Account__r.BOT_Account_Type__c =: selectedChannel];
        	//Retrieving list of formulary records filtered by channel
            formularies = [select Id, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Name__c, BOT_Formulary_Lives__c, BOT_Formulary_Lives_Med__c 
                           from BOT_Formularies_Unique__c where BOT_Account__c =: accountId and BOT_Account__r.BOT_Account_Type__c =: selectedChannel 
                           order by BOT_Formulary_Name__c];
       		//Calculating total no of pages
            formularyPages = (Integer)Math.ceil(Decimal.valueOf(formularyTotal).divide(5,1));
        }
    }
	*/
    
	//When user click on '<<' button of plan demographics section 
    /*
    public void firstPlan()
    {
    	planPage = 1;
        planOffset = (planPage - 1) * 5;
        getPlans();
    }
    
    //When user click on '<' button of plan demographics section 
    public void previousPlan()
    {
    	planPage = planPage - 1;
        planOffset = (planPage - 1) * 5;
        getPlans();
    }
    
    //When user click on '>' button of plan demographics section 
    public void nextPlan()
    {
    	planPage = planPage + 1;
        planOffset = (planPage - 1) * 5;
        getPlans();
    }
    
    //When user click on '>>' button of plan demographics section 
    public void lastPlan()
    {
    	planPage = planPages;
        planOffset = (planPage -1) * 5;
        getPlans();
    }

    //Retrieving list of plan demograpics records filtered by pagenation controlls
    public void getPlans()
    {
    	//If the selected channel is All or blank
        if(selectedChannel == '--ALL--' || selectedChannel == '')
        {
        	plans = [select Id, name, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives__c, BOT_Product_Lives_Rx__c, 
                 	BOT_Product_Type__c from Plan_Product__c where BOT_Account__c =: accountId order by name];
        }
        //If the selected channel is Commercial or Medicate or etc. 
        else
        {
        	plans = [select Id, name, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives__c, BOT_Product_Lives_Rx__c, 
                     BOT_Product_Type__c from Plan_Product__c where BOT_Account__c =: accountId and BOT_Account__r.BOT_Account_Type__c =: 
                     selectedChannel order by name];    
        }
    }
    
	//When user click on '<<' button of formulary section  
    public void firstFormulary()
    {
    	formularyPage = 1;
        formularyOffset = (formularyPage - 1) * 5;
        getFormularies();    
    }
    
    //When user click on '<' button of formulary section  
    public void previousFormulary()
    {
    	formularyPage = formularyPage - 1;
        formularyOffset = (formularyPage - 1) * 5;
        getFormularies();
    }
    
    //When user click on '>' button of formulary section  
    public void nextFormulary()
    {
    	formularyPage = formularyPage + 1;
        formularyOffset = (formularyPage - 1) * 5;
        getFormularies();
    }
    
    //When user click on '>>' button of formulary section  
    public void lastFormulary()
    {
    	formularyPage = formularyPages;
        formularyOffset = (formularyPage -1) * 5;
        getFormularies();
    }
    
    //Retrieving list of formulary records filtered by pagenation controlls
    public void getFormularies()
    {
        //If the selected channel is All or blank
        if(selectedChannel == '--ALL--' || selectedChannel == '')
        {
        	formularies = [select Id, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Name__c, BOT_Formulary_Lives__c, BOT_Formulary_Lives_Med__c 
                       		from BOT_Formularies_Unique__c where BOT_Account__c =: accountId order by BOT_Formulary_Name__c];
        }
        //If the selected channel is Commercial or Medicate or etc. 
        else
        {
        	formularies = [select Id, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Name__c, BOT_Formulary_Lives__c, BOT_Formulary_Lives_Med__c 
                           from BOT_Formularies_Unique__c where BOT_Account__c =: accountId and BOT_Account__r.BOT_Account_Type__c =: selectedChannel
                           order by BOT_Formulary_Name__c];    
        }
    }
	*/
    
    //Retrieving list of demographics records filtered by name with user selected text
    public void getPlansByName()
    {
		/*
        plans.clear();
        String nameString;
        if(selectedText == '' || selectedText.length() == 0)
        {
        	plans.addAll(backupPlans);       
        }
        else
        {
        	for(Plan_Product__c p : backupPlans)
        	{
            	nameString = p.name;
            	if(nameString.startsWith(selectedText))
            	{
                	plans.add(p);
            	}
            }
        }
		*/
        queryString = 'select Id, name, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives__c, BOT_Product_Lives_Rx__c, BOT_Product_Type__c from Plan_Product__c where BOT_Account__c =: accountId and Name like \''+selectedText+'%\' order by name';
        plans = Database.query(queryString);
    }
    
    //Retrieving list of demographics records filtered by Product type with user selected text
    public void getPlansByType()
    {
        queryString = 'select Id, name, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives__c, BOT_Product_Lives_Rx__c, BOT_Product_Type__c from Plan_Product__c where BOT_Account__c =: accountId and BOT_Product_Type__c like \''+selectedType+'%\' order by name';
        plans = Database.query(queryString);
    }
    
    //Retrieving list of formulary records filtered by name with user selected text
    public void getFormularyByName()
    {
    	queryString = 'select Id, BOT_Account__r.BOT_Account_Type__c, BOT_Formulary_Name__c, BOT_Formulary_Lives__c, BOT_Formulary_Lives_Med__c from BOT_Formularies_Unique__c where BOT_Account__c =: accountId and BOT_Formulary_Name__c like \''+selectedFormulary+'%\' order by BOT_Formulary_Name__c';
        formularies = Database.query(queryString);
    }
    
    //Creating a dynamic channels list
    public List<selectOption> getDynamicChannels()
    {
        List<selectOption> options = new List<selectOption>();
        if(channels.size()>0 && channels != null)
        {
        	options.add(new selectOption('--ALL--','--ALL--'));
            for(String c : channels)
            {
                options.add(new selectOption(c,c));
            }
        }
        return options;
    }    
}