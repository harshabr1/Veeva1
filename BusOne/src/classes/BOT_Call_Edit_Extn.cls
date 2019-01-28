public class BOT_Call_Edit_Extn 
{
    Public Id callId{get;set;}                     //Used to store the Call record ID
    public List<Product__c> productList = new List<Product__c>();
    public product__c productSingle {get;set;}
    public BOT_Call_Edit_Extn()
    {
    	//callID = controller.getId();
        productSingle = new product__c();
    }
}