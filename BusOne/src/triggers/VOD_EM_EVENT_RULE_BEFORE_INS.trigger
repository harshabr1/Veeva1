trigger VOD_EM_EVENT_RULE_BEFORE_INS on EM_Event_Rule_vod__c (before insert) {
    Set<String> materials = new Set<String>();
    Set<String> documents = new Set<String>();
    for (EM_Event_Rule_vod__c rule : Trigger.new) {
        if (rule.Material_vod__c != null) {
            materials.add(rule.Material_vod__c);
        } else if (rule.Email_Template_vod__c != null) {
        	documents.add(rule.Email_Template_vod__c);    
        } 
    }

    Map<Id, EM_Catalog_vod__c> catalog = new Map<Id, EM_Catalog_vod__c>([SELECT Id, RecordType.Name
                                                                         FROM EM_Catalog_vod__c WHERE Id IN : materials]);
    Map<Id, Approved_Document_vod__c> documentMap = new Map<Id, Approved_Document_vod__c>([SELECT Id, RecordType.Name
                                                                         FROM Approved_Document_vod__c WHERE Id IN : documents]);
    for (EM_Event_Rule_vod__c rule : Trigger.new) {
        if (rule.Material_vod__c != null && catalog.get(rule.Material_vod__c) != null) {
            rule.Material_Type_vod__c = catalog.get(rule.Material_vod__c).RecordType.Name;
        } else if (rule.Email_Template_vod__c != null && documentMap.get(rule.Email_Template_vod__c) != null) {
            rule.Material_Type_vod__c = documentMap.get(rule.Email_Template_vod__c).RecordType.Name;
        }
    }
}