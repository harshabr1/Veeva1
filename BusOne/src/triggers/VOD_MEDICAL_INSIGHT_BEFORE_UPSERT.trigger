trigger VOD_MEDICAL_INSIGHT_BEFORE_UPSERT on Medical_Insight_vod__c (before update, before insert) {
    String restrictedError = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('MEDICAL_INSIGHTS_RESTRICTED_WORDS_ERROR', 'Medical', '"{0}" is a restricted word or phrase in the {1} field that cannot be captured in a Key Medical Insight.');
    String restrictedWords = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('MEDICAL_INSIGHTS_RESTRICTED_WORDS', 'Medical', '');
    String summaryLabel = Medical_Insight_vod__c.Summary_vod__c.getDescribe().getLabel();
    String descriptionLabel = Medical_Insight_vod__c.Description_vod__c.getDescribe().getLabel();
    List<String> separatedWords = restrictedWords.split(';;');
    Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
    // check for the submitted error
    if (Trigger.isUpdate) {
        for (Medical_Insight_vod__c insight : Trigger.new) {
            Medical_Insight_vod__c oldInsight = Trigger.oldMap.get(insight.Id);
            if (insight.Override_Lock_vod__c == true) {
                insight.Override_Lock_vod__c = false;
                continue;        
            }       
            if (insight.Status_vod__c == 'Submitted_vod' && oldInsight.Status_vod__c == 'Submitted_vod') {
                insight.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('MEDICAL_INSIGHTS_NO_UPDATE_SUBMITTED', 'Medical', 'You may not update a submitted Key Medical Insight.'));
            }        
        }
    }
    for (Medical_Insight_vod__c insight : Trigger.new) {        
        if (vsc.MEDICAL_INSIGHTS_RESTRICTED_WORDS_vod__c && restrictedWords != '') {
            for (String restricted : separatedWords) {
                if (insight.Summary_vod__c != null && insight.Summary_vod__c.toLowerCase().contains(restricted.toLowerCase())) {
                    insight.addError(restrictedError.replace('{0}', restricted).replace('{1}', summaryLabel));
                    break;
                } else if (insight.Description_vod__c != null && insight.Description_vod__c.toLowerCase().contains(restricted.toLowerCase())) {
                    insight.addError(restrictedError.replace('{0}', restricted).replace('{1}', descriptionLabel));
                    break;
                }
            }
        }
        if (insight.Entity_Reference_Id_vod__c != null && insight.Entity_Reference_Id_vod__c != '') {
            insight.Account_vod__c = insight.Entity_Reference_Id_vod__c;
        }             
    }

}