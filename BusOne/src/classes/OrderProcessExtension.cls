public class OrderProcessExtension {
    private final Order_vod__c order;
    
    public OrderProcessExtension(ApexPages.StandardController standardController) {
        this.order = (Order_vod__c) standardController.getRecord();
    }   

    public boolean getRendered(){
        // check several settings to see if we display the approval history related list
        ID id = order.Id;
        
        // process instance exists for the object
        Integer piCount = [SELECT count() FROM ProcessInstance WHERE TargetObjectId = :id];
        
        // enable order approval setting
        Decimal orderApprovalRequest = Veeva_Settings_vod__c.getInstance().ENABLE_ORDER_APPROVAL_vod__c;  
        
        // valid relationship
        boolean hasValidRelationship = false;
        Schema.DescribeSObjectResult describeResult = Order_vod__c.getSObjectType().getDescribe();
        List<Schema.ChildRelationship> childRelationships = describeResult.getChildRelationships();
        for(Schema.ChildRelationship rel : childRelationships){
            if ('ProcessSteps'.equals(rel.getRelationshipName())){
                hasValidRelationship = true;
            }
        }
        
        return piCount > 0 && orderApprovalRequest == 1 && hasValidRelationship;
    }
}