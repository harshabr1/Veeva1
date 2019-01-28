/*
Name			: BOT_Coverage_Policy_Extn
Created date	: 04-18-2018
Cteated by		: Sreenivasulu Adipudi
Description		: It is a controller class for BOT_Coverage_Policy_View
*/
public class BOT_Coverage_Policy_Extn {
    Id accId;										// To store the Account Id
    public String selectedMarket {get;set;}			// To store market value which is opted by the user
    public String selectedIndication {get;set;}		// To store indication value which is opted by the user
    public String selectedSubIndication {get;set;}	// To store sub-indication value which is opted by the user
    public String selectedDrug {get;set;}			// To srore drug value which is opted by the user
    List<BOT_Coverage_Policy__c> markets;			// To store all account related coverage policy records for market dropdown input 
    List<BOT_Coverage_Policy__c> indications;		// To store all account related coverage policy records for indications dropdown input
    List<BOT_Coverage_Policy__c> subIndications;	// To store all account related coverage policy records for sub-indications dropdown input
    List<BOT_Coverage_Policy__c> drugs;				// To store all account related coverage policy records for drug dropdown input
    public List<BOT_Coverage_Policy__c> coveragePolicy {get;set;}	// To get coverage policy details on user selection
    public Boolean renderTable {get;set;}
    public Id attachmentId {get;set;}
    //Controller
    public BOT_Coverage_Policy_Extn(Apexpages.StandardController controller)
    {
        //accId = controller.getId();
        accId = '0013C000006CgNn';					// It is for testing purpose, later we can comment it
        renderTable = false;
        
        // Getting the related coverage policy records for markets picklist display
        markets = [select Id, BOT_Market__c, BOT_Indication__c, BOT_Sub_Indication__c, BOT_Drug__c from BOT_Coverage_Policy__c 
                   where BOT_Plan_Name__c =: accId];
        indications = [select Id, BOT_Indication__c from BOT_Coverage_Policy__c where BOT_Plan_Name__c =: accId];
        subIndications = [select Id, BOT_Sub_Indication__c from BOT_Coverage_Policy__c where BOT_Plan_Name__c =: accId];
        drugs = [select Id, BOT_Drug__c from BOT_Coverage_Policy__c where BOT_Plan_Name__c =: accId];
    }
    
    public void getIndications()
    {
    	if(selectedMarket != '' || selectedMarket != '--ALL--')
        	indications = [select Id, BOT_Indication__c from BOT_Coverage_Policy__c where BOT_Plan_Name__c =: accId and BOT_Market__c =: selectedMarket];    
    }
    
    public void getSubIndications()
    {
    	if(selectedIndication != '' || selectedIndication != '--ALL--')
        	subIndications = [select Id, BOT_Sub_Indication__c from BOT_Coverage_Policy__c where BOT_Plan_Name__c =: accId and 
                      		  BOT_Market__c =: selectedMarket and BOT_Indication__c =: selectedIndication ];
        
    }
    
    public void getdrugs()
    {
        if(selectedSubIndication != '' || selectedSubIndication != '--ALL--')
            drugs = [select Id, BOT_Drug__c from BOT_Coverage_Policy__c where BOT_Plan_Name__c =: accId and BOT_Market__c =: selectedMarket 
                     and BOT_Indication__c =: selectedIndication and BOT_Sub_Indication__c =: selectedSubIndication ];
    }
    
    public void getCoveragePolicy()
    {
        coveragePolicy = new List<BOT_Coverage_Policy__c>();
        if(selectedDrug != '' || selectedDrug != '--ALL--')
            coveragePolicy = [select Id, BOT_Channel__c, BOT_Market__c, BOT_Drug__c, BOT_Origination_Date__c, BOT_Effective_Date__c, 
                              (select Id, name from Attachments) from BOT_Coverage_Policy__c where BOT_Plan_Name__c =: accId and 
                              BOT_Market__c =: selectedMarket and BOT_Indication__c =: selectedIndication and BOT_Sub_Indication__c =: 
                              selectedSubIndication and BOT_Drug__c =: selectedDrug ];
       	//List<attachment>Id = [select Id from attachment where ]
    	
        System.debug('Coverage policy : '+coveragePolicy.size());
        if(coveragePolicy.size()>0)
            renderTable = true;
    }
    
    public List<selectOption> getDynamicMarkets()
    {
    	List<selectOption> options = new List<selectOption>();
        if(markets.size() > 0 || markets != null)
        {
            options.add(new selectOption('--ALL--', '--ALL--'));
            for(BOT_Coverage_Policy__c c : markets)
            {
            	options.add(new selectOption(c.BOT_Market__c, c.BOT_Market__c));    
            }            
        }
        return options;
    }
    
    public List<selectOption> getDynamicIndications()
    {
    	List<selectOption> options = new List<selectOption>();
        if(indications.size()>0 || indications != null)
        {
            options.add(new selectOption('--ALL--', '--ALL--'));
        	for(BOT_Coverage_Policy__c i : indications)
        	{
            	options.add(new selectOption(i.BOT_Indication__c, i.BOT_Indication__c));
        	}
        }
        return options;
    }
    
    public List<selectOption> getDynamicSubIndications()
    {
    	List<selectOption> options = new List<selectOption>();
        if(subIndications.size()>0 || subIndications != null)
        {
            options.add(new selectOption('--ALL--', '--ALL--'));
            for(BOT_Coverage_Policy__c s : subIndications)
            {
            	options.add(new selectOption(s.BOT_Sub_Indication__c, s.BOT_Sub_Indication__c));  
            }            
        }
        return options;
    }
    
    public List<selectOption> getDynamicDrugs()
    {
        List<selectOption> options = new List<selectOption>();
        if(drugs.size()>0 || drugs != null)
        {
            options.add(new selectOption('--ALL--', '--ALL--'));
            for(BOT_Coverage_Policy__c d : drugs)
            {
                options.add(new selectOption(d.BOT_Drug__c, d.BOT_Drug__c));
            }
        }
        return options;
    }
}