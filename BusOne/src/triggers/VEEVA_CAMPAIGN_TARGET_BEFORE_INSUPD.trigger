trigger VEEVA_CAMPAIGN_TARGET_BEFORE_INSUPD on Campaign_Target_vod__c (before insert, before update) {
  for (Campaign_Target_vod__c ct: Trigger.new) {
        ct.External_Id_vod__c = ct.Campaign_vod__c +'__' + ct.Target_Account_vod__c;
    }
 

}