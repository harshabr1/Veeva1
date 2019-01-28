trigger VEEVA_BEFORE_ORDER_INSERT on Order_vod__c (before insert) {
    Set<Id> acctIDs = new Set<Id>();

    for (Order_vod__c orderNew : Trigger.new) {
        acctIds.add(orderNew.Account_vod__c);
        acctIds.add(orderNew.Entity_Reference_Id_vod__c);
    }

    Map<Id, Account> acctMap = new Map<id, Account>([SELECT Name FROM Account WHERE Id IN :acctIds]);

    for (Order_vod__c orderNew : Trigger.new) {
        if (orderNew.Override_Lock_vod__c)
            orderNew.Override_Lock_vod__c = false;
        if (orderNew.Status_vod__c == 'Submitted_vod') {
            orderNew.Lock_vod__c = true;
        }

        if (orderNew.Entity_Reference_Id_vod__c != null &&
            orderNew.Entity_Reference_Id_vod__c.length() > 0) {

            orderNew.Account_vod__c = orderNew.Entity_Reference_Id_vod__c;
            orderNew.Entity_Reference_Id_vod__c = null;
        }

        if(orderNew.Account_vod__c !=null){
            orderNew.Account_ID_vod__c = orderNew.Account_vod__c;
            orderNew.Account_Name_vod__c = acctMap.get(orderNew.Account_vod__c).Name;
        }
    }
}