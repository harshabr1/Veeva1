trigger VOD_HTML_REPORT_BEFORE_UPSERT on HTML_Report_vod__c (before insert, before update) {
    
    Set<String> profileIdsToQuery = new Set<String>();
    Set<String> profileNamesToQuery = new Set<String>();
    Map<String, String> profileIdsToNameMap = new Map<String, String>();
    Map<String, String> profileNamesToIdMap = new Map<String, String>();
    
    // Add either the Profile Id or Profile Name to the respective Set
    for(HTML_Report_vod__c report : Trigger.new) {
        if(report.Profile_vod__c != null) {
            profileIdsToQuery.add(report.Profile_vod__c);
        } else if(report.Profile_Name_vod__c != null) {
            profileNamesToQuery.add(report.Profile_Name_vod__c);
        }
    }
    
    // Querry for all Profiles by Id. Add them to the respective map
    if(!profileIdsToQuery.isEmpty()) {
        for(Profile profile : [SELECT Id, Name FROM Profile WHERE Id IN: profileIdsToQuery]) {
            profileIdsToNameMap.put(profile.Id, profile.Name);
        }    
    }
    
    // Query for all the Profiles by Name. Add them to the respective Map
    if(!profileNamesToQuery.isEmpty()) {
        for(Profile profile : [SELECT Id, Name FROM Profile WHERE Name IN: profileNamesToQuery]) {
            profileNamesToIdMap.put(profile.Name, profile.Id);
        }
    }
    
    // get the error message that need to be used
    
    List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='CANNOT_RESOLVE_PROFILE_ERROR' AND Category_vod__c='Alerts' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorText;
    if(messages.size() != 0){
        errorText = messages[0].Text_vod__c;
    } else { // default to english hardcoded
        errorText = 'Could not determine the Salesforce Profile associated with this record';    
    }

    
    for(HTML_Report_vod__c report : Trigger.new) {
        // If a Profile Id and Name are not supplied then continue.
        if(report.Profile_vod__c == null && report.Profile_Name_vod__c == null) {
            continue;
        }
        
        // Fetch the Profile Name from the map
        String profileName = profileIdsToNameMap.get(report.Profile_vod__c);
        if(profileName != null) {
            // Valid name. Set it here.
            report.Profile_Name_vod__c = profileName;    
        } else {
            // Could not find the Profile Name from the Id. User might have provided the Name instead.
            // Fetch the Profile Id from the map
            String profileId = profileNamesToIdMap.get(report.Profile_Name_vod__c);
            if(profileId == null) {
                // Could not find a valid Profile Id OR Name. Add an error. 
                report.Id.addError(errorText , false);
            } else {
                // Found the Profile Id
                report.Profile_vod__c = profileId;    
            }
        }
    }
	
	//check for duplicate records
	Map<String, HTML_Report_vod__c> newReports = new Map<String, HTML_Report_vod__c>();
    Set<Id> checkTypes = VOD_HTML_REPORT_TRIG.getDuplicateCheckRecordTypes();
    Set<String> checkProfiles = new Set<String>();
    Set<String> checkSharingGroups = new Set<String>();
    Set<String> checkObjRecTypes = new Set<String>();
    
	//check for duplicates within edited/created records
    for (HTML_Report_vod__c report : Trigger.new) {
        if (checkTypes.contains(report.RecordTypeId)) {
            String key = VOD_HTML_REPORT_TRIG.getCombinedId(report);
            HTML_Report_vod__c newUnique = newReports.get(key); 
            if (newUnique != null) {
				String message = VOD_GET_ERROR_MSG.getErrorMsg('SAVING_RECORD','COMMON');
                report.addError(message.replace('{0}', newUnique.Name));
            } else {
                newReports.put(key, report);
                checkProfiles.add(report.Profile_vod__c);
                checkSharingGroups.add(report.Sharing_Group_vod__c);
                checkObjRecTypes.add(report.Object_RecordType_Id_vod__c);
            }
        }
    }
    
	//check if there is an existing duplicate record in the database
    for (HTML_Report_vod__c existing : [SELECT Id, Name, RecordTypeId, Profile_vod__c, Sharing_Group_vod__c, Object_Recordtype_Id_vod__c
                                        FROM HTML_Report_vod__c
                                        WHERE RecordTypeId IN :checkTypes
                                        AND Profile_vod__c IN :checkProfiles
                                        AND Sharing_Group_vod__c IN :checkSharingGroups
                                        AND Object_RecordType_Id_vod__c IN :checkobjRecTypes]) {
        String key = VOD_HTML_REPORT_TRIG.getCombinedId(existing);
        HTML_Report_vod__c newRecord = newReports.get(key);
        if (newRecord != null && newRecord.Id != existing.Id) {
            String message = VOD_GET_ERROR_MSG.getErrorMsg('SAVING_RECORD','COMMON');
            newRecord.addError(message.replace('{0}', existing.Name));
		} 
    }
}