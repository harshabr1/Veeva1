/*
Name:BOT_Pharmacy_View_Extn
Created By :Harsha BR
Created Date:03/08/2017
Overview:Used to display the Pharmacy Services data.

Modified By: Harsha BR
Modified Date: 04/07/2017
Reason: To add Pagination 
*/

public class BOT_Pharmacy_View_Extn
{
    Public ID accId{get;set;}                                       //To store the Account Id
    Public string selected{get;set;}                                //To store the selected Pharmacy Name
    Public string selChannel{get;set;}                              //To store the selected channel
    Public String firstPhar{get;set;}                               //To store the first Pharmacy Name
    Public String strPBMId;                                         //To store the BOT PBM Id
    Public Boolean firstChange;                                     //Becomes true on change of the channel for the first time
    Public List<BOT_Pharamcy_Service__c> lstPharmacies{get;set;}    //To store all the pharmacies display on the VF Page
    Public List<BOT_Pharamcy_Service__c> lstPhar{get;set;}          //To store the Pharmacy Services
    Public Set<String> setPharmacy=new Set<String>();               //To store the Pharmacy Names
    Public Set<String> setChannels=new Set<String>();               //To store the Channel Name
    Private static final integer list_size=10;                      //sets the page size or number of rows
    Private integer counter=0;                                      //keeps track of the offset 
    Public integer total_size{get;set;}                             //Used to show user the total size of the list
    Private string strFilter;                                       //Used to store the condition to run the query
    Private string strExeQuery;                                     //Used to store the query to find the number of drug records
    Private String channel;                                         //Used to store the Channel name
    Private String strCountQuery;                                   //Used for counting the number of records
    Public Boolean blnButtons{get;set;}                             //Used to display the pagination buttons
     
    //Constructor
    Public BOT_Pharmacy_View_Extn(ApexPages.StandardController controller) 
    {
        accId = controller.getRecord().Id;
        strFilter='';
        fetchPharmacyDetails();
    }
    
    //Used to fetch the Pharmacy Service details
    Public void fetchPharmacyDetails()
    {
        try
        {   
            List<BOT_Pharamcy_Service__c> lstTempPhar=new List<BOT_Pharamcy_Service__c>();  //To store pharmacies to populate the Pharmacy Name
            
            //To fetch the PBM Account related details
            List<Account> lstPBMAcc=[SELECT Id,Name,BOT_Entity_Id__c
                                     FROM Account
                                     WHERE Id=:accId
                                     LIMIT 1];

            if(lstPBMAcc[0].BOT_Entity_Id__c!='')
            {
                strPBMId=lstPBMAcc[0].BOT_Entity_Id__c;
            }
            
            //To dynamically populate the channel
            lstPhar=[Select Id,BOT_PBM_Name__c,BOT_Channel__c
                     FROM BOT_Pharamcy_Service__c
                     WHERE BOT_PBM_ID__c=:strPBMId
                     ORDER BY BOT_Channel__c
                     LIMIT 50000]; 
            
            for(BOT_Pharamcy_Service__c objPhar:lstPhar)
            {
                setChannels.add(objPhar.BOT_Channel__c);
            }

            if(!setChannels.isEmpty())
            {
                channel= new List<String> (setChannels)[0]; 
            }
            
            lstTempPhar=[Select Id,Name,BOT_Channel__c,BOT_PBM_ID__c
                         FROM BOT_Pharamcy_Service__c
                         WHERE BOT_PBM_ID__c=:strPBMId AND BOT_Channel__c=:channel
                         ORDER BY Name
                         LIMIT 50000];
            
            for(BOT_Pharamcy_Service__c objPhar:lstTempPhar)
            {
                setPharmacy.add(objPhar.Name);     
            }

            if(!setPharmacy.isEmpty())
            {
                firstPhar= new List<String> (setPharmacy)[0];    
            }
            
            strFilter='BOT_PBM_ID__c=:strPBMId AND Name=:firstPhar AND BOT_Channel__c=:channel';
            
            strCountQuery = 'Select Count() From BOT_Pharamcy_Service__c Where ' + strFilter;
            total_size = database.Countquery(strCountQuery);
            
            //Retrieving pharmacies that are displayed on the VF page
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
                strExeQuery ='Select Id,Name,BOT_Account__c,BOT_Channel__c,BOT_PBM_Name__c,BOT_Account__r.Name,BOT_Account__r.Entity_Level__c,BOT_Account__r.BOT_State__c,BOT_Account__r.IsPersonAccount FROM BOT_Pharamcy_Service__c WHERE BOT_PBM_ID__c=:strPBMId AND Name=:firstPhar AND BOT_Channel__c=:channel ORDER BY BOT_Account__r.Name LIMIT :list_size Offset: counter';
                fetchPharmacy();
            }    
        }
        
        Catch(Exception e)
        {
            system.debug('Exception Found at Line number '+e.getLineNumber() +':'+e.getMessage());
        } 
    }
    
    Public void fetchPharmacy()
    {
        lstPharmacies=database.query(strExeQuery);   
    }
    
    //To store the Pharmacy Service Name values
    public List<SelectOption> getdynamiclist()
    {
        List<SelectOption> options = new List<SelectOption>();

        for(String value : setPharmacy)
        {
            options.add(new SelectOption(value,value));
        }
        return options;
    }
    
    //To store the Channel Names
    public List<SelectOption> getchannelList()
    {
        List<SelectOption> channels = new List<SelectOption>();
        
        for(String value : setChannels)
        {
            channels.add(new SelectOption(value,value));
        }
        return channels;   
    }
    
    //Used to fetch the pharmacy services based on the selected channel
    Public void changeChannel()
    {
        setPharmacy.clear();
        counter=0;
        
        lstPhar=[Select Id,Name,BOT_PBM_ID__c,BOT_Channel__c
                 FROM BOT_Pharamcy_Service__c
                 WHERE BOT_PBM_ID__c=:strPBMId AND BOT_Channel__c=:selChannel
                 ORDER BY Name
                 LIMIT 50000];
         
         for(BOT_Pharamcy_Service__c objPhar:lstPhar)
         {
            setPharmacy.add(objPhar.Name);     
         }
        
         if(!setPharmacy.isEmpty())
         {
            firstPhar= new List<String> (setPharmacy)[0];    
         }
        
        
        //Executes the below loop if the channel change is happening for the first time. 
      /*  if(firstChange==null)
        {
            strFilter='BOT_PBM_ID__c=:strPBMId AND Name=:firstPhar AND BOT_Channel__c=:selChannel';
            strCountQuery = 'Select Count() From BOT_Pharamcy_Service__c Where ' + strFilter;
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
                strExeQuery ='SELECT Id,Name,BOT_Account__c,BOT_Channel__c,BOT_PBM_Name__c,BOT_Account__r.Name,BOT_Account__r.Entity_Level__c,BOT_Account__r.BOT_State__c,BOT_Account__r.IsPersonAccount FROM BOT_Pharamcy_Service__c WHERE BOT_PBM_ID__c=:strPBMId AND Name=:firstPhar AND BOT_Channel__c=:selChannel ORDER BY BOT_Account__r.Name LIMIT :list_size Offset: counter';
                fetchPharmacy();    
            }
            firstChange=true;
        }
        
        else
        {*/
            strFilter='BOT_PBM_ID__c=:strPBMId AND Name=:selected AND BOT_Channel__c=:selChannel';
            strCountQuery = 'Select Count() From BOT_Pharamcy_Service__c Where ' + strFilter;
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
                strExeQuery ='SELECT Id,Name,BOT_Account__c,BOT_Channel__c,BOT_PBM_Name__c,BOT_Account__r.Name,BOT_Account__r.Entity_Level__c,BOT_Account__r.BOT_State__c,BOT_Account__r.IsPersonAccount  FROM BOT_Pharamcy_Service__c WHERE BOT_PBM_ID__c=:strPBMId AND Name=:selected AND BOT_Channel__c=:selChannel ORDER BY BOT_Account__r.Name LIMIT :list_size Offset: counter';
                fetchPharmacy();
            }
            
            //Executes if the selected Channel and the Pharmacy Name does not have any records
            else
            {
                strFilter='BOT_PBM_ID__c=:strPBMId AND Name=:firstPhar AND BOT_Channel__c=:selChannel';
                strCountQuery = 'Select Count() From BOT_Pharamcy_Service__c Where ' + strFilter;
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
                    strExeQuery ='SELECT Id,Name,BOT_Account__c,BOT_Channel__c,BOT_PBM_Name__c,BOT_Account__r.Name,BOT_Account__r.Entity_Level__c,BOT_Account__r.BOT_State__c,BOT_Account__r.IsPersonAccount  FROM BOT_Pharamcy_Service__c WHERE BOT_PBM_ID__c=:strPBMId AND Name=:firstPhar AND BOT_Channel__c=:selChannel ORDER BY BOT_Account__r.Name LIMIT :list_size Offset: counter';
                    fetchPharmacy();
               /* }*/
            }
        }
    }
    
    //Used to fetch the pharmacy services based on the selected Pharmacy Name
    Public void changePharmacy()
    {
        counter=0;
        strFilter='BOT_PBM_ID__c=:strPBMId AND Name=:selected AND BOT_Channel__c=:selChannel';
        strCountQuery = 'Select Count() From BOT_Pharamcy_Service__c Where ' + strFilter;
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
            strExeQuery ='Select Id,Name,BOT_Account__c,BOT_Channel__c,BOT_PBM_Name__c,BOT_Account__r.Name,BOT_Account__r.Entity_Level__c,BOT_Account__r.BOT_State__c,BOT_Account__r.IsPersonAccount FROM BOT_Pharamcy_Service__c WHERE BOT_PBM_ID__c=:strPBMId AND Name=:selected AND BOT_Channel__c=:selChannel ORDER BY BOT_Account__r.Name LIMIT :list_size Offset: counter';
            fetchPharmacy();    
        }
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
        fetchPharmacy();
        return null;
    }
    
    //User clicked previous button
    Public PageReference Previous()
    {
        counter -= list_size;
        fetchPharmacy();
        return null;
    }
    
    //User clicked next button
    Public PageReference Next()
    {
        counter += list_size;
        fetchPharmacy();
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
        fetchPharmacy();
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