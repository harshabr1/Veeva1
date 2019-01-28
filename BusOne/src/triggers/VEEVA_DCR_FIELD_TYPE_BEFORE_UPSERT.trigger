trigger VEEVA_DCR_FIELD_TYPE_BEFORE_UPSERT on DCR_Field_Type_vod__c (before insert, before update) {
    Map<String,Profile> profileById = new Map<String, Profile>();
    for (DCR_Field_Type_vod__c record : Trigger.new) {
        String profileId = record.Profile_ID_vod__c;
        // Set profile name from provided ID
        if (String.isNotBlank(profileId)) {
            // check cache
        	Profile profile = profileById.get(profileId);
            if (profile == null) {
               profile = [SELECT Id,Name FROM Profile WHERE Id=:profileId];
            }
            if (profile != null) {
                // cache
                profileById.put(profileId, profile);
                // use
                record.Profile_Name_vod__c = profile.Name;
            }
        }
        // Sort countries for unique key.
        String[] countries = record.Country_vod__c.split(';',0);
        countries.sort();
        String countryStr = String.join(countries, ';');
        // set unique key, check for overflow now that Country_vod__c can be as long as unique key
        Schema.DescribeFieldResult uniqueDescribe = DCR_Field_Type_vod__c.Unique_Key_vod__c.getDescribe();
        Integer maxLength = uniqueDescribe.getLength();
        List<String> keyComponents = new String[] {
            record.Profile_Name_vod__c,record.Object_API_Name_vod__c,
            record.Record_Type_vod__c,record.Field_API_Name_vod__c};
        String keyComponentsStr = String.join(keyComponents,':');
        Integer totalLength = countryStr.length() + keyComponentsStr.length() + 1;
        if (totalLength > maxLength) {
            countryStr = countryStr.substring(0, maxLength-keyComponentsStr.length()-1);
        }
        record.Unique_Key_vod__c = countryStr + ':' + keyComponentsStr;        
        
        // Now look for country duplicates
        String query = 'SELECT Id from DCR_Field_Type_vod__c WHERE Profile_Name_vod__c = ' 
            + VOD_Utils.quotedOrNull(record.Profile_Name_vod__c)
            + ' AND Object_API_Name_vod__c = \'' + record.Object_API_Name_vod__c 
            + '\' AND Field_API_Name_vod__c = \'' + record.Field_API_Name_vod__c
            + '\' AND Record_Type_vod__c = ' 
            + VOD_Utils.quotedOrNull(record.Record_Type_vod__c);
        if (record.Id != null) {
            query += ' AND Id != \'' + record.Id + '\'';
        }
        if (record.External_ID_vod__c != null) {
            query += ' AND External_ID_vod__c != \'' + record.External_ID_vod__c + '\'';
        }
        query += ' AND (';
        boolean first = true;
        for (String country : countries) {
            if (first) {
                first = false;
                query += 'Country_vod__c LIKE \'%' + country + '%\'';
            } else {
                query += ' OR Country_vod__c LIKE \'%' + country + '%\'';
            }	    
        }
        query += ') LIMIT 1';
        List<SObject> conflicts = Database.query(query);
        if (conflicts.size() > 0) {
            record.Country_vod__c.addError('One or more countries conflict with an existing DCR Field Type record.');    
        }
    }
}