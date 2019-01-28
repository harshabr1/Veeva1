trigger VEEVA_ALERT_PROFILE_BEFORE_INSUPD on Alert_Profile_vod__c (before insert, before update) {
    
      
    Map<String, String> profileIdMap = new Map<String, String> ();
    Map<String, String> profileNameMap = new Map<String, String> ();
    for(Profile profile: [Select Id, Name FROM Profile]) 
    {
        profileIdMap.put(profile.Id, profile.Name);
        profileNameMap.put(profile.Name, profile.Id);
        
    }   
    
    List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='CANNOT_RESOLVE_PROFILE_ERROR' AND Category_vod__c='Alerts' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorText;
    if(messages.size() != 0){
        errorText = messages[0].Text_vod__c;
    } else { // default to english hardcoded
        errorText = 'Could not determine the Salesforce Profile associated with this record';    
    }
    for (Alert_Profile_vod__c ap : Trigger.new) {        
        // now check the profile id field and profile name feild to do the copying
        if (ap.Profile_vod__c != null ) { // profile id is not null
            // check if its valid id or not
            if (profileIdMap.get(ap.Profile_vod__c) != null) {
                ap.Profile_Name_vod__c =  profileIdMap.get(ap.Profile_vod__c);  
            } else if (ap.Profile_Name_vod__c != null && profileNameMap.get(ap.Profile_Name_vod__c) != null) {
                ap.Profile_vod__c   =  profileNameMap.get(ap.Profile_Name_vod__c);    
            } else { // both id and name is null throw an error
                ap.addError(errorText , false);
            }
        } else if (ap.Profile_Name_vod__c != null && profileNameMap.get(ap.Profile_Name_vod__c) != null) { // profile id is null in this case so check the name is not null and valid
             ap.Profile_vod__c   =  profileNameMap.get(ap.Profile_Name_vod__c);
        } else { // both id and name is null throw an error
             ap.addError(errorText , false);
        }
        // add the external id
        ap.External_Id_vod__c = ap.Alert_vod__c + '__' + ap.Profile_vod__c;
    }
}