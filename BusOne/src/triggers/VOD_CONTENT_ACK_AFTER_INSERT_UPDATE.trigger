trigger VOD_CONTENT_ACK_AFTER_INSERT_UPDATE on Content_Acknowledgement_vod__c (after insert, after update) {

    Set<String> completedIds = new Set<String>();
    for (Content_Acknowledgement_vod__c ack : Trigger.new) {
        if (ack.Status_vod__c == 'Completed_vod' || ack.Signature_Date_vod__c != null) {
            completedIds.add(String.valueOf(ack.Id) + ',Content_Acknowledgement_vod__c');
        }
    }

    List<Alert_vod__c> activeAlerts = [SELECT Expiration_Date_vod__c, Link_Reference_vod__c
                                       FROM Alert_vod__c
                                       WHERE Link_Reference_vod__c IN : completedIds AND Expiration_Date_vod__c >= TODAY];

    if(activeAlerts.size() < 1 ) {
        return;
    }

    String ackId = '';
    for (Alert_vod__c alert : activeAlerts) {
        ackId = alert.Link_Reference_vod__c.substringBefore(',');
        Content_Acknowledgement_vod__c ack = Trigger.newMap.get(ackId);
        if (ack.Signature_Date_vod__c != null) {
            alert.Expiration_Date_vod__c = ack.Signature_Date_vod__c;
        } else {
            alert.Expiration_Date_vod__c = Date.today();
        }
    }

    if (activeAlerts.size() > 0) {
        update activeAlerts;
    }
}