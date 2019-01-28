trigger VOD_CONTRACT_PARTNER_BEFORE_DELETE on Contract_Partner_vod__c (before delete) {
    Map<Id, Set<Id>> contractToSpeakers = new Map<Id, Set<Id>>();
    Set<Id> speakerId = new Set<Id>();
    for (Contract_Partner_vod__c partner : Trigger.old) {
        if (partner.Contract_vod__c != null && partner.EM_Speaker_vod__c != null) {
            if (contractToSpeakers.get(partner.Contract_vod__c) == null) {
                contractToSpeakers.put(partner.Contract_vod__c, new Set<Id>());
            }
            contractToSpeakers.get(partner.Contract_vod__c).add(partner.EM_Speaker_vod__c);
            speakerId.add(partner.EM_Speaker_vod__c);
        }
    }

    Map<Id, Contract_Line_vod__c> lines = new Map<Id, Contract_Line_vod__c>([SELECT Id
                                                                             FROM Contract_Line_vod__c
                                                                             WHERE Service_vod__c != null AND Contract_vod__c IN : contractToSpeakers.keySet()]);
    List<EM_Speaker_Qualification_vod__c> qualifications = [SELECT Id, Speaker_vod__c, Contract_Line_vod__r.Contract_vod__c
                                                            FROM EM_Speaker_Qualification_vod__c
                                                            WHERE Contract_Line_vod__c IN : lines.keySet() AND Speaker_vod__c IN : speakerId];
    List<EM_Speaker_Qualification_vod__c> toDelete = new List<EM_Speaker_Qualification_vod__c>();
    for (EM_Speaker_Qualification_vod__c qualification : qualifications) {
        if (contractToSpeakers.get(qualification.Contract_Line_vod__r.Contract_vod__c).contains(qualification.Speaker_vod__c)) {
            toDelete.add(qualification);
        }
    }

    if (toDelete.size() > 0) {
        delete toDelete;
    }
}