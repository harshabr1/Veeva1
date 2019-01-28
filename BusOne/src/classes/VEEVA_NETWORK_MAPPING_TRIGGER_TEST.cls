@isTest
private class VEEVA_NETWORK_MAPPING_TRIGGER_TEST {
    private static String[] countries = new String[]{'AF','AL','AR','AM','AU','AT','BE','BO','BY','CA','CN',
        'CR','CZ','DK','EC','ER','EE','ET','FI','FR','GA','GB','GD','GU','HK','HU','IS','IN','IE','IL','IT',
        'JP','KE','KP','KW','LV','LR','LI','LT','LU','MG','MY','MX','MZ','NL','NP','NZ','NE','NO','OM','PS',
        'PA','PL','PT','PR','QA','RO','RU','RW','SA','RS','SG','TW','TJ','TH','TR','TN','UA','US','UY','UZ',
        'VE','VN','WF','YE','ZA','ZM'};
    
    static testMethod void testInsertMappingSingleCountry() {
        deactivateAllCurrentMappings();
        List<Network_Mapping_vod__c> mappings = new List<Network_Mapping_vod__c>();
        for (Integer i=0; i < countries.size(); i++) {
            Network_Mapping_vod__c mapping = new Network_Mapping_vod__c(Name = 'Test Mapping ' +i, 
                                                                        Country_vod__c = countries[i]);
            // Make second half active
            if (i > (countries.size()/2)) {
                mapping.Active_vod__c = true;
            }
            mappings.add(mapping);
        }
        System.Test.startTest();
        insert mappings;
        System.Test.stopTest();
        
        List<Network_Mapping_vod__c> inserted = [SELECT Id, Name, Active_vod__c, Country_vod__c, 
                                                 Unique_Key_vod__c
                                                 FROM Network_Mapping_vod__c
                                                WHERE Id IN :mappings];
        System.assertEquals(inserted.size(), countries.size());
        // Verify unique key values
        for (Network_Mapping_vod__c mapping : inserted) {
            if (mapping.Active_vod__c) {
                System.assertEquals(mapping.Unique_Key_vod__c,mapping.Country_vod__c);
            } else {
                System.assert(mapping.Unique_Key_vod__c == null);
            }
        }
    }
    
    static testMethod void testUpdateMappingSingleCountry() {
        deactivateAllCurrentMappings();
        List<Network_Mapping_vod__c> mappings = new List<Network_Mapping_vod__c>();
        for (Integer i=0; i < countries.size(); i++) {
            Network_Mapping_vod__c mapping = new Network_Mapping_vod__c(Name = 'Test Mapping ' +i, 
                                                                        Country_vod__c = countries[i]);
            // Make second half active
            if (i > (countries.size()/2)) {
                mapping.Active_vod__c = true;
            }
            mappings.add(mapping);
        }
        insert mappings;
        System.Test.startTest();
        for (Network_Mapping_vod__c mapping : mappings) {
            mapping.Active_vod__c = !mapping.Active_vod__c;
        }
        update mappings;
        
        System.Test.stopTest();
        
        List<Network_Mapping_vod__c> inserted = [SELECT Id, Name, Active_vod__c, Country_vod__c, 
                                                 Unique_Key_vod__c
                                                 FROM Network_Mapping_vod__c
                                                WHERE Id IN :mappings];
        System.assertEquals(inserted.size(), countries.size());
        // Verify unique key values
        for (Network_Mapping_vod__c mapping : inserted) {
            if (mapping.Active_vod__c) {
                System.assertEquals(mapping.Unique_Key_vod__c, mapping.Country_vod__c);
            } else {
                System.assert(mapping.Unique_Key_vod__c == null);
            }
        }
    }
    
    static testMethod void testInsertMappingMultiCountry() {
        deactivateAllCurrentMappings();
    	Network_Mapping_vod__c mapping = new Network_Mapping_vod__c(Name = 'Test Multi-Country Mapping', 
                                                                        Country_vod__c = 'US;CA;MX', Active_vod__c = true);
        System.Test.startTest();
        insert mapping;
        System.Test.stopTest();
        Network_Mapping_vod__c inserted = [SELECT Id, Name, Active_vod__c, Country_vod__c, Unique_Key_vod__c
                                          FROM Network_Mapping_vod__c WHERE Id = :mapping.Id];
        System.assertEquals('CA;MX;US', inserted.Unique_Key_vod__c, 'Did not sort countries.');
    }
    
    static testMethod void testInsertMappingDuplicateCountry() {
        deactivateAllCurrentMappings();
    	Network_Mapping_vod__c original = new Network_Mapping_vod__c(Name = 'Test Multi-Country Mapping', 
                                                                        Country_vod__c = 'US;CA;MX', Active_vod__c = true);
        insert original;
        
        Network_Mapping_vod__c conflict = new Network_Mapping_vod__c(Name = 'Duplicate Mapping',
                                                                    	Country_vod__c = 'BZ;HN;MX;NI', Active_vod__c = true);
        try {
        	System.Test.startTest();
            insert conflict;
        	System.Test.stopTest();
            System.assert(false, 'Should have thrown an exception and failed the second insert.');
        } catch (DMLException e) {
            Integer count = [SELECT COUNT() FROM Network_Mapping_vod__c WHERE Country_vod__c LIKE '%MX%' AND Active_vod__c = true];
            System.assertEquals(count, 1, 'Should only have one Active mapping with MX in Country list');
        }
    }
    
    static testMethod void testUpdateMappingDuplicateCountry() {
    	deactivateAllCurrentMappings();
    	Network_Mapping_vod__c original0 = new Network_Mapping_vod__c(Name = 'Test Multi-Country Mapping', 
                                                                        Country_vod__c = 'US;CA;HN', Active_vod__c = true);
    	Network_Mapping_vod__c original1 = new Network_Mapping_vod__c(Name = 'Test Multi-Country Mapping2', 
                                                                        Country_vod__c = 'BZ;NI;HN;MX', Active_vod__c = false);
        List<Network_Mapping_vod__c> originals = new List<Network_Mapping_vod__c>();
        originals.add(original0);
        originals.add(original1);
        insert originals;
        
        original1.Active_vod__c = true;
        try {
            System.Test.startTest();
            update original1;
            System.assert(false, 'Update should have failed.');
        } catch (DMLException e) {
            Integer count = [SELECT COUNT() FROM Network_Mapping_vod__c WHERE Country_vod__c LIKE '%HN%' AND Active_vod__c = true];
            System.assertEquals(count, 1, 'Should only have one Active mapping with HN in Country list');
        }
    }
    
    static void deactivateAllCurrentMappings() {
        // This will automatically get reverted when test is completed.
        List<Network_Mapping_vod__c> current = [SELECT Id, Active_vod__c FROM Network_Mapping_vod__c WHERE Active_vod__c = true];
        for (Network_Mapping_vod__c mapping : current) {
            mapping.Active_vod__c = false;
        }
        if (current.size() > 0) {
        	update current;
        }
    }
}