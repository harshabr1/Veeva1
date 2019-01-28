trigger VOD_EM_EVENT_LAYOUT_BEFORE_INS_UPD on EM_Event_Layout_vod__c (before insert, before update) {
    
	List<Profile> profileMap;
    
    for(EM_Event_Layout_vod__c layout: trigger.new) {
        boolean updateName = false;
        if(trigger.isUpdate) {
     		EM_Event_Layout_vod__c oldLayout = trigger.oldMap.get(layout.Id);
            if(oldLayout.User_Profile_vod__c != layout.User_Profile_vod__c || layout.User_Profile_Id_vod__c == null) {
                updateName = true;
            }
        }
        
        if(trigger.IsInsert || updateName) {
            if(profileMap == null) {
                profileMap = [SELECT Id, Name FROM Profile];
        	}

        	boolean hasMatch = false;

            for(Profile profile: profileMap) {
                if(profile.Name == layout.User_Profile_vod__c) {
                    layout.User_Profile_Id_vod__c = profile.Id;
                    hasMatch = true;
                    break;
                }
            }

            if(!hasMatch) {
                layout.User_Profile_Id_vod__c = null;
            }
        }
	} 
}