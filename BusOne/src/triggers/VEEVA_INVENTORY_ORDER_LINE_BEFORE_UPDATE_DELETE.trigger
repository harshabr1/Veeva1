trigger VEEVA_INVENTORY_ORDER_LINE_BEFORE_UPDATE_DELETE on Inventory_Order_Line_vod__c (before update, before delete) {
    //1. prevents modification of order line if the order line is locked

    if (VEEVA_PROCESS_FLAGS.getUpdateSIO())
        return;
    
    for (Integer i=0;i<Trigger.old.size();i++) {
        String orderLineStatus = Trigger.old[i].Inventory_Order_Line_Status_vod__c;
        if ((orderLineStatus != 'Saved_vod') && (orderLineStatus != 'Canceled_vod')) {
            if (Trigger.isDelete){
                String delErrMsg = VOD_GET_ERROR_MSG.getErrorMsg('ERROR_DELETING_ORDER_LINE_STATUS', 'ORDER_MANAGEMENT');
                Trigger.old[i].addError(delErrMsg, false);
            }
            else{
                String modErrMsg = VOD_GET_ERROR_MSG.getErrorMsg('ERROR_MODIFYING_ORDER_LINE_STATUS', 'ORDER_MANAGEMENT');
                Trigger.new[i].addError(modErrMsg, false);
            }
        }
    }
}