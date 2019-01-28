/*
Name            : BOT_Maestro_Test_Formulary
Created By      : SREENIVASULU ADIPUDI
Created Date    : 16/JUN/2017
Description     : It is controller class of BOT_Maestro_Test_Formulary Visual Force page.
*/
public class BOT_Maestro_Test_Formulary 
{
    //Public string getEntityID {get;set;}                  //To get the Entity ID from the Input
    transient List<Accountdata> accountsList;       		//To store records which are received from the external system 
    public Boolean ifListSize {get;set;}                    //To render the if condition response pageBlock
    public Boolean elseListSize {get;set;}                  //To render the else condition response pagBlock
    public List<Accountdata> formularies {get;set;}
    //Constructor
    public BOT_Maestro_Test_Formulary()
    {
        accountsData();
    }
    //To get records from external system
    public void accountsData()
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
            accountsList = (List<Accountdata>)system.JSON.deserialize(JsonString, List<Accountdata>.class);                              
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
            ifListSize=true;
        }
        else
        {
            elseListSize=true;
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