trigger VEEVA_BEFORE_INVENTORY_DELETE on Inventory_Monitoring_vod__c (before delete) {
        
        for (Integer i = 0; i <Trigger.old.size(); i++) {
            Inventory_Monitoring_vod__c old = Trigger.old[i];
        
            if (old.Lock_vod__c == true) {
                old.Id.addError(System.Label.NO_MODIFY_INVENTORY_MONITORING, false);
            }               
        }
}