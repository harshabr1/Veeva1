trigger VOD_EVENT_LAYOUT_DUPLICATE on EM_Event_Layout_vod__c (after insert, after update) {
    Map<String, String> idToConfig = new Map<String, String>();
    Map<String, String> idToProfile = new Map<String, String>();
    Map<String, String> idToRole = new Map<String, String>();
    Map<String, String> idToStatus = new Map<String, String>();
    Map<String, String> idToCountry = new Map<String, String>();
    Map<String, String> idToRecordType = new Map<String, String>();
    Map<String, String> idToEventObject = new Map<String, String>();
    Map<String, String> idToObjectRT = new Map<String, String>();

    List<EM_Event_Layout_vod__c> layouts = [ SELECT Id, RecordType.DeveloperName, Event_Object_Name_vod__c, Record_Type_vod__c,
                                                    Event_Configuration_vod__c, User_Profile_vod__c, Event_Team_Role_vod__c,
                                                    Event_Status_vod__c, Country_Override_vod__c
                                             FROM   EM_Event_Layout_vod__c ];

    for (EM_Event_Layout_vod__c layout : layouts) {
        idToConfig.put(layout.Id, layout.Event_Configuration_vod__c);
        idToProfile.put(layout.Id, layout.User_Profile_vod__c);
        idToRole.put(layout.Id, layout.Event_Team_Role_vod__c);
        idToStatus.put(layout.Id, layout.Event_Status_vod__c);
        idToCountry.put(layout.Id, layout.Country_Override_vod__c);
        idToRecordType.put(layout.Id, layout.RecordType.DeveloperName);
        idToEventObject.put(layout.Id, layout.Event_Object_Name_vod__c);
        idToObjectRT.put(layout.Id, layout.Record_Type_vod__c);
    }

    /* After Insert */
    /* After Update */
    for (EM_Event_Layout_vod__c layout : Trigger.new) {
        // We want to compare the upsert objects to the newest versions of EM_Event_Layout_vod
        // so we need to override what is already in the database
        idToConfig.put(layout.Id, layout.Event_Configuration_vod__c);
        idToProfile.put(layout.Id, layout.User_Profile_vod__c);
        idToRole.put(layout.Id, layout.Event_Team_Role_vod__c);
        idToStatus.put(layout.Id, layout.Event_Status_vod__c);
        idToCountry.put(layout.Id, layout.Country_Override_vod__c);
        idToRecordType.put(layout.Id, layout.RecordType.DeveloperName);
        idToEventObject.put(layout.Id, layout.Event_Object_Name_vod__c);
        idToObjectRT.put(layout.Id, layout.Record_Type_vod__c);
    }

    // For each newly created layout, check if it's a duplicate
    for (EM_Event_Layout_vod__c layout1 : Trigger.new) {
        for (EM_Event_Layout_vod__c layout2 : layouts) {
            if (!layout1.Id.equals(layout2.Id) &&
                VOD_Utils.isValueSame(idToConfig, layout1.Id, layout2.Id) &&
                VOD_Utils.isValueSame(idToEventObject, layout1.Id, layout2.Id) &&
                VOD_Utils.isValueSame(idToObjectRT, layout1.Id, layout2.Id) &&
                VOD_Utils.isValueSame(idToProfile, layout1.Id, layout2.Id) &&
                VOD_Utils.isValueSame(idToRole, layout1.Id, layout2.Id) &&
                VOD_Utils.isValueSame(idToStatus, layout1.Id, layout2.Id) &&
                VOD_Utils.isValueSame(idToCountry, layout1.Id, layout2.Id)) {
                layout1.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_CONFIG_ERROR', 'TriggerError',
                                                                          'Duplicate Configuration Error'));
            }
        }
    }
}