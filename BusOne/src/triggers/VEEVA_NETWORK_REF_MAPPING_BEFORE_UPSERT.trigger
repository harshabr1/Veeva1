trigger VEEVA_NETWORK_REF_MAPPING_BEFORE_UPSERT on Network_Reference_Mapping_vod__c (before insert, before update) {
    for (Network_Reference_Mapping_vod__c mapping : Trigger.new) {
        List<String> keyValues = new List<String>{mapping.Network_Field_Mapping_vod__c, mapping.Direction_vod__c};
        if (mapping.Direction_vod__c == 'Bidirectional_vod' || mapping.Direction_vod__c == 'Inbound_vod') {
            keyValues.add(mapping.Network_Reference_Code_vod__c);
        } else {
            keyValues.add(mapping.CRM_Lookup_ID_vod__c);
            keyValues.add(mapping.CRM_Picklist_Value_vod__c);
            keyValues.add(mapping.CRM_Record_Type_Name_vod__c);
        }	
        mapping.Unique_Key_vod__c = String.join(keyValues,':');
    }
}