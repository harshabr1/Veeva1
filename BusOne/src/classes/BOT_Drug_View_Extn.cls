/*
Name:BOT_Drug_View_Extn
Created By :Harsha BR
Created Date:02/27/2017
Overview:Used to display the Drug data.

Modified By: Harsha BR
Modified Date: 04/04/2017
Reason: To add Pagination
*/

public class BOT_Drug_View_Extn 
{
     Public ID formularyId{get;set;}                                        //Used to store the Formulary record ID
     Public string selected{get;set;}                                       //Used to store the selected Therapeutic Class value
     Public String botFormID{get;set;}                                      //Used to store the BOT Formulary ID
     Public String botPlanProdID{get;set;}                                  //Used to store the BOT Plan Product ID
     Public String accName{get;set;}										//Used to store the Account Name
     Public Boolean blnPBMAcc{get;set;}										//True if the Account type is not PBM 	
     public set<String> setTherapeutic = new set<String>();                 //Used to store the Therapeutic Class
     Public List<Product_vod__c> lstProducts{get;set;}                      //Used to store the Drug data 
     Public List<Formulary_Products_vod__c> lstDesigns{get;set;}            //Used to store the Benefit design data
     Private static final integer list_size=10;        						//sets the page size or number of rows
     Private integer counter=0;                      						//keeps track of the offset 
     Public integer total_size{get;set;}                          			//Used to show user the total size of the list
     Private string strFilter;												//Used to store the condition to run the query
	 Private string firstThera;												//Used to store the First Therapeutic class Name 
     Private string strExeQuery;											//Used to store the query to find the number of drug records
     Public Boolean blnButtons{get;set;}
    
    //Constructor
    Public BOT_Drug_View_Extn(ApexPages.StandardController controller) 
    {
        formularyId = controller.getRecord().Id;
        strFilter='';
        fetchProducts();
    }
    

    //Used to fetch all the Events associated with the account.
    Public void fetchProducts()
    { 
        String strAccType;
        List<Product_vod__c> lstTherapeutic=new List<Product_vod__c>();		//To store the therapeutic class
        
        List<Formulary_Products_vod__c> lstForms=[SELECT ID,Name,BOT_Account__r.Account_Type__c,BOT_Account__r.Name,BOT_Account_Plan__c
                                                  FROM Formulary_Products_vod__c
                                                  WHERE ID=:formularyId
                                                  LIMIT 1];
        
        if(!lstForms.isEmpty())
        {
            if(lstForms[0].name!='')
            {
             	botFormID=lstForms[0].name;   
            }
            
            if(lstForms[0].BOT_Account__r.Account_Type__c!=null)
            {
             	strAccType=lstForms[0].BOT_Account__r.Account_Type__c;   
            } 
            if(lstForms[0].BOT_Account_Plan__c!=null)
            {
                botPlanProdID=lstForms[0].BOT_Account_Plan__c;
            }
            if(lstForms[0].BOT_Account__r.Name!=null)
            {
                accName=lstForms[0].BOT_Account__r.Name;
            }
        }
        
        if(strAccType!='PBM')
        {
        	blnPBMAcc=true; 	   
        }
        //Used to query the Benefit design data
        lstDesigns=[SELECT Id,BOT_Formulary_Name__c, (SELECT Id,Name,BOT_Channel__c,BOT_Copay__c,BOT_Status__c,BOT_Product_Type__c,BOT_Product_Plan__r.Name,BOT_Formulary__c,BOT_Formulary__r.BOT_Formulary_Name__c
                    FROM Benefit_Designs__r)
                    FROM Formulary_Products_vod__c
                    WHERE Id=:formularyId and Id in (SELECT BOT_Formulary__c from Benefit_Design_vod__c)
                    LIMIT 50000];
        
         lstTherapeutic=[SELECT Id,Therapeutic_Class_vod__c,BOT_Formulary_ID__c
                         FROM Product_vod__c
                     	 WHERE BOT_Formulary_ID__c=:botFormID
                     	 ORDER BY Therapeutic_Class_vod__c 
                     	 LIMIT 50000];
        
        for(Product_vod__c objProd:lstTherapeutic)
        {
            if(objProd.Therapeutic_Class_vod__c!='')
            {
            	setTherapeutic.add(objProd.Therapeutic_Class_vod__c);    
            }     
        }
        
        if(!setTherapeutic.isEmpty())
        {
        	firstThera= new List<String> (setTherapeutic)[0];    
        }
        
        strFilter='BOT_Formulary_ID__c=:botFormID AND Therapeutic_Class_vod__c=:firstThera AND BOT_Plan_Demographics__c=:botPlanProdID';
        
        String strCountQuery = 'Select Count() From Product_vod__c Where ' + strFilter;
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
        	strExeQuery ='SELECT Id,Name,BOT_Formulary_ID__c,Therapeutic_Class_vod__c,BOT_Status__c,Restricted_States_vod__c,BOT_Copay__c,BOT_Strength__c FROM Product_vod__c WHERE BOT_Formulary_ID__c=:botFormID AND Therapeutic_Class_vod__c =:firstThera AND BOT_Plan_Demographics__c=:botPlanProdID ORDER BY Name ';
        	fetchDrugs();    
        }
    }

    //Used to filter the drug based based on the selected therapeutic class
    Public void fetchResults()
    {
        counter=0;
		strFilter='BOT_Formulary_ID__c=:botFormID AND Therapeutic_Class_vod__c=:selected AND BOT_Plan_Demographics__c=:botPlanProdID';
        String strCountQuery = 'Select Count() From Product_vod__c Where ' + strFilter;
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
        	strExeQuery ='SELECT Id,Name,BOT_Formulary_ID__c,Therapeutic_Class_vod__c,BOT_Status__c,Restricted_States_vod__c,BOT_Copay__c,BOT_Strength__c FROM Product_vod__c WHERE BOT_Formulary_ID__c=:botFormID AND Therapeutic_Class_vod__c =:selected AND BOT_Plan_Demographics__c=:botPlanProdID ORDER BY Name';
        	fetchDrugs();    
        }	
    }
    
    //Used to query the drug data
    Public void fetchDrugs()
    {
         lstProducts= database.query(strExeQuery);  
    }
    
    //Used to store the therapeutic class values
    Public List<SelectOption> getdynamiclist()
    {
        List<SelectOption> options = new List<SelectOption>();

        for(String value : setTherapeutic)
        {
            options.add(new SelectOption(value,value));
        }
        return options;
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
        fetchDrugs();
        return null;
    }
    
    //User clicked previous button
    Public PageReference Previous()
    {
        counter -= list_size;
        fetchDrugs();
        return null;
    }
    
    //User clicked next button
    Public PageReference Next()
    {
        counter += list_size;
        fetchDrugs();
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
        fetchDrugs();
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