trigger VEEVA_NETWORK_MAPPING_BEFORE_UPSERT on Network_Mapping_vod__c (before insert, before update) {
    for(Network_Mapping_vod__c mapping : Trigger.new) {
        if (mapping.Active_vod__c) {
            // Sort countries for unique key.
            String[] countries = mapping.Country_vod__c.split(';',0);
            countries.sort();
            mapping.Unique_Key_vod__c = String.join(countries, ';');
            // Now look for inner duplicates
            String query = 'SELECT Id from Network_Mapping_vod__c WHERE Active_vod__c = TRUE';
            
            if (mapping.Id != null) {
                query += ' AND Id != \'' + mapping.Id + '\'';
            }
            if (mapping.External_ID_vod__c != null) {
                query += ' AND External_ID_vod__c != \'' + mapping.External_ID_vod__c + '\'';
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
            	mapping.Country_vod__c.addError('One or more countries conflict with existing active Network Mapping records.');    
            }
        } else {
            mapping.Unique_Key_vod__c = null;
        }
    }
}