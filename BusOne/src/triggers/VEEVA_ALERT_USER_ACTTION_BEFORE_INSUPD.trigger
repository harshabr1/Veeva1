trigger VEEVA_ALERT_USER_ACTTION_BEFORE_INSUPD on Alert_User_Action_vod__c (before insert, before update) {
    for (Alert_User_Action_vod__c aua : Trigger.new) {
        aua.External_Id_vod__c = aua.Alert_vod__c + '__' + aua.User_vod__c;
    }
}