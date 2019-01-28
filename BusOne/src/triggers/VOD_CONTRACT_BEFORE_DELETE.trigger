trigger VOD_CONTRACT_BEFORE_DELETE on Contract_vod__c (before delete) {
    VEEVA_CONTRACT_HEADER_CLASS.setFromContractBeforeTrigger(true);
    List<Contract_Partner_vod__c> partners = [SELECT Id
                                              FROM Contract_Partner_vod__c
                                              WHERE Contract_vod__c IN : Trigger.oldMap.keySet()];
    List<Contract_Line_vod__c> lines = [SELECT Id
                                        FROM Contract_Line_vod__c
                                        WHERE Contract_vod__c IN : Trigger.oldMap.keySet()];
    if (partners.size() > 0) {
        delete partners;
    }
    if (lines.size() > 0) {
        delete lines;
    }
}