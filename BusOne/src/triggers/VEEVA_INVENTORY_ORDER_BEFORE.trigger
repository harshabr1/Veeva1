trigger VEEVA_INVENTORY_ORDER_BEFORE on Inventory_Order_vod__c (before delete, before update, before insert) {
    //1. sets the OwnerId of the order to the value of the Order For User field
    //2. resets the appropriate fields when unlock flag is set to true
    //3. approves order when approve flag is set to true
    //4. prevents modification of a locked order
    //5. prevents delete of a locked order

    if (VEEVA_PROCESS_FLAGS.getUpdateSIO())
        return;

    Integer count = Trigger.isDelete ? Trigger.old.size() : Trigger.new.size();
    for (Integer i = 0;i < count;i++) {
        if (Trigger.isUpdate || Trigger.isInsert) {
            Trigger.new[i].OwnerId = Trigger.new[i].Order_For_User_vod__c;
            if ((Trigger.new[i].Order_Status_vod__c == null) || (Trigger.new[i].Order_Status_vod__c == ''))
                Trigger.new[i].Order_Status_vod__c = 'Saved_vod';
            if (Trigger.isUpdate && !Trigger.old[i].Unlock_vod__c && Trigger.new[i].Unlock_vod__c) {
                //order is being unlocked
                Trigger.new[i].Order_Status_vod__c = 'Saved_vod';
                Trigger.new[i].Order_Submit_Date_vod__c = null;
                Trigger.new[i].Approved_Date_vod__c = null;
                Trigger.new[i].Approved_By_vod__c = null;
                Trigger.new[i].Approved_vod__c = false;
                Trigger.new[i].Unlock_vod__c = false;
                //after update trigger will fire to unlock the order lines
                VEEVA_PROCESS_FLAGS.setUpdateSIO(true);
            } else if (Trigger.isUpdate && !Trigger.old[i].Approved_vod__c && Trigger.new[i].Approved_vod__c) {
                //order is being approved
                Trigger.new[i].Order_Status_vod__c = 'Submitted_vod';
                Trigger.new[i].Approved_By_vod__c = UserInfo.getName();

                Datetime dt = System.now();
                Date approveDate = Date.newInstance(dt.year(), dt.month(), dt.day());
                Trigger.new[i].Approved_Date_vod__c = approveDate;
                //after update trigger will fire to approve the order lines
                VEEVA_PROCESS_FLAGS.setUpdateSIO(true);
            } else if ((Trigger.new[i].Order_Submit_Date_vod__c == null)
                         && ((Trigger.new[i].Order_Status_vod__c == 'Pending_Approval_vod') || (Trigger.new[i].Order_Status_vod__c == 'Submitted_vod'))) {
                //order is being submitted
                Datetime dt = System.now();
                Date submitDate = Date.newInstance(dt.year(), dt.month(), dt.day());
                Trigger.new[i].Order_Submit_Date_vod__c = submitDate;
                //after update trigger will fire to submit the order lines
                VEEVA_PROCESS_FLAGS.setUpdateSIO(true);
            } else if (Trigger.isUpdate && (Trigger.old[i].Order_Status_vod__c != 'Saved_vod') && (Trigger.old[i].Order_Status_vod__c != 'Canceled_vod')) {
                Trigger.new[i].addError('Order cannot be modified because of the Order Status.', false);
            }
        } else if (Trigger.isDelete) {
            if ((Trigger.old[i].Order_Status_vod__c != 'Saved_vod') && (Trigger.old[i].Order_Status_vod__c != 'Canceled_vod')) {
                String delErrMsg = VOD_GET_ERROR_MSG.getErrorMsg('ERROR_DELETING_ORDER_STATUS', 'InventoryOrder');
                Trigger.old[i].addError(delErrMsg, false);
            }
        }
    }
}