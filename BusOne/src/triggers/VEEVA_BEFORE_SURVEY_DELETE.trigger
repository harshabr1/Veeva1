trigger VEEVA_BEFORE_SURVEY_DELETE on Survey_vod__c (before delete) {
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    if (vsc.CALL_ARCHIVE_USER_vod__c != UserInfo.getUserName()){
        for (Survey_vod__c survey : Trigger.old){
            if (survey.status_vod__c == 'Published_vod'){
                survey.addError(VOD_GET_ERROR_MSG.getErrorMsg('SURVEY_LOCK_ERROR','Surveys'));
            }
        }
    }
}