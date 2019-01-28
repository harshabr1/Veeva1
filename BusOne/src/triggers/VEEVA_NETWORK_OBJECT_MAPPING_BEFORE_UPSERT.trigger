trigger VEEVA_NETWORK_OBJECT_MAPPING_BEFORE_UPSERT on Network_Object_Mapping_vod__c (before insert, before update) {
    for (Network_Object_Mapping_vod__c mapping : Trigger.new) {
        List<String> keyValues = new List<String>{mapping.Network_Mapping_vod__c,mapping.Network_Object_API_Name_vod__c,
            mapping.CRM_Object_API_Name_vod__c};
        mapping.Unique_Key_vod__c = String.join(keyValues,':');
    }
}