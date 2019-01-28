/*
Name:BOT_Specialty_View_Extn
Created By :Harsha BR
Created Date:03/07/2017
Overview:Used to display the specialty provider data related to a Thera class.

Modified By: Harsha BR
Modified Date: 04/24/2017
Reason: To add Pagination
*/

public class BOT_Specialty_View_Extn 
{
    Public ID theraId{get;set;}											//To store the Thera class ID											
    Public List<BOT_Specialty_Provider__c> lstSpecialties{get;set;}		//To store the list of specialty providers
    Private static final integer list_size=10;        					//sets the page size or number of rows
    Private integer counter=0;                      					//keeps track of the offset 
    Public integer total_size{get;set;}                          		//Used to show user the total size of the list
    Private string strFilter;											//Used to store the condition to run the query
    Private string strExeQuery;											//Used to store the query to find the number of drug records
    Public Set<ID> setSpecialtyIDs{get;set;}								
    Public Boolean blnButtons{get;set;}									//To store the specialty provider IDs
    
    //Constructor
    Public BOT_Specialty_View_Extn(ApexPages.StandardController controller) 
    {
        theraId = controller.getRecord().Id;
        strFilter='';
        fetchSpecialties();
    }
    
    Public void fetchSpecialties()
    {
        ID accId;											//To store the Account ID
        String strTheraName;								//To store the Thera class Name
        Set<ID> setSpecIDs=new Set<ID>();					//To store the specialty provider IDs
        setSpecialtyIDs=new Set<ID>();
        
        List<BOT_Thera_Class__c> lstTheraclass=new List<BOT_Thera_Class__c>();
        
        //Query to retrieve the thera class details
     	List<BOT_Thera_Class__c> lstThera =[SELECT Id,Name,BOT_Account__c,BOT_Thera_ID__c,BOT_Specialty__c,BOT_SPP_ID__c
                                            FROM BOT_Thera_Class__c
                                            WHERE ID=:theraId
                                            LIMIT 1];
        accId=lstThera[0].BOT_Account__c;
        strTheraName=lstThera[0].Name;
        
        //Query to retrieve all the specialty providers related to the account
        List<BOT_Specialty_Provider__c> lstSpecProviders=[SELECT Id,BOT_Account__c,BOT_Specialty_ID__c
                                                          FROM BOT_Specialty_Provider__c
                                                          WHERE BOT_Account__c=:accId
                                                          LIMIT 50000];
        
        for(BOT_Specialty_Provider__c objSpec:lstSpecProviders)
        {
			setSpecIDs.add(objSpec.Id);   
        }
		
        //Query to retrieve all the thera class reccords
        lstTheraclass=[SELECT Id,Name,BOT_Thera_ID__c,BOT_SPP_ID__c,BOT_Specialty__c
                       FROM BOT_Thera_Class__c
                       WHERE BOT_Specialty__c IN:setSpecIDs
                       LIMIT 50000];
        
        for(BOT_Thera_Class__c objThera:lstTheraclass)
        {
         	if(objThera.Name==strTheraName)
            {
             	setSpecialtyIDs.add(objThera.BOT_Specialty__c);	   
            }
        }
        
        strFilter='Id IN:setSpecialtyIDs';
        
        String strCountQuery = 'Select Count() From BOT_Specialty_Provider__c Where ' + strFilter;
        total_size = database.Countquery(strCountQuery);
        
        if(total_size>0)
        {
            if(total_size<list_size)
            {
                blnButtons=false;
            }
            else
            {
            	 blnButtons=true;
            }
        	strExeQuery ='SELECT Id,Name,BOT_PBM__c,BOT_SPP_Type__c,BOT_Phone__c,BOT_City__c,BOT_State__c,BOT_website__c FROM BOT_Specialty_Provider__c WHERE Id IN:setSpecialtyIDs ORDER BY Name LIMIT :list_size Offset: counter';
        	fetchResults();    
        }       
    }
    
    //Used to query the Specialty Providers data
    Public void fetchResults()
    {
         lstSpecialties=database.query(strExeQuery);  
    }
    
     //This will disable the previous and first buttons
    Public Boolean getDisablePrevious() 
    { 
        if (counter>0)
        {
            return false; 
        }
        else
        {
            return true;
        }
    }
    
    //This will disable the next and last buttons
    public Boolean getDisableNext() 
    { 
        if (counter + list_size < total_size) 
        {
            return false; 
        }
        else
        {
            return true;
        }
    }
    
    //User clicked First button
    Public PageReference first()
    {
        counter = 0;
        fetchResults();
        return null;
    }
    
    //User clicked previous button
    Public PageReference Previous()
    {
        counter -= list_size;
        fetchResults();
        return null;
    }
    
    //User clicked next button
    Public PageReference Next()
    {
        counter += list_size;
        fetchResults();
        return null;
    }
    
    ///User clicked end button
    Public PageReference last()
    {
        counter = total_size - math.mod(total_size, list_size);
        if(counter==total_size)
        {
            counter-=list_size;
        }
        fetchResults();
        return null;
    }
    
    Public Integer getPageNumber() 
    {
		return counter/list_size + 1;
    }

    Public Integer getTotalPages() 
    {
       if(math.mod(total_size, list_size) > 0)
       {
			return total_size/list_size + 1;
       } 
       else
       {
			return (total_size/list_size); 
       }
   }
}