trigger VOD_TSF_BEFORE_TRIGGER on TSF_vod__c (before insert, before update) {
    for (TSF_vod__c tsf: Trigger.new) {
        tsf.External_Id_vod__c = tsf.Account_vod__c +'__' + tsf.Territory_vod__c;
    }

}