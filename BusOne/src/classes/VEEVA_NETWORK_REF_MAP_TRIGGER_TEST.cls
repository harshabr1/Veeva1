@isTest
private class VEEVA_NETWORK_REF_MAP_TRIGGER_TEST {

    private static String[] crmSpecialties = new String[]{'Oncology','General Practice','Family Practice',
        'Pathology','Pathology','Urology','Orthopedics'};
    private static String[] netSpecialties = new String[]{'ONCOLOGY','GP','GP','PATHOLOGY','RESEARCH','UROLOGY','ORTHOPEDICS'};
    private static String[] directions = new String[]{'Bidirectional_vod','Bidirectional_vod','Outbound_vod','Bidirectional_vod',
        'Inbound_vod','Bidirectional_vod','Bidirectional_vod'};
    private static String[] updateDirections = new String[]{'Outbound_vod','Outbound_vod','Bidirectional_vod','Inbound_vod',
        'Bidirectional_vod','Inbound_vod','Outbound_vod'};
        
    static testMethod void testInsert() {
        Network_Mapping_vod__c parent = new Network_Mapping_vod__c(Name='Test Parent Mapping',
                                                                   Country_vod__c='CA');
        insert parent;
        Network_Object_Mapping_vod__c objMap = new Network_Object_Mapping_vod__c(
            Network_Mapping_vod__c=parent.Id, Network_Object_API_Name_vod__c='hcp__v',
            CRM_Object_API_Name_vod__c='Account', External_ID_API_Name_vod__c='Dummy_Network_Id_vod__c');
        insert objMap;
        Network_Field_Mapping_vod__c fieldMap = new Network_Field_Mapping_vod__c(
            Network_Object_Mapping_vod__c=objMap.Id, CRM_Field_API_Name_vod__c='Specialty_vod__c',
            Network_Field_API_Name_vod__c='specialty__v');
        insert fieldMap;
        List<Network_Reference_Mapping_vod__c> refMaps = constructPicklistReferences(fieldMap);
        System.Test.startTest();
        insert refMaps;
	    System.Test.stopTest();
        verifyResults(refMaps, 1, directions);
    }
    
    static testMethod void testUpdate() {
        Network_Mapping_vod__c parent = new Network_Mapping_vod__c(Name='Test Parent Mapping',
                                                                   Country_vod__c='CA');
        insert parent;
        Network_Object_Mapping_vod__c objMap = new Network_Object_Mapping_vod__c(
            Network_Mapping_vod__c=parent.Id, Network_Object_API_Name_vod__c='hcp__v',
            CRM_Object_API_Name_vod__c='Account', External_ID_API_Name_vod__c='Dummy_Network_Id_vod__c');
        insert objMap;
        Network_Field_Mapping_vod__c fieldMap = new Network_Field_Mapping_vod__c(
            Network_Object_Mapping_vod__c=objMap.Id, CRM_Field_API_Name_vod__c='Specialty_vod__c',
            Network_Field_API_Name_vod__c='specialty__v');
        insert fieldMap;
        List<Network_Reference_Mapping_vod__c> refMaps = constructPicklistReferences(fieldMap);
        insert refMaps;
        System.Test.startTest();
        List<Network_Reference_Mapping_vod__c> updateMaps = new List<Network_Reference_Mapping_vod__c>();
        for (Integer i=0; i < refMaps.size(); i++) {
            Network_Reference_Mapping_vod__c oldValue = refMaps[i];
            Network_Reference_Mapping_vod__c updValue = 
                new Network_Reference_Mapping_vod__c(Id=oldValue.Id,
                                                     Direction_vod__c=updateDirections[i]);
            updateMaps.add(updValue);
        }
        update updateMaps;
        System.Test.stopTest();
        verifyResults(refMaps, 3, updateDirections);
    }
    
    private static List<Network_Reference_Mapping_vod__c> constructPicklistReferences(Network_Field_Mapping_vod__c fieldMap) {
        List<Network_Reference_Mapping_vod__c> refMaps = new List<Network_Reference_Mapping_vod__c>();
        Id picklistType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Network_Reference_Mapping_vod__c'
       					AND DeveloperName = 'Picklist_vod'].Id;
        for (Integer i=0; i < crmSpecialties.size(); i++) {
            Network_Reference_Mapping_vod__c refMap = new Network_Reference_Mapping_vod__c(RecordTypeId=picklistType,
                Network_Field_Mapping_vod__c=fieldMap.Id,Direction_vod__c=directions[i],
                CRM_Picklist_Value_vod__c=crmSpecialties[i],Network_Reference_Code_vod__c=netSpecialties[i]);
            refMaps.add(refMap);
        }
        return refMaps;
    }
    
    private static void verifyResults(List<Network_Reference_Mapping_vod__c> refMaps, Integer outCount, String[] directionArray) {
		List<Network_Reference_Mapping_vod__c> inserted = [SELECT Id, Network_Field_Mapping_vod__c,
                                                           Network_Reference_Code_vod__c,
                                                           Direction_vod__c,
                                                           Unique_Key_vod__c
                                                           FROM Network_Reference_Mapping_vod__c
                                                           WHERE Direction_vod__c IN ('Inbound_vod','Bidirectional_vod')
                                                           AND Id IN :refMaps];
        System.assertEquals(inserted.size(),directionArray.size() - outCount);
        for (Network_Reference_Mapping_vod__c mapping : inserted) {
            System.assert(String.isNotBlank(mapping.Unique_Key_vod__c));
            System.assert(mapping.Unique_Key_vod__c.contains(mapping.Network_Field_Mapping_vod__c));
            System.assert(mapping.Unique_Key_vod__c.contains(mapping.Network_Reference_Code_vod__c));
            System.assert(mapping.Unique_Key_vod__c.contains(mapping.Direction_vod__c));
        }
        inserted = [SELECT Id, Network_Field_Mapping_vod__c,Network_Reference_Code_vod__c,
                    Direction_vod__c,
                    CRM_Picklist_Value_vod__c,
                    CRM_Lookup_ID_vod__c,
                    CRM_Record_Type_Name_vod__c,
                    Unique_Key_vod__c
                    FROM Network_Reference_Mapping_vod__c
                    WHERE Direction_vod__c ='Outbound_vod'
                    AND Id IN :refMaps];
        System.assertEquals(inserted.size(),outCount);
        for (Network_Reference_Mapping_vod__c mapping : inserted) {
            System.assert(String.isNotBlank(mapping.Unique_Key_vod__c));
            System.assert(mapping.Unique_Key_vod__c.contains(mapping.Network_Field_Mapping_vod__c));
            if (String.isNotBlank(mapping.CRM_Picklist_Value_vod__c)) {
                System.assert(mapping.Unique_Key_vod__c.contains(mapping.CRM_Picklist_Value_vod__c));
            }
            if (String.isNotBlank(mapping.CRM_Lookup_ID_vod__c)) {
            	System.assert(mapping.Unique_Key_vod__c.contains(mapping.CRM_Lookup_ID_vod__c));
            }
            if (String.isNotBlank(mapping.CRM_Record_Type_Name_vod__c)) {
                System.assert(mapping.Unique_Key_vod__c.contains(mapping.CRM_Record_Type_Name_vod__c));
            }
            
            System.assert(mapping.Unique_Key_vod__c.contains(mapping.CRM_Picklist_Value_vod__c));
            System.assert(mapping.Unique_Key_vod__c.contains(mapping.Direction_vod__c));
        }
    }
}