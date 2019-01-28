trigger VEEVA_BEFORE_ORDER_LINE_INSERT on Order_Line_vod__c (before insert) {
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        if (Trigger.new[i].Override_Lock_vod__c)
            Trigger.new[i].Override_Lock_vod__c = false;
    }
}