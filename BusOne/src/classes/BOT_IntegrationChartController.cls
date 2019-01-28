/*
Name : BOT_IntegrationChartController
Created By : Harsha BR
Created Date : 13-June-2017
Overview : Controller for the "BOT_IntegrationChart" VF page
 */
public class BOT_IntegrationChartController 
{
    Public string getEntityID {get;set;}					//To get the Entity ID from the Input
    Public string accName1 {get;set;}
    Public List<Account> lstAccs {get;set;}
    

    public BOT_IntegrationChartController()
    {
        
    }
    
    public List<PieWedgeData> getPieData() 
    {  
        List<PieWedgeData> data = new List<PieWedgeData>();
        lstAccs=[SELECT Name,BOT_Entity_Id__c FROM Account LIMIT 10];
		system.debug('***lstAccs***'+lstAccs);
        for(Account temp:lstAccs)
        {           
            data.add(new PieWedgeData(temp.Name,temp.BOT_Entity_Id__c));
        }
        return data;  
    }  
    
    // Wrapper class  
    public class PieWedgeData 
    {  
        public String name { get; set; }  
        public String entity { get; set; }  
        
        public PieWedgeData(String name, String entity) 
        {  
            this.name = name;  
            this.entity = entity;  
        }  
    }  
    
   
    Public PageReference myActionInController()
    {
        String accName = Apexpages.currentPage().getParameters().get('accountName');
        string passedParam2 = system.CurrentPageReference().getParameters().get('entityId');

        system.debug('***Account Name ***'+accName);
        system.debug('***Account Name ***'+accName1);
        system.debug('***Entity Id***'+passedParam2);
    	PageReference pageRef = new PageReference('/apex/BOT_Maestro_SF_DashBoard');
        return pageRef;
    
    }
    
     @RemoteAction
    public static void DeleteQuoteLineItem(string accountName) {
    system.debug(accountName);
}
}