trigger VOD_EVENT_CONFIG_COUNTRY_DUPLICATE on EM_Event_Configuration_Country_vod__c (after insert, after update) {
    Map<String, String> countryConfigToConfig = new Map<String, String>();
    Map<String, Date> configToStart = new Map<String, Date>();
    Map<String, Date> configToEnd = new Map<String, Date>();
    Map<String, String> configToType = new Map<String, String>();
    Set<String> configs = new Set<String>();

    List<EM_Event_Configuration_Country_vod__c> configCountries = [ SELECT Id, Country_vod__c, Event_Configuration_vod__c
                                                                    FROM EM_Event_Configuration_Country_vod__c ];
    for (EM_Event_Configuration_Country_vod__c configCountry : configCountries) {
        countryConfigToConfig.put(configCountry.Id, configCountry.Event_Configuration_vod__c);
    }

    for (EM_Event_Configuration_vod__c config : [ SELECT Id, Start_Date_vod__c, End_Date_vod__c, Event_Type_vod__c
                                                  FROM EM_Event_Configuration_vod__c ]) {
        configToStart.put(config.Id, config.Start_Date_vod__c);
        configToEnd.put(config.Id, config.End_Date_vod__c);
        configToType.put(config.Id, config.Event_Type_vod__c);
    }

    for (EM_Event_Configuration_Country_vod__c configCountry : Trigger.new) {
        // We want to compare the upsert objects to the newest versions of EM_Event_Configuration_Country_vod
        // so we need to override what is already in the database
        countryConfigToConfig.put(configCountry.Id, configCountry.Event_Configuration_vod__c);
        configs.add(configCountry.Event_Configuration_vod__c);
    }

    for (EM_Event_Configuration_vod__c config : [ SELECT Id, Start_Date_vod__c, End_Date_vod__c, Event_Type_vod__c
                                                  FROM EM_Event_Configuration_vod__c
                                                  WHERE Id IN :configs ]) {
        // We want to compare the upsert objects to the newest versions of EM_Event_Configuration_vod
        // so we need to override what is already in the database
        configToStart.put(config.Id, config.Start_Date_vod__c);
        configToEnd.put(config.Id, config.End_Date_vod__c);
        configToType.put(config.Id, config.Event_Type_vod__c);
    }

    for (EM_Event_Configuration_Country_vod__c configCountry1 : Trigger.new) {
        for (EM_Event_Configuration_Country_vod__c configCountry2 : configCountries) {
            if (configCountry1.Id.equals(configCountry2.Id) ||
                (configCountry1.Country_vod__c == null && configCountry2.Country_vod__c != null) ||
                !configCountry1.Country_vod__c.equals(configCountry2.Country_vod__c)) {
                continue;
            }
            String id1 = countryConfigToConfig.get(configCountry1.Id);
            String id2 = countryConfigToConfig.get(configCountry2.Id);
            if ((id1 == null && id2 == null) || (id1 != null && id1.equals(id2)) ||
                (VOD_Utils.isValueSame(configToType, id1, id2) &&
                 configToStart.get(id1) != null && configToStart.get(id2) != null &&
                 configToStart.get(id1).daysBetween(configToEnd.get(id2)) >= 0 &&
                 configToStart.get(id2).daysBetween(configToEnd.get(id1)) >= 0)) {
                configCountry1.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_CONFIG_ERROR', 'TriggerError',
                                                                                 'Duplicate Configuration Error'));
            }
        }
    }
}