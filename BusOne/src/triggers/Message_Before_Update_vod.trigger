trigger Message_Before_Update_vod on Message_vod__c (before update) {
    String message = VOD_GET_ERROR_MSG.getErrorMsg('ENFORCE_VEEVA_SETTINGS', 'Common');
    for (Integer i = 0; i < Trigger.old.size(); i++) {
        if (((Trigger.old[i].Type_vod__c == 'Config_vod') || (Trigger.old[i].Type_vod__c == 'Custom_Setting_vod')) && (Trigger.new[i].Type_vod__c != 'Custom_Setting_vod'))
            Trigger.new[i].Type_vod__c.addError(message, false);
    }
}