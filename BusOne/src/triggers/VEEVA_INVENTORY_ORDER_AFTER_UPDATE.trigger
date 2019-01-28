trigger VEEVA_INVENTORY_ORDER_AFTER_UPDATE on Inventory_Order_vod__c (after update) {
    //1. unlock order lines if order was unlocked (status set back to saved)
    //2. submit order lines that don't require approval, submit order lines that have been approved

    List<Id> savedOrders = new List<Id>();
    List<Id> submittedOrders = new List<Id>();
    for (Integer i=0;i<Trigger.new.size();i++) {
        if (Trigger.new[i].Order_Status_vod__c == 'Saved_vod') {
            savedOrders.add(Trigger.new[i].Id);
        } else if (Trigger.new[i].Approved_vod__c || Trigger.new[i].Order_Status_vod__c == 'Submitted_vod') {
            submittedOrders.add(Trigger.new[i].Id);
        }
    }

    if (savedOrders.size() > 0) {
        List<Inventory_Order_Line_vod__c> linesToSave = [select Id, Product_vod__r.Name, Inventory_Order_Allocation_vod__c FROM Inventory_Order_Line_vod__c
                                                     where Inventory_Order_Line_Status_vod__c != 'Saved_vod'
                                                      and Inventory_Order_Header_vod__c in :savedOrders];
        if (linesToSave.size() > 0) {
            for (Inventory_Order_Line_vod__c orderLine : linesToSave) {
                orderLine.Inventory_Order_Line_Status_vod__c = 'Saved_vod';
            }
            try {
                update linesToSave;
            }
            catch (DMLException e){
                modifyOverlapDMLExceptionMsg(linesToSave, e);
                throw e;
            }
        }
    }

    if (submittedOrders.size() > 0) {
        List<Inventory_Order_Line_vod__c> linesToSubmit = [select Id, Product_vod__r.Name, Inventory_Order_Allocation_vod__c, Order_Quantity_vod__c FROM Inventory_Order_Line_vod__c
                                                     where Inventory_Order_Line_Status_vod__c != 'Submitted_vod'
                                                      and Inventory_Order_Header_vod__c in :submittedOrders];
        if (linesToSubmit.size() > 0) {
            for (Inventory_Order_Line_vod__c orderLine : linesToSubmit) {
                orderLine.Inventory_Order_Line_Status_vod__c = 'Submitted_vod';
                orderLine.Order_Fulfilled_Quantity_vod__c = orderLine.Order_Quantity_vod__c;
            }
            try {
                update linesToSubmit;
            }
            catch (DMLException e){
                modifyOverlapDMLExceptionMsg(linesToSubmit, e);
                throw e;
            }
        }
    }
    
    void modifyOverlapDMLExceptionMsg(List<Inventory_Order_Line_vod__c> lines, DMLException e) {
        if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Overlap detected')) {
            String errorMsg = 'There are Inventory Order Allocations with overlapping Allocation Date ranges:';
            for (Integer i = 0; i < e.getNumDml(); ++i) {
                Inventory_Order_Line_vod__c line = lines.get(e.getDmlIndex(i));
                errorMsg += '\nProduct \'' + line.Product_vod__r.Name + '\' (' + line.Inventory_Order_Allocation_vod__c + ': ' + e.getDMLMessage(i) + ')';
            }
            e.setMessage(errorMsg);
        }
    }
}