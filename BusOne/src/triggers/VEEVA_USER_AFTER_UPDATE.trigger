trigger VEEVA_USER_AFTER_UPDATE on User (after update) {
    if (trigger.isAfter && trigger.isUpdate) {
        List<Id> userIds = new List<Id>();
        // Handle for deactived User
        for (User user : Trigger.new) {
            //User oldUser = Trigger.oldMap.get(user.Id);
            if(user.IsActive == false || user.Mobile_CRM_App_Access_Disabled_vod__c == true) {
                // When user is deactivated
                userIds.add(user.Id);
            }
        }
        if(!userIds.isEmpty()) {
            // Insert with @future method
            VOD_MobileDeviceUtils.modifyMobileDeviceRecords(userIds);
        }
    }   
}