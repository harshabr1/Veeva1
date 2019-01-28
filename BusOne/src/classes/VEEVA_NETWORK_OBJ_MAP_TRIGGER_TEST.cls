@isTest
private class VEEVA_NETWORK_OBJ_MAP_TRIGGER_TEST {
    private static String[] networkObjects = new String[]{'hco__v','hcp__v','addresses__v',
        'licenses__v','parentHCO__v'};
    private static String[] crmObjects = new String[]{'Account','Account','Address_vod__c',
        'Address_vod__c','ChildAccount_vod__c'};
            
    static testMethod void testInsert() {
        Network_Mapping_vod__c parent = new Network_Mapping_vod__c(Name='Test Parent Mapping',
                                                                   Country_vod__c='CN');
        insert parent;
        List<Network_Object_Mapping_vod__c> mappings = new List<Network_Object_Mapping_vod__c>();
        for (Integer i=0; i < networkObjects.size(); i++) {
            String networkObject = networkObjects[i];
            String crmObject = crmObjects[i];
            Network_Object_Mapping_vod__c objMap = new Network_Object_Mapping_vod__c(
                Network_Mapping_vod__c=parent.Id,Network_Object_API_Name_vod__c=networkObject,
                CRM_Object_API_Name_vod__c=crmObject,External_ID_API_Name_vod__c='Dummy_Field_Name_vod__c');
            mappings.add(objMap);
        }
        System.Test.startTest();
        insert mappings;
        System.Test.stopTest();
        List<Network_Object_Mapping_vod__c> inserted = [SELECT Id, Network_Mapping_vod__c,
                                                        Network_Object_API_Name_vod__c,
                                                        CRM_Object_API_Name_vod__c,
                                                        Unique_Key_vod__c
                                                FROM Network_Object_Mapping_vod__c
                                                WHERE Id IN :mappings];
        System.assertEquals(inserted.size(), networkObjects.size());
        for (Network_Object_Mapping_vod__c mapping : inserted) {
            System.assert(String.isNotBlank(mapping.Unique_Key_vod__c));
            System.assert(mapping.Unique_Key_vod__c.contains(mapping.Network_Mapping_vod__c));
            System.assert(mapping.Unique_Key_vod__c.contains(mapping.Network_Object_API_Name_vod__c));
            System.assert(mapping.Unique_Key_vod__c.contains(mapping.CRM_Object_API_Name_vod__c));
        }
    }
    
    static testMethod void testUpdate() {
        Network_Mapping_vod__c parent = new Network_Mapping_vod__c(Name='Test Parent Mapping',
                                                                   Country_vod__c='CN');
        insert parent;
        Network_Object_Mapping_vod__c objMap = new Network_Object_Mapping_vod__c(
            Network_Mapping_vod__c=parent.Id,Network_Object_API_Name_vod__c='hcp__v',
            CRM_Object_API_Name_vod__c='Account',External_ID_API_Name_vod__c='Dummy_Network_Id_vod__c',
            Person_Account_vod__c=true);
        insert objMap;
        System.Test.startTest();
        Network_Object_Mapping_vod__c updateMap = new Network_Object_Mapping_vod__c(Id=objMap.Id,
                                                                                   Network_Object_API_Name_vod__c='hco__v');
        update updateMap;
        System.Test.stopTest();
        List<Network_Object_Mapping_vod__c> queryList = [SELECT Id, Network_Mapping_vod__c,
                                                        Network_Object_API_Name_vod__c,
                                                        CRM_Object_API_Name_vod__c,
                                                        Unique_Key_vod__c
                                                FROM Network_Object_Mapping_vod__c
                                                WHERE Id=:objMap.Id];
        System.assertEquals(queryList.size(), 1);
        Network_Object_Mapping_vod__c updated = queryList[0];
        System.assertEquals(updated.Network_Object_API_Name_vod__c, 'hco__v');
        System.assert(String.isNotBlank(updated.Unique_Key_vod__c));
        System.assert(updated.Unique_Key_vod__c.contains(updated.Network_Mapping_vod__c));
        System.assert(updated.Unique_Key_vod__c.contains(updated.Network_Object_API_Name_vod__c));
        System.assert(updated.Unique_Key_vod__c.contains(updated.CRM_Object_API_Name_vod__c));
    }
}