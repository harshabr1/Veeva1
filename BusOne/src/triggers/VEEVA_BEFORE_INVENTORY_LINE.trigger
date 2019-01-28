trigger VEEVA_BEFORE_INVENTORY_LINE on Inventory_Monitoring_Line_vod__c (before delete, before update) {

	boolean modAllData = VOD_Utils.canModifyAllData();
		                
    for (Integer i = 0; i < Trigger.old.size(); i++) {
        if (Trigger.old[i].Inventory_Monitoring_vod__r.Lock_vod__c == true && !modAllData) {
                Trigger.new[i].Id.addError(System.Label.NO_MODIFY_INVENTORY_MONITORING, false);
        }
    }
}