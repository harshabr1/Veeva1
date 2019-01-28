/*
Name			: BOT_Maestro_SF_Integration
Created By 		: SREENIVASULU ADIPUDI
Created Date	: 09/JUN/2017
Description		: It is controller class of BOT_Maestro_SF_Integration Visual Force page which is created for integration process.
*/
public class BOT_Maestro_SF_Integration 
{    
    Public string getEntityID {get;set;}					//To get the Entity ID from the Input
    public List<Accountdata> accountsList {get;set;}		//To store records which are received from the external system 
    public Boolean ifListSize {get;set;}					//To render the if condition response pageBlock
    public Boolean elseListSize {get;set;}  				//To render the else condition response pagBlock
    //Constructor
    public BOT_Maestro_SF_Integration()
    { 
    	ifListSize = false;									//To hide the if condition response pageBlock				
        elseListSize = false;								//To hide the else condition response pagBlock
    }
    //To get records from external system 
    public void accountsData()
    {
        if(getEntityID == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please Enter the Entity ID'));
        }
        else
        {
            //Creating end point URL with input entity ID
            String reqString = 'http://www.b1maestro.com/SalesForceServices/SalesForceService.svc/GetEntityDetailsJSON?EntityID='+getEntityID;        
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndPoint(reqString);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            System.debug('Response'+Response.getBody());
            //To verify the server response
            if(response.getStatusCode() == 200 && response.getBody() != '')
            {
                string JsonString = response.getBody();
                accountsList = (List<Accountdata>)system.JSON.deserialize(JsonString, List<Accountdata>.class);                              
                ifListSize=true;            
            }
            //If there is no response from the server
            else
            {
                elseListSize=true;
            }
        }
    }
    //Wrapper Class
    public class Accountdata
    {
        public String ENTITY_ID {get;set;}
        public String ENTITY_NAME {get;set;}
        public String ENTITY_STATE {get;set;}
        public String FORMULARY_ID {get;set;}
        public String FORMULARY_LIVES {get;set;}
        public String FORMULARY_NAME {get;set;}
    }
}