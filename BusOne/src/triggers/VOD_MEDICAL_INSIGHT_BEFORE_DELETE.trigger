trigger VOD_MEDICAL_INSIGHT_BEFORE_DELETE on Medical_Insight_vod__c (before delete) {
    for (Medical_Insight_vod__c insight : Trigger.old) {
        if (insight.Status_vod__c == 'Submitted_vod' && !insight.Override_Lock_vod__c) {
            insight.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('MEDICAL_INSIGHTS_NO_DELETE_SUBMITTED', 'Medical', 'You may not delete a submitted Key Medical Insight.'));
        }
    }
}