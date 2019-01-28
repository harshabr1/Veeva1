trigger VOD_EM_TOPIC_MATERIAL_BEFORE_INS on EM_Topic_Material_vod__c (before insert) {
    Set<String> materials = new Set<String>();
    Set<String> documents = new Set<String>();
    for (EM_Topic_Material_vod__c topic : Trigger.new) {
        if (topic.Material_vod__c != null) {
            materials.add(topic.Material_vod__c);
        } else if (topic.Email_Template_vod__c != null) {
            documents.add(topic.Email_Template_vod__c);
        } 
    }

    Map<Id, EM_Catalog_vod__c> catalog = new Map<Id, EM_Catalog_vod__c>([SELECT Id, RecordType.Name
                                                                         FROM EM_Catalog_vod__c WHERE Id IN : materials]);
    Map<Id, Approved_Document_vod__c> documentMap = new Map<Id, Approved_Document_vod__c>([SELECT Id, RecordType.Name
                                                                         FROM Approved_Document_vod__c WHERE Id IN : documents]);
    for (EM_Topic_Material_vod__c topic : Trigger.new) {
        if (topic.Material_vod__c != null && catalog.get(topic.Material_vod__c) != null) {
            topic.Material_Type_vod__c = catalog.get(topic.Material_vod__c).RecordType.Name;
        } else if (topic.Email_Template_vod__c != null && documentMap.get(topic.Email_Template_vod__c) != null) {
            topic.Material_Type_vod__c = documentMap.get(topic.Email_Template_vod__c).RecordType.Name;
        }
    }
}