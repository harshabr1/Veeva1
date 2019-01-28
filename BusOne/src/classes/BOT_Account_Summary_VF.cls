/*
Name 			: BOT_Account_Summary_VF
Created by		: Sreenivasulu Adipudi
Created Date	: 02/27/2017
Overview		: It is a controller class for BOT_Related_PlanDemographics_OnAccount VF page

Modified By		: Harsha BR
Modified Date	: 04/13/2017
Reason			: To add Pagination and Sorting functionality.

Modified by		: Sreenivasulu Adipudi
Modified Date	: 07/20/2018
Reason			: Added Scroll bars, sort functionality and CSS styles
*/
global with sharing class BOT_Account_Summary_VF 
{
    ID acctID;                                                      //Used to store the current record id    
    Public string selected{get;set;}                                //Used to store the selected channel VF page
    List<Account_Plan_vod__c> plansForChannel; 						//Used to store the related plan demograpics records for the selected account
    Public set<String> picklist = new set<String>();                //Used to store the unique channels
    Public List <Account_Plan_vod__c> listOfPlans {get;set;}        //Used to store the List account plans which is related to selected account 
    Public List<Formulary_Products_vod__c> formulary {get;set;}     //Used to store the Formulary records which is related to selected account
    Public List<BOT_Pharamcy_Service__c> Pharmacy {get;set;}        //Used to store the Pharmacy Service records which is related to selected account
    public List<BOT_Coverage_Policy__c> coveragePolicy {get;set;}	//Used to store the coverage policy records
    map<String, Formulary_Products_vod__c> fomularyMap;				//Used to store uniqueue formularies by name (Merging repeated formularies)
    Public String PlanSortDir {get;set;}							//Used to store plans sort direction asc/desc
    Public String FormularySortDir {get;set;}						//Used to store formulary sort direction asc/desc
    Public String pharmacySortDir {get;set;}						//Used to store pharmacy services sort direction asc/desc
    public String sortByField {get;set;}							//Used to store the field name of which user wish to sort 
    String queryString;												//Used to store the query string
    
    //Constructor
    public Bot_Account_Summary_VF(ApexPages.StandardController controller)
    {
        //To get current account Id
        acctID=controller.getRecord().Id;
       
        //Assigning initial sort direction as descending
        PlanSortDir = 'desc';
        FormularySortDir = 'desc';
        pharmacySortDir = 'desc';
        
        //To get all plan demographics, formulary, pharmacy services & coverage policy records related to selected account
        initialRetrieve();
        
        //Iterating plan demographics records and getting channels
        for(Account_Plan_vod__c plan : listOfPlans)
        {
            picklist.add(plan.BOT_Channel__c);
        }

    }
    
    //To get all account related records
    Public void initialRetrieve()
    {
    	//To get Plan demographic records related to selected account
        listOfPlans = [SELECT ID, Name, BOT_Channel__c, BOT_Product_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives_Rx__c, BOT_Account__c,
                       BOT_PBM__c FROM Account_Plan_vod__c WHERE BOT_Account__c =: acctID ORDER BY BOT_Channel__c ASC, 
                       BOT_Product_Lives_Rx__c DESC NULLS LAST];
        
        //To get Formulary records related to selected account
        formulary = [SELECT ID, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Total_Formulary_Lives__c, BOT_Account__c FROM Formulary_Products_vod__c 
                     WHERE BOT_Account__c =: acctID ORDER BY BOT_Channel__c ASC, BOT_Total_Formulary_Lives__c DESC NULLS LAST];
        
        //To get Pharmacy services records related to selected account
        Pharmacy = [SELECT ID,Name,BOT_Channel__c,BOT_PBM_Name__c,BOT_Corporate__c,BOT_Other_Provider_Name__c FROM 
                    BOT_Pharamcy_Service__c WHERE BOT_Account__c =: acctID ORDER BY BOT_Channel__c, Name];
        
        //To get Coverage policy records related to selected account
        coveragePolicy = [select Id, BOT_Channel__c, Name, BOT_Score__c, BOT_Indication__c, (select Id, name from Attachments limit 2) 
                          from BOT_Coverage_Policy__c where BOT_Plan_Name__c =: acctID ORDER BY Name];
        
        //To avoid duplicate formulary
        mergeFormulary();
    }
    
    //To get all account related records filtered by the selected channel
    public void Get_Accout_Summary()
    {
        //If the selected channel is All, calling initial Retrieve to get all records
        if(selected=='--All--') 
        {
            initialRetrieve();
        }
        else
        {
            //To get Plan demographic records related to selected account by the selected channel
        	listOfPlans = [SELECT ID, Name, BOT_Channel__c, BOT_Product_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives_Rx__c, 
                           BOT_PBM__c, BOT_Account__c FROM Account_Plan_vod__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected 
                           ORDER BY BOT_Channel__c ASC, BOT_Product_Lives_Rx__c DESC NULLS LAST];
        
        	//To get Formulary records related to selected account by the selected channel
        	formulary = [SELECT ID, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Total_Formulary_Lives__c, BOT_Account__c FROM 
                         Formulary_Products_vod__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected ORDER BY 
                         BOT_Channel__c ASC, BOT_Total_Formulary_Lives__c DESC NULLS LAST];
            
            //To get Pharmacy services records related to selected account by the selected channel
        	Pharmacy = [SELECT ID,Name,BOT_Channel__c,BOT_PBM_Name__c,BOT_Corporate__c,BOT_Other_Provider_Name__c FROM 
                        BOT_Pharamcy_Service__c WHERE  BOT_Account__c =: acctID and BOT_Channel__c =: selected ORDER 
                        BY BOT_Channel__c, Name];
        
        	//To get Coverage policy records related to selected account by the selected channel
        	coveragePolicy = [select Id, BOT_Channel__c, Name, BOT_Score__c, BOT_Indication__c, (select Id, name from Attachments limit 2) 
                              from BOT_Coverage_Policy__c where BOT_Plan_Name__c =: acctID and BOT_Channel__c =: selected ORDER BY Name];
            
            //To avoid duplicate formulary
        	mergeFormulary();
    	}
    }
    
    //Sort funtionality implemented for plan demographics records
    public void plansSort()
    {
        //Cheking seleted channel
        if(selected=='--All--' || selected==null) 
        {
            //Checking sort by field name, because query string value will be different for sort by lives 
            if(sortByField!='BOT_Product_Lives_Rx__c')
            {
            	queryString = 'SELECT ID, Name, BOT_Channel__c, BOT_Product_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives_Rx__c, BOT_PBM__c, BOT_Account__c FROM Account_Plan_vod__c WHERE BOT_Account__c =: acctID ORDER BY '+sortByField+' '+PlanSortDir+' NULLS LAST, BOT_Product_Lives_Rx__c DESC NULLS LAST';
            }
            else
            {
            	queryString = 'SELECT ID, Name, BOT_Channel__c, BOT_Product_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives_Rx__c, BOT_PBM__c, BOT_Account__c FROM Account_Plan_vod__c WHERE BOT_Account__c =: acctID ORDER BY BOT_Product_Lives_Rx__c '+PlanSortDir+' NULLS LAST';    
            }
		}
        
        //If the selected channel is not All or not blank
        else
        {
			if(sortByField!='BOT_Product_Lives_Rx__c')
            {
            	queryString = 'SELECT ID, Name, BOT_Channel__c, BOT_Product_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives_Rx__c, BOT_PBM__c, BOT_Account__c FROM Account_Plan_vod__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected ORDER BY '+sortByField+' '+PlanSortDir+' NULLS LAST, BOT_Product_Lives_Rx__c DESC NULLS LAST';
            }
            else
            {
            	queryString = 'SELECT ID, Name, BOT_Channel__c, BOT_Product_Type__c, BOT_Formulary_Used__c, BOT_Product_Lives_Rx__c, BOT_PBM__c, BOT_Account__c FROM Account_Plan_vod__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected ORDER BY BOT_Product_Lives_Rx__c '+PlanSortDir+' NULLS LAST';    
            }
        }
        
        //Query execution
        listOfPlans = database.query(queryString);
        
        //Change sort direction to change the image
        if(PlanSortDir == 'asc')
            PlanSortDir = 'desc';
        else
            PlanSortDir = 'asc';
    }
    
    public void formularySort()
    {
    	//Cheking seleted channel
        if(selected=='--All--' || selected==null || selected=='') 
        {
            //Checking sort by field name, because query string value will be different for sort by lives 
            if(sortByField!='BOT_Formulary_Lives__c')
            {
            	queryString = 'SELECT ID, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Total_Formulary_Lives__c, BOT_Account__c FROM Formulary_Products_vod__c WHERE BOT_Account__c =: acctID ORDER BY '+sortByField+' '+FormularySortDir+' NULLS FIRST, BOT_Total_Formulary_Lives__c DESC NULLS LAST';
            }
            else
            {
            	queryString = 'SELECT ID, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Total_Formulary_Lives__c, BOT_Account__c FROM Formulary_Products_vod__c WHERE BOT_Account__c =: acctID ORDER BY BOT_Total_Formulary_Lives__c '+FormularySortDir+' NULLS FIRST';    
            }
            
        }
        //If the selected channel is not All or not blank
        else
        {
            if(sortByField!='BOT_Formulary_Lives__c')
            {
            	queryString = 'SELECT ID, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Total_Formulary_Lives__c, BOT_Account__c FROM Formulary_Products_vod__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected ORDER BY '+sortByField+' '+FormularySortDir+' NULLS FIRST, BOT_Total_Formulary_Lives__c DESC NULLS LAST';
            }
            else
            {
            	queryString = 'SELECT ID, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Total_Formulary_Lives__c, BOT_Account__c FROM Formulary_Products_vod__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected ORDER BY BOT_Total_Formulary_Lives__c '+FormularySortDir+' NULLS FIRST';    
            }
       	}
        //Query execution
        formulary = database.query(queryString);
        
        //Change sort direction to change the image
        if(FormularySortDir == 'asc')
            FormularySortDir = 'desc';
        else
            FormularySortDir = 'asc';
        
        //To avoid duplicate formulary
        mergeFormulary();
    }
    
    public void pharmacySort()
    {
        //Cheking seleted channel
        if(selected=='--All--' || selected==null || selected=='') 
        {
            queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_PBM_Name__c,BOT_Corporate__c,BOT_Other_Provider_Name__c FROM BOT_Pharamcy_Service__c WHERE BOT_Account__c =: acctID ORDER BY '+sortByField+' '+pharmacySortDir+' NULLS LAST';
        }
        //If the selected channel is not All or not blank
        else
        {
            queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_PBM_Name__c,BOT_Corporate__c,BOT_Other_Provider_Name__c FROM BOT_Pharamcy_Service__c WHERE BOT_Account__c =: acctID ORDER BY '+sortByField+' '+pharmacySortDir+' NULLS LAST';
        }
        //Query execution
        Pharmacy = database.query(queryString);
        
        //Change sort direction to change the image
        if(pharmacySortDir == 'asc')
            pharmacySortDir = 'desc';
        else
            pharmacySortDir = 'asc';
    }
    
    //Avoiding repeated formulary records by formulary name
    public void mergeFormulary()
    {
        fomularyMap = new map<String, Formulary_Products_vod__c>();
        for(Formulary_Products_vod__c form : formulary)
        {
            fomularyMap.put(form.BOT_Formulary_Name__c, form);
        }
        formulary.clear();
        formulary.addAll(fomularyMap.values());
	}
    
    //To create channel picklist dynamically
    public List<selectOption> getDynamicList() 
    {
        List<selectOption> options = new List<selectOption>();
        if(picklist.size()>1)
        {
            options.add(new selectOption('--All--','--All--'));
        }
        for(String s : picklist)
        {
            //  Adding the channels to picklist for the purpose of display on VF Page
            options.add(new selectOption(s,s));
        }
        return options;
    }
    
    @RemoteAction
    global static void changeRTToFormularyProduct(String planProduct,String accID) {

        List<Formulary_Products_vod__c> lstFormularyToBeUpdated=new List<Formulary_Products_vod__c>();
        
        for(Formulary_Products_vod__c objForm:[SELECT Id,RecordtypeId,BOT_Account__c,BOT_Account_Plan__c FROM Formulary_Products_vod__c WHERE BOT_Account__c=:accID AND  BOT_Account_Plan__c=:planProduct LIMIT 50000])
        {
            if(objForm.RecordtypeId!=Label.BOT_Formulary_Product)
            {
                objForm.RecordtypeId=Label.BOT_Formulary_Product;
         		lstFormularyToBeUpdated.add(objForm);
            }
        }
        system.debug('***lstFormularyToBeUpdated***'+lstFormularyToBeUpdated.size());
        try
        {
         	if(!lstFormularyToBeUpdated.isEmpty())
        	{
        		Update lstFormularyToBeUpdated;   
        	}   
        }
        Catch(Exception e)
        {
         	System.debug('Exception '+e.getMessage()+' found in Class- BOT_Account_Summary_VF,method - changeRTToFormularyProduct at Line number '+e.getLineNumber());   
        }	
    }
    
    @RemoteAction
    global static void changeRTToFormularyMainScreen(String formId,String accID)
    {
        Formulary_Products_vod__c objForm=[SELECT Id,RecordtypeId,Recordtype.Name,BOT_Account__c,BOT_Account_Plan__c FROM Formulary_Products_vod__c WHERE BOT_Account__c=:accID AND Id=:formId LIMIT 1];
        system.debug('***objForm***'+objForm);    
		 if(objForm.RecordtypeId!=Label.BOT_Formulary_Main_Screen)
         {
         	objForm.RecordtypeId=Label.BOT_Formulary_Main_Screen;
 		 }    

        try
        {
        	if(objForm!=null)
        	{
                system.debug('***INside Update***');
        		Update objForm;   
        	}    
        }
        Catch(Exception e)
        {
         	System.debug('Exception '+e.getMessage()+' found in Class- BOT_Account_Summary_VF,method - changeRTToFormularyMainScreen at Line number '+e.getLineNumber());   
        }  
    }
}