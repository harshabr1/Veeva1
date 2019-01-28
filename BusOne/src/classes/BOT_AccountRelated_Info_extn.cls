/*
Name : BOT_AccountRelated_Info_extn
Created by : Sreenivasulu Adipudi
Created Date : 07/19/2017
VF page : BOT_AccountRelated_Info
Overview : It is Visualforce page standard controller class
*/
public with sharing class BOT_AccountRelated_Info_extn 
{
    Public ID acctID{get;set;}                                                          //Used to store the current record id    
    Public List <Account_Plan_vod__c> listOfPlans {get;set;}                            //Used to store the List account plans which is related to selected account 
    Public string selected{get;set;}                                                    //Used to store the selected channel VF page
    Public set<String> picklist = new set<String>();                                    //Used to store the unique channels
    Public List<Account_Plan_vod__c> plansForChannel = new List<Account_Plan_vod__c>(); //Used to store the related plan demograpics records for the selected account
    Public List<Formulary_Products_vod__c> formulary {get;set;}                         //Used to store the Formulary records which is related to selected account
    Public List<BOT_Pharamcy_Service__c> Pharmacy {get;set;}                            //Used to store the Pharmacy Service records which is related to selected account    
    Public String sortOrder;                                                            //USed to store the data retrieving order
    Public String queryString;                                                          //Used to prepare the query string   
    private integer count=1;                                                            //To take the function calling
    private integer counter=0;                                                          //To keep track of offset
    private integer list_size=10;                                                       //To set the page size to show the paze size/records
    public integer total_size;                                                          //Used to show user the total size of the list
    public List<Account_Plan_vod__c> pagenationTest {get;set;}
                
    
    //Constructor
    public BOT_AccountRelated_Info_extn(ApexPages.StandardController controller)
    {
        //Getting the current account Id
        acctID=controller.getRecord().Id;
        
        //Getting the related plan demographics records based on selected account id
        plansForChannel = [select BOT_Account__c,BOT_Channel__c,id,name From Account_Plan_vod__c Where BOT_Account__c =: acctID order by BOT_Channel__c];
        total_size=[select count() from Account_Plan_vod__c Where BOT_Account__c =: acctID];
        for(Account_Plan_vod__c st : plansForChannel)
        {
            //Getting the unique channel values
            picklist.add(st.BOT_Channel__c);
            sortOrder = 'BOT_Channel__c';
        }
        //To retrieve all the plans, formularies and pharmcy services recores related to selected account
        initialRetrievePlan();
        initialRetrieveFomulary();
        initialRetrievePharmacy();
    }
    
    //To get all the plan records related to selected account
    Public void initialRetrievePlan()
    {
        //Preparing the query string to retrieve plan demographics records
        queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c FROM Account_Plan_vod__c WHERE BOT_Account__c =: acctID ORDER BY '+sortOrder+' limit 10';         
        listOfPlans = Database.query(queryString);
    }
    
    //To get all the formulary records related to selected account
    Public void initialRetrieveFomulary()
    {
        //Preparing the query string to retrieve formulary records
        queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Account_Plan__r.name,BOT_Formulary_Name__c,BOT_Formulary_Lives__c FROM Formulary_Products_vod__c WHERE BOT_Account__c =: acctID ORDER BY '+sortOrder+' limit 10'; 
        formulary = Database.query(queryString);
    }
    
    //To get all the pharmacy service records related to selected account
    Public void initialRetrievePharmacy()
    {
        //Preparing the query string to retrieve pharmacy services records
        queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_PBM_Name__c,BOT_Corporate__c,BOT_Other_Provider_Name__c FROM BOT_Pharamcy_Service__c WHERE BOT_Account__c =: acctID ORDER BY '+sortOrder+' limit 10';        
        Pharmacy = Database.query(queryString);
        System.debug('Pharmacy'+Pharmacy);
    }
    
    //Retrieving the Plan demographics filtered by selected channel
    Public void channelFilterRetrievePlan()
    {
        //Preparing the query string to retrieve plan demographics records
        queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c FROM Account_Plan_vod__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected ORDER BY '+sortOrder+' limit 10'; 
        listOfPlans = Database.query(queryString);        
    }
    
    //Retrieving the Formulary records filtered by selected channel
    Public void channelFilterRetrieveFormulay()
    {
        //Preparing the query string to retrieve formulary records
        queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Account_Plan__r.name,BOT_Formulary_Name__c,BOT_Formulary_Lives__c FROM Formulary_Products_vod__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected ORDER BY '+sortOrder+' limit 10'; 
        formulary = Database.query(queryString);    
    }
    
    //Retrieving the Pharmacy services records filtered by selected channel 
    Public void channelFilterRetrievePharmacy()
    {
        //Preparing the query string to retrieve pharmacy services records
        queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_PBM_Name__c,BOT_Corporate__c,BOT_Other_Provider_Name__c FROM BOT_Pharamcy_Service__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected ORDER BY '+sortOrder+' limit 10';        
        Pharmacy = Database.query(queryString);   
    }
    
    //To get account related records
    public void Get_Accout_Summary()
    {
        //To get all the records where selected channel is All
        if(selected=='--All--') 
        {
            initialRetrievePlan();
            initialRetrieveFomulary();
            initialRetrievePharmacy();
        }
        //To get records filtered by selected channel
        else
        {
            channelFilterRetrievePlan();
            channelFilterRetrieveFormulay();
            channelFilterRetrievePharmacy();
        }
    }
    
    //Sort the plan records ordered by channel
    public void PlanOrderByChannel()
    {
        sortOrder = 'BOT_Channel__c';        
        if(selected=='--All--')
            initialRetrievePlan();
        else
            channelFilterRetrievePlan();    
    }
    
    //Sort the plan records ordered by name
    public void PlanOrderByName()
    {
        sortOrder = 'name';
        if(selected=='--All--') 
            initialRetrievePlan();
        else            
            channelFilterRetrievePlan();
    }
    
    //Sort the formulary records ordered by channel
    public void FormularyOrderByChannel()
    {
        sortOrder = 'BOT_Channel__c';        
        if(selected=='--All--') 
            initialRetrieveFomulary();            
        else
            channelFilterRetrieveFormulay();    
    }
    
    //Sort the formulary records ordered by name
    public void FormularyOrderByName()
    {
        sortOrder = 'name';       
        if(selected=='--All--') 
            initialRetrieveFomulary();             
        else
            channelFilterRetrieveFormulay();   
    }
    
    //Sort the pharmacy records ordered by channel
    public void pharmacyOrderByChannel()
    {
        sortOrder = 'BOT_Channel__c';       
        if(selected=='--All--') 
            initialRetrievePharmacy();            
        else
            channelFilterRetrievePharmacy();
    }
    
    //Sort the pharmacy records ordered by name
    public void pharmacyOrderByName()
    {
        sortOrder = 'name';      
        if(selected=='--All--') 
            initialRetrievePharmacy();            
        else
            channelFilterRetrievePharmacy();
    }
    
    //When user clicked on the begining button
    public pageReference beginning()    
    {
        counter = 0;
        //queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c FROM Account_Plan_vod__c WHERE  BOT_Account__c =: acctID ORDER BY '+sortOrder+'limit 10';
        if(selected=='--All--')
        {
            pagenationTest = [SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c From Account_Plan_vod__c Where BOT_Account__c =: acctID order by BOT_Channel__c limit 10];
        }
        else
        {
            queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c FROM Account_Plan_vod__c WHERE BOT_Account__c =: acctID and BOT_Channel__c =: selected by BOT_Channel__c limit 10'; 
        }
        return null;
    }
    //When user clicked on the previous button
    public pageReference previous()
    {
        counter = counter-list_size;
        if(count == 1)
        {           
            //queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c FROM Account_Plan_vod__c WHERE  BOT_Account__c =: acctID ORDER BY '+sortOrder+'limit 10 offset 10';
            pagenationTest = [SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c From Account_Plan_vod__c Where BOT_Account__c =: acctID order by BOT_Channel__c limit 10 offset 10];
            count++;  
        }
        else
        {
            //queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c FROM Account_Plan_vod__c WHERE  BOT_Account__c =: acctID ORDER BY '+sortOrder+'limit 10 offset 10';
            pagenationTest = [SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c From Account_Plan_vod__c Where BOT_Account__c =: acctID order by BOT_Channel__c limit 10 offset 10];
        }
        return null;
    }
    //When user clicked on the next button
    public pageReference next()
    {
        counter = counter+list_size;
        //queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c FROM Account_Plan_vod__c WHERE  BOT_Account__c =: acctID ORDER BY '+sortOrder+'limit 10 offset 10';
        pagenationTest = [SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c From Account_Plan_vod__c Where BOT_Account__c =: acctID order by BOT_Channel__c limit 10 offset 10];           
        return null;        
    }
    //When user clicked on the end button
    public pageReference end()
    {
        counter = total_size - math.mod(total_size, list_size);
        //queryString = 'SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c FROM Account_Plan_vod__c WHERE  BOT_Account__c =: acctID ORDER BY '+sortOrder+'limit 10 offset 20';
        pagenationTest = [SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Formulary_Used__c,BOT_Product_Lives_Rx__c,BOT_PBM__c From Account_Plan_vod__c Where BOT_Account__c =: acctID order by BOT_Channel__c limit 10 offset 20];           
        return null;    
    }
    //This will disable the previous and beginning buttons
    public Boolean getDisabledPrevious()
    {
        if(counter>0)
            return false;
        else
            return true;
    }
    //This will disable the next and end buttons
    public Boolean getDisabledNext()
    {
        if(counter+list_size < total_size)
            return false;
        else
            return true;        
    }
    public Integer getTotal_size()
    {
        return total_size;
    }
    public Integer getPageNumber()
    {
        return counter/list_size+1;
    }
    public Integer getTotalPages()
    {
        if(math.mod(total_size, list_size) > 0)
            return total_size/list_size + 1;
        else
            return total_size/list_size;
    }
    //Creating chanel selection picklist values
    public List<selectOption> getDynamicList() 
    {
        List<selectOption> options = new List<selectOption>();
        if(picklist.size()>1)
        {
            options.add(new selectOption('--All--','--All--'));
        }
        for(String s : picklist)
        {
            //Add the channels to picklist to display on VF Page
            options.add(new selectOption(s,s));
        }
        return options;
    }
}