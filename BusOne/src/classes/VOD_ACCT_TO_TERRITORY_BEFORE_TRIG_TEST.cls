@isTest
public class VOD_ACCT_TO_TERRITORY_BEFORE_TRIG_TEST{
    static testMethod void testInsert_TerritoryIsNull_ToAddTerritoryIsNull_TerritoryToDropIsNotNull() {
         
        String objId = insertTestObject('test001Z000000CCgk0IAD',null, null, ';Territory_0;');
        Account_Territory_Loader_vod__c inserted = [SELECT Id, Territory_vod__c, Territory_To_Add_vod__c, Territory_to_Drop_vod__c 
        FROM Account_Territory_Loader_vod__c  WHERE Id= :objId];
        System.assert(inserted != null);
        System.assertEquals(inserted.Territory_to_Drop_vod__c, null);
        System.assertEquals(inserted.Territory_vod__c, null);
    }
    static testMethod void testInsert_TerritoryIsNotNull_ToAddTerritoryIsNull_TerritoryToDropIsNotNull() {
         
        String objId = insertTestObject('test001Z000000CCgk0IAD',';Territory_15;Territory_0;', null, ';Territory_0;');
        Account_Territory_Loader_vod__c inserted = [SELECT Id, Territory_vod__c, Territory_To_Add_vod__c, Territory_to_Drop_vod__c 
        FROM Account_Territory_Loader_vod__c  WHERE Id= :objId];
        System.assert(inserted != null);
        System.assertEquals(inserted.Territory_to_Drop_vod__c, null);
        System.assertEquals(inserted.Territory_vod__c, ';Territory_15;');
    }
    static testMethod void testInsert_TerritoryIsNotNull_ToAddTerritoryOverlapWithTerritoryToDrop() {
         
        String objId = insertTestObject('test1001Z000000CCgk0IAD',';Territory_15;Territory_0;',';Territory_1;', 
                                        ';Territory_1;');
        Account_Territory_Loader_vod__c inserted = [SELECT Id, Territory_vod__c, Territory_To_Add_vod__c, Territory_to_Drop_vod__c 
        FROM Account_Territory_Loader_vod__c  WHERE Id= :objId];
        System.assert(inserted != null);
        System.assertEquals(inserted.Territory_to_Drop_vod__c, null);
        System.assertEquals(inserted.Territory_vod__c, ';Territory_15;Territory_0;');
        System.assertEquals(inserted.Territory_To_Add_vod__c, null);
    }
    static testMethod void testInsert_TerritoryOverlapWithTerritoryToDrop_ToAddTerritoryIsNotNull() {
         
        String objId = insertTestObject('test2001Z000000CCgk0IAD',';Territory_15;Territory_0;',';Territory_1;', 
                                        ';Territory_0;');
        Account_Territory_Loader_vod__c inserted = [SELECT Id, Territory_vod__c, Territory_To_Add_vod__c, Territory_to_Drop_vod__c 
        FROM Account_Territory_Loader_vod__c  WHERE Id= :objId];
        System.assert(inserted != null);
        System.assertEquals(inserted.Territory_to_Drop_vod__c, null);
        System.assertEquals(inserted.Territory_vod__c, ';Territory_15;Territory_1;');
        System.assertEquals(inserted.Territory_To_Add_vod__c, null);
    }
    private static String insertTestObject(String externalId, String territory, String territoryToAdd, String territoryToDrop)
    {
        Account_Territory_Loader_vod__c obj = new Account_Territory_Loader_vod__c(
            External_ID_vod__c = externalId,
            Territory_vod__c = territory,
            Territory_To_Add_vod__c = territoryToAdd, 
            Territory_to_Drop_vod__c = territoryToDrop
        ); 
        System.Test.startTest();
        insert obj; 
        System.Test.stopTest();
        return obj.Id;
    }

}