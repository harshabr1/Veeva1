trigger VEEVA_INVENTORY_ORDER_ALLOCATION_BEFORE_DEL on Inventory_Order_Allocation_vod__c (before delete) {
    for (Integer i = 0 ; i < Trigger.old.size(); i++) {
        if (Trigger.old[i].Total_Order_Fulfilled_Quantity_vod__c > 0) {
            String delErrMsg = VOD_GET_ERROR_MSG.getErrorMsg('ERROR_DELETING_ALLOC_RECORD', 'InventoryOrder');
            Trigger.old[i].addError(delErrMsg, false);
        }
    }
}