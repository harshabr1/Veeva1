trigger VOD_CONTRACT_AFTER_INSUPD on Contract_vod__c (after insert, after update) {
    List<EM_Speaker_Qualification_vod__c> qualifications = [SELECT Id, Contract_Status_vod__c, Contract_Line_vod__r.Contract_vod__c
                                                            FROM EM_Speaker_Qualification_vod__c
                                                            WHERE Contract_Line_vod__r.Contract_vod__c IN : Trigger.newMap.keySet()];
    for (EM_Speaker_Qualification_vod__c qualification : qualifications) {
        qualification.Contract_Status_vod__c = Trigger.newMap.get(qualification.Contract_Line_vod__r.Contract_vod__c).Status_vod__c;
    }
    if (qualifications.size() > 0) {
        update qualifications;
    }
}