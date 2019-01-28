trigger Sample_Inventory_Items_Before_vod on Sample_Inventory_Item_vod__c (before delete, before update) {
    List<Sample_Inventory_Item_vod__c> modified;
    if(Trigger.isDelete) {
        modified = Trigger.old;
    } else {
        modified = Trigger.new;
    }

    Map <Id, Sample_Inventory_Item_vod__c> invMap = new Map <Id,Sample_Inventory_Item_vod__c> (
        [Select Id, Inventory_Name_vod__r.Status_vod__c From Sample_Inventory_Item_vod__c
        where Id in :modified]);

    for (Integer i = 0; i < modified.size(); i++ ) {
        Sample_Inventory_Item_vod__c invItem = invMap.get(modified[i].Id);

        if (invItem.Inventory_Name_vod__r.Status_vod__c == 'Submitted_vod') {
            modified[i].Id.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_SAMP_INV','TriggerError'), false);
        }
    }
}