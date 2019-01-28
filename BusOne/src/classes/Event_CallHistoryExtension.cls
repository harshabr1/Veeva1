/*

Class Name:Event_CallHistoryExtension
Created By :Harsha BR
Created Date:01/30/2017
Overview:Used to fetch all the call history detail records related to an account. 

*/
public class Event_CallHistoryExtension 
{
    Public Id eventID{get;set;}                     //Used to store the Event record ID
    Public Id prodId{get;set;}
    Public Boolean blnFound{get;set;}               //True if the call history is present
    Public String accName{get;set;}                 //Used to store the name of the account
    Public Integer numberOfRowToRemove {get;set;}    //Used to store the row no the products table 
    Public Event objEvent{get;set;}                 //Event object
    Public Product__c objProduct{get;set;}          //Product Object
    Public List<Event> lstEvents{get;set;}          //Used to store the list of the Events.
    Public List<Product__c> lstProducts{get;set;}   //List contaning the products    
    Public List<Product__c> lstProdDisplay{get;set;} //List containg the products to be displayed
    public Integer removePos=0;
    
    //Constructor
    Public Event_CallHistoryExtension(ApexPages.StandardController controller) 
    {
        eventID = controller.getRecord().Id;
        objProduct=new Product__C();
        lstProducts=new list<Product__c>();
        lstProdDisplay=new list<Product__c>();
        lstProducts.add(objProduct);  
        fetchCallHistory();
    } 
    
    //Used to fetch all the Events associated with the account.
    Public void fetchCallHistory()
    {
        Account objAcc=new Account();
        Id accID;
        Event objEvent;
        
        blnFound=false;
        
        //Query to fetch the Event
        objEvent=[SELECT Id,AccountId
                  FROM Event
                  WHERE ID=:eventID
                  LIMIT 1];
        
        //Query to fetch the Account Name
        objAcc=[SELECT Id,Name
                FROM Account
                WHERE Id=:objEvent.AccountId
                LIMIT 1];
        
        accName=objAcc.Name;
        
        //Query to fetch the events associated with the account
        lstEvents=[SELECT Id,AccountId,Subject,Call_Type__c,StartDateTime,IsRecurrence,Product__c,Objective1__c,(SELECT Id, Name FROM Attachments) 
                   FROM Event
                   WHERE AccountId=:objEvent.AccountId AND ID!=:eventID AND EndDateTime <=:System.now()
                   LIMIT 50000]; 
                   
        //Query to fetch the products associated with the event           
        lstProdDisplay=[SELECT Id,Product__c,Event_ID__c,Objective1__c,Objective2__c,Objective3__c
                        FROM Product__c 
                        WHERE Event_ID__c=:eventID 
                        LIMIT 50000];
        
        if(!lstEvents.isEmpty())
        {
            blnFound=true;     
        }   
    }
    
    //Used to add the product related information
    public PageReference saveProducts()
    {
        List<Product__C> lstProductsToBeInserted=new List<Product__C>(); //To store the list of Products to be inserted
        
        if(lstProducts[0].Product__c==null && lstProducts[0].Objective1__c==null)
        {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select either Product or Objective1'));
             return null;   
        }
        
        Event objRetrieve=[SELECT Id,Product__c,Objective1__c FROM Event Where Id=:eventID LIMIT 1]; 
        
        if(objRetrieve.Product__c==null && objRetrieve.Objective1__c==null)
        {
            objRetrieve.Product__c=lstProducts[0].Product__c;
            objRetrieve.Objective1__c=lstProducts[0].Objective1__c;    
            update objRetrieve;
        }

        for(Product__c objProd:lstProducts)
        {
            if(objProd.Product__c!=null || objProd.Objective1__c!=null)
            {
                objProd.Event_ID__c=eventID;
                lstProductsToBeInserted.add(objProd);
            }
               
        }
        
        if(!lstProductsToBeInserted.isEmpty())
        {
            insert lstProductsToBeInserted;
        }
                       
        PageReference detailPage=new PageReference('/'+eventID);
        return detailPage;
    }
    
    //Used to add the product related information
    Public void addProducts()
    {
        Product__c objProd=new Product__c();
        lstProducts.add(objProd);
    }
    
    //Used to close the Product Information page
    public PageReference closeProducts()
    {
        PageReference detailPage=new PageReference('/'+eventID);
        return detailPage;
    }
    
    //Used to delete the particular row
    Public PageReference deleteNewProd()
    {
        lstProducts.remove(numberOfRowToRemove);
        return null;
    }
    
    //Used to delete the product records permanently
    Public void deleteProduct()
    {
        List<Product__C> lstProdToDelete=new List<Product__c>();
        
         for(Product__c objProduct:lstProdDisplay) 
         {
              if(objProduct.Id==prodId)
              {
                  lstProdToDelete.add(objProduct);  
              } 
         }
         
         for(Integer i=0;i<lstProdDisplay.size();i++)
         {
            if(lstProdDisplay[i].id==prodId)
            {
                removepos=i;
            }
         }
         
         delete lstProdToDelete;
         lstProdDisplay.remove(removePos);
    }
}