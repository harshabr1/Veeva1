trigger VEEVA_AFTER_ORDER_UPDATE on Order_vod__c (after update) {
    Decimal orderApprovalRequest = Veeva_Settings_vod__c.getInstance().ENABLE_ORDER_APPROVAL_vod__c;
    Set<ID> orderIds = new Set<ID>();
    
    if (orderApprovalRequest == 1){
        System.debug('Order Approval Setting is true');
        for (Order_vod__c newOrder : Trigger.new) {
            Boolean hasBeenProcessed = orderIds.contains(newOrder.Id);
            orderIds.add(newOrder.Id);
            if (newOrder.Approval_Status_vod__c == 'Approved_vod' || newOrder.Status_vod__c != 'Submitted_vod' || 
                hasBeenProcessed || newOrder.Parent_Order_vod__c != null){
            	System.debug('Will not create approval process for order');
                continue;
            } else {
                System.debug('Attempting to create approval process for order');
            }
                    
            Approval.ProcessSubmitRequest apsr = new Approval.ProcessSubmitRequest();
            apsr.setObjectId(newOrder.Id);
            apsr.setComments(Label.VOD_ORDER_SENT_FOR_APPROVAL);
            
            Approval.ProcessResult result = null;
            AllowLockOverrideForApproval.allowOrderToBeOverridable(newOrder.Id);
            try{
                result = Approval.process(apsr);
                if (!result.isSuccess()) {
                    System.debug(result.getErrors());
                    continue;
                }
            } catch(DmlException dmlExc){
                for (Integer i = 0; i < dmlExc.getNumDml(); i++) {
                    System.debug(dmlExc.getDmlMessage(i));
                }
            }
            AllowLockOverrideForApproval.revokeAllowOrderToBeOverridable(newOrder.Id);
            if (result == null)
                continue;
            
            System.debug('Successfully created approval process for ' + newOrder.Id);
        }
    }

    // propogate status to child orders
    List<Order_vod__c> childOrders = new List<Order_vod__c>();

    //take existing query to a list to reuse
    List<Order_vod__c> existingOrders = new List<Order_vod__c>([SELECT Id, 
                                                                    Lock_vod__c, 
                                                                    Status_vod__c,
                                                                    Approval_Status_vod__c,
                                                                    Parent_Order_vod__r.Status_vod__c,
                                                                    Parent_Order_vod__r.Approval_Status_vod__c
                                                            FROM Order_vod__c WHERE Parent_Order_vod__c IN :Trigger.newMap.keySet()]);

    for (Order_vod__c child : existingOrders) {
        if ((child.Status_vod__c != 'Submitted_vod' && !child.Lock_vod__c && child.Status_vod__c != child.Parent_Order_vod__r.Status_vod__c) ||
            (orderApprovalRequest == 1 && child.Approval_Status_vod__c != child.Parent_Order_vod__r.Approval_Status_vod__c)) {
            if (orderApprovalRequest == 1) {
                AllowLockOverrideForApproval.allowOrderToBeOverridable(child.Id);
            }
            Order_vod__c toUpdate = new Order_vod__c(
                Id = child.Id,
                Status_vod__c = child.Parent_Order_vod__r.Status_vod__c
            );

            if(orderApprovalRequest == 1){
                    toUpdate.Approval_Status_vod__c = child.Parent_Order_vod__r.Approval_Status_vod__c;
                    toUpdate.Override_Lock_vod__c = true;
            } 
            childOrders.add(toUpdate);
        }
    }

    if (!childOrders.isEmpty()) {
        update childOrders;
    }
    AllowLockOverrideForApproval.revokeAllAllowOrderToBeOverridable();
}