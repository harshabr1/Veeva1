trigger VOD_CONTRACT_LINE_BEFORE_DELETE on Contract_Line_vod__c (before delete) {
    List<EM_Speaker_Qualification_vod__c> qualifications = [SELECT Id
                                                            FROM EM_Speaker_Qualification_vod__c
                                                            WHERE Contract_Line_vod__c IN : Trigger.oldMap.keySet()];
    if (qualifications.size() > 0) {
        delete qualifications;
    }
}