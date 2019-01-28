/*
Class Name:BOT_Event_CallHistoryExtension_Test
Created By :Harsha BR
Created Date:02/28/2017
Overview:Test class for the BOT_Event_CallHistoryExtension class. 
*/

@isTest(SeeAllData=False)
public class BOT_Event_CallHistoryExtension_Test 
{
    private static testMethod void validateCallHistory()
    {
        //Inserting account
        Account objAcc = new Account(Name = 'TestAccountName');
        insert objAcc;
        
        //Inserting Events
        List<Event> lstEvents=new List<Event>();
        Event objEvent=new Event(whatId=objAcc.Id,
                                 Subject='Call',
                                 StartDateTime=(system.now()-(1/6.0)),
                                 EndDateTime=(system.now()-(1/8.0)));
        lstEvents.add(objEvent);
        
        Event objEvent1=new Event(whatId=objAcc.Id,
                                 Subject='Email',
                                 StartDateTime=(system.now()-(1/6.0)),
                                 EndDateTime=(system.now()-(1/8.0)));
        lstEvents.add(objEvent1);
        
        insert lstEvents;
        
        //Inserting Products
        List<Product__c> lstProducts=new List<Product__c>();
        Product__c objProd=new Product__c(Product__c='Myrbetriq',
                                          Event_ID__c=objEvent.Id);
        lstProducts.add(objProd);
        
        Product__c objProd1=new Product__c(Product__c='Xtandi',
                                           Event_ID__c=objEvent.Id);
        lstProducts.add(objProd1);
        
        insert lstProducts;
        
        ApexPages.StandardController sc = new ApexPages.standardController(objEvent);
        Event_CallHistoryExtension controller = new Event_CallHistoryExtension(sc);
        controller.saveProducts();
        controller.addProducts();
        //controller.deleteNewProd();
        controller.deleteProduct();
        controller.closeProducts();
        
    }
}