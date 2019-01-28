trigger VEEVA_BEFORE_SURVEY_TARGET_DELETE on Survey_Target_vod__c (before delete) {
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    if (vsc ==  null || vsc.CALL_ARCHIVE_USER_vod__c != UserInfo.getUserName()){
        for (Survey_Target_vod__c target : Trigger.old){
            if (target.status_vod__c == 'Submitted_vod' || target.status_vod__c == 'Late_Submission_vod'){
                target.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_DEL_SURVEY_TARGET','Surveys'), false);
            }
        }
    }
}