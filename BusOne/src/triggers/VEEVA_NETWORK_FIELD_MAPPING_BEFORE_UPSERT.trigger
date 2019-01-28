trigger VEEVA_NETWORK_FIELD_MAPPING_BEFORE_UPSERT on Network_Field_Mapping_vod__c (before insert, before update) {
    for (Network_Field_Mapping_vod__c mapping : Trigger.new) {
        List<String> keyValues = new List<String>{mapping.Network_Object_Mapping_vod__c,
            mapping.Network_Field_API_Name_vod__c};
        mapping.Unique_Key_vod__c = String.join(keyValues,':');
    }
}