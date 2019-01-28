@isTest
private class VEEVA_NETWORK_FLD_MAP_TRIGGER_TEST {

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
        System.Test.startTest();
        insert fieldMap;
	System.Test.stopTest();
        List<Network_Field_Mapping_vod__c> queryList = [SELECT Id, Network_Object_Mapping_vod__c,
                                                       Network_Field_API_Name_vod__c, Unique_Key_vod__c
                                                       FROM Network_Field_Mapping_vod__c
                                                       WHERE Id=:fieldMap.Id];
        System.assertEquals(queryList.size(), 1);
        Network_Field_Mapping_vod__c inserted = queryList[0];
        System.assert(String.isNotBlank(inserted.Unique_Key_vod__c));
        System.assert(inserted.Unique_Key_vod__c.contains(inserted.Network_Object_Mapping_vod__c));
        System.assert(inserted.Unique_Key_vod__c.contains(inserted.Network_Field_API_Name_vod__c));
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
        System.Test.startTest();
        Network_Field_Mapping_vod__c updateMap = new Network_Field_Mapping_vod__c(Id=fieldMap.Id,
                                                                                  Network_Field_API_Name_vod__c='hcp_specialty__v');
        update updateMap;
	System.Test.stopTest();
        List<Network_Field_Mapping_vod__c> queryList = [SELECT Id, Network_Object_Mapping_vod__c,
                                                       Network_Field_API_Name_vod__c, Unique_Key_vod__c
                                                       FROM Network_Field_Mapping_vod__c
                                                       WHERE Id=:fieldMap.Id];
        System.assertEquals(queryList.size(), 1);
        Network_Field_Mapping_vod__c updated = queryList[0];
        System.assert(String.isNotBlank(updated.Unique_Key_vod__c));
        System.assert(updated.Unique_Key_vod__c.contains(updated.Network_Object_Mapping_vod__c));
        System.assert(updated.Unique_Key_vod__c.contains(updated.Network_Field_API_Name_vod__c));
    }
}