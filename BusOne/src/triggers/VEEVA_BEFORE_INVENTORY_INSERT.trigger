trigger VEEVA_BEFORE_INVENTORY_INSERT on Inventory_Monitoring_vod__c (before insert) {

Set<Id> acctIDs = new Set<Id>();

for (Inventory_Monitoring_vod__c invNew : Trigger.new) {
	acctIds.add(invNew.Account_vod__c);
	acctIds.add(invNew.Entity_Reference_Id_vod__c);
}

Map<Id, Account> acctMap = new Map<id, Account>([SELECT Name FROM Account WHERE Id IN :acctIds]);

for (Integer i = 0; i <Trigger.new.size(); i++) {
        Inventory_Monitoring_vod__c  recNew = Trigger.new[i];
        if (recNew.Status_vod__c == 'Submitted_vod') {
            recNew.Lock_vod__c = true;    
        }
                
        if (recNew.Entity_Reference_Id_vod__c != null && 
            recNew.Entity_Reference_Id_vod__c.length() > 0) {
            
            recNew.Account_vod__c = recNew.Entity_Reference_Id_vod__c;
            recNew.Entity_Reference_Id_vod__c = null;
                
        }

        if(recNew.Account_vod__c != null){
            recNew.Account_ID_vod__c = recNew.Account_vod__c;
            recNew.Account_Name_vod__c = acctMap.get(recNew.Account_vod__c).Name;
        }
    }
}