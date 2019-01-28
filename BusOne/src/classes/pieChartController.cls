/*
Name			: pieChartController
Created Date	: 13-JUN-2017
Created by		: SREENIVASULU ADIPUDI
Description		: It is a controller class for BOT_Maestro_SF_DashBoard VF Page.
*/
public class pieChartController 
{    
    public List<Accountdata> accountsList;					//To store records which are received from the external system
    public List<Accountdata> filterAccList {get;set;}		//To store records which are filtered by the selected picklist value
    public List<Accountdata> formularies {get;set;}    		//To store the selected formularies
    transient List<Accountdata> allAccountsList;			//To store all account records retrun from the external server
    Public string getEntityID {get;set;}					//To get the Entity ID from the Input    
    Public string inputValue {get;set;}						//To store the selected pick list value   
    Public string formName {get;set;}						//To store the Formulary Name
    public Boolean displayFilter {get;set;}					//To render filter condition block
    public Boolean displayChart {get;set;}  				//To render bar chart and pie chart
    public Boolean displayFormulary {get;set;}				//To render the formulary table pageBlock    
    
    //Constructor
    //public pieChartController()
    //{ 
        //accountsData();	
    //}
    //To get records from external system
    public void accountsData()
    {
        //Displaying an error message whenever entity ID Text Box is empty
        if(getEntityID=='')
        {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please Enter the Entity ID'));
        }
        else
        {
            displayFilter = false;									//To hide the if condition response pageBlock				
            displayChart = false;									//To hide the else condition response pagBlock
            displayFormulary = false;       	
            //Creating end point URL with input entity ID
            String reqString = 'http://www.b1maestro.com/SalesForceServices/SalesForceService.svc/GetEntityDetailsJSON?EntityID='+getEntityID;        
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndPoint(reqString);
            request.setMethod('GET');
            HttpResponse response = http.send(request);       
            //To verify the server response
            if(response.getStatusCode() == 200 && response.getBody() != '')
            {
                string JsonString = response.getBody();
                //Extrection JSON data
                accountsList = (List<Accountdata>)system.JSON.deserialize(JsonString, List<Accountdata>.class);
                //Verifying that the data is exist or not
                if(accountsList != null)
                    //Copying data to filterAccList Varible
                    filterAccList = accountsList.clone();
                displayFilter=true;			
                displayChart=true;
                displayFormulary=false;			      
            }
            //If there is no response from the server
            else
            {
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'No records found'));
                displayFilter=false;
                displayChart=false;
                displayFormulary=false;
            }
        }
    }
    //Filtering the records based on the selected picklist value
    public void filterFormulary()
    {
        //Getting all records when the selected picklist value is all 
        if(inputValue == '--All--')
        {           		
            filterAccList = accountsList.clone();   
        }
        //Getting records where formulary lives are above 50K
        else if(inputValue == 'A50')
        {
            filterAccList = new List<Accountdata>();
            for(Accountdata acc : accountsList)
            {
                if((Integer.valueOf(acc.FORMULARY_LIVES))>50000)
                {
                    filterAccList.add(acc);
                    //System.debug('Above 50K Lives'+acc);
                }
            }
        }
        //Getting records where formulary lives are between 10K - 50K        
        else if(inputValue == 'B10-50')
        {
            filterAccList = new List<Accountdata>();
            for(Accountdata acc : accountsList)
            {
                if((Integer.valueOf(acc.FORMULARY_LIVES))>=10000 && (Integer.valueOf(acc.FORMULARY_LIVES))<=50000)
                {
                    filterAccList.add(acc);
                    //System.debug('Between 10K to 50K Lives'+acc);
                }
            }
        }
        //Getting records where formulary lives are below 10K
        else if(inputValue == 'U10')
        {
            filterAccList = new List<Accountdata>();
            for(Accountdata acc : accountsList)     	   
            {
                if((Integer.valueOf(acc.FORMULARY_LIVES))<=10000)
                {
                    filterAccList.add(acc);
                    //System.debug('Upto 10K Lives'+acc);
                }
            }
        }
    }
    //Wrapper Class used for deserialize the Http response
    public class Accountdata
    {
        public String ENTITY_ID {get;set;}
        public String ENTITY_NAME {get;set;}
        public String ENTITY_STATE {get;set;}
        public String FORMULARY_ID {get;set;}
        public String FORMULARY_LIVES {get;set;}
        public String FORMULARY_NAME {get;set;}
    }
    //Preparing chart data  
    public List<PieWedgeData> getPieData1()
    {
        List<PieWedgeData> data1 = new List<PieWedgeData>();
        Integer intSkip=0;        
        if(accountsList!=null)
        {
            for(Accountdata acc : filterAccList)
            {
                if(intSkip>3)
                {
                    //adding the formulary name and formulary lives to chart data
                    data1.add(new PieWedgeData(acc.FORMULARY_NAME,Integer.valueOf(acc.FORMULARY_LIVES)));   
                }
                intSkip++;
            }    
        }
        
        return data1;
    }
    public class PieWedgeData
    {
        public String formularyName {get;set;}
        public Integer formularyLives {get;set;}
        public PieWedgeData(String formularyName, Integer formularyLives)
        {
            this.formularyName=formularyName;
            this.formularyLives=formularyLives;
        }
    }
    //Preparing the picklist values
    public List<selectOption> getDynamicList() 
    {
        List<selectOption> forularyLives = new List<selectOption>();
        forularyLives.add(new selectOption('--All--','--All--'));
        forularyLives.add(new selectOption('A50','>50K Lives'));
        forularyLives.add(new selectOption('B10-50','10K-50K Lives'));
        forularyLives.add(new selectOption('U10','<10K Lives'));
        return forularyLives;
    }
    //To get selected formularies by click on a graph bar    
    Public PageReference myActionInController()
    {
        String reqString = 'http://www.b1maestro.com/SalesForceServices/SalesForceService.svc/GetEntityDetailsJSON';        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndPoint(reqString);
        request.setMethod('GET');
        HttpResponse response = http.send(request);       
        //To verify the server response
        if(response.getStatusCode() == 200 && response.getBody() != '')
        {
            string JsonString = response.getBody();
            allAccountsList = (List<Accountdata>)system.JSON.deserialize(JsonString, List<Accountdata>.class);                              
            Integer count=1;
            formularies = new List<Accountdata>();
            for(AccountData acc:accountsList)
            {                
                if(Count<=20)
                {
                    formularies.add(acc);
                    System.debug('Formulary'+count+' '+acc);
                    count++;
                }
                else
                {
                    break;
                }
                
            }
            displayFilter=false;
            displayChart=false;
            displayFormulary=true;
        }       
        //String accName = Apexpages.currentPage().getParameters().get('accountName');
        //string passedParam2 = system.CurrentPageReference().getParameters().get('entityId');
        
        //system.debug('***Account Name ***'+accName);
        system.debug('***Formulary Name ***'+formName);
        //system.debug('***Entity Id***'+passedParam2);
        PageReference pageRef = new PageReference('/apex/BOT_Maestro_Test_FormularyVF');
        return pageRef;    
    }
    /*
    public PageReference previouspage()
    {
        PageReference pr = new PageReference ('/apex/BOT_Maestro_SF_DashBoard');
        pr.setRedirect(true);
        return pr;
    }
	*/    
}