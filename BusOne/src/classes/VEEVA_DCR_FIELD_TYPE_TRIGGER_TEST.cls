@isTest
private class VEEVA_DCR_FIELD_TYPE_TRIGGER_TEST {

    static testMethod void testInsertProfile() {
        Profile testProfile = [SELECT Id, Name from Profile LIMIT 1];
        DCR_Field_Type_vod__c fieldType = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c='QA',
                                                                   Record_Type_vod__c='Professional_vod',
                                                                   Field_API_Name_vod__c='Name',
                                                                   Field_Type_vod__c='DCR_vod',
                                                                   Profile_ID_vod__c=testProfile.Id);
        System.Test.startTest();
        insert fieldType;
        System.Test.stopTest();
        DCR_Field_Type_vod__c inserted = [SELECT Id, Profile_Name_vod__c,Unique_Key_vod__c FROM DCR_Field_Type_vod__c
                                          WHERE Id= :fieldType.Id];
        System.assert(inserted != null);
        System.assertEquals(inserted.Profile_Name_vod__c, testProfile.Name);
        System.assertEquals(inserted.Unique_Key_vod__c, 'QA:'+inserted.Profile_Name_vod__c+':Account:Professional_vod:Name');
    }
    
    static testMethod void testInsertNoProfile() {
        DCR_Field_Type_vod__c fieldType = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c='QA',
                                                                   Record_Type_vod__c='Professional_vod',
                                                                   Field_API_Name_vod__c='Name',
                                                                   Field_Type_vod__c='DCR_vod');
        System.Test.startTest();
        insert fieldType;
        System.Test.stopTest();
        DCR_Field_Type_vod__c inserted = [SELECT Id, Profile_Name_vod__c,Unique_Key_vod__c FROM DCR_Field_Type_vod__c
                                          WHERE Id= :fieldType.Id];
        System.assert(inserted != null);
        System.assert(inserted.Profile_Name_vod__c == null);
        System.assertEquals(inserted.Unique_Key_vod__c, 'QA::Account:Professional_vod:Name');
    }
    
    static testMethod void testInsertNoRecordTypeNoProfile() {
        DCR_Field_Type_vod__c fieldType = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c='QA',
                                                                   Field_API_Name_vod__c='Name',
                                                                   Field_Type_vod__c='DCR_vod');
        System.Test.startTest();
        insert fieldType;
        System.Test.stopTest();
        DCR_Field_Type_vod__c inserted = [SELECT Id, Profile_Name_vod__c,Unique_Key_vod__c FROM DCR_Field_Type_vod__c
                                          WHERE Id= :fieldType.Id];
        System.assert(inserted != null);
        System.assert(inserted.Profile_Name_vod__c == null);
        System.assertEquals(inserted.Unique_Key_vod__c, 'QA::Account::Name');
    }
    
    static testMethod void testInsertNoRecordType() {
        Profile testProfile = [SELECT Id, Name from Profile LIMIT 1];
        DCR_Field_Type_vod__c fieldType = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c='QA;MX',
                                                                   Field_API_Name_vod__c='Name',
                                                                   Field_Type_vod__c='DCR_vod',
                                                                   Profile_ID_vod__c=testProfile.Id);
        System.Test.startTest();
        insert fieldType;
        System.Test.stopTest();
        DCR_Field_Type_vod__c inserted = [SELECT Id, Profile_Name_vod__c,Unique_Key_vod__c FROM DCR_Field_Type_vod__c
                                          WHERE Id= :fieldType.Id];
        System.assert(inserted != null);
        System.assertEquals(inserted.Profile_Name_vod__c,testProfile.Name);
        System.assertEquals(inserted.Unique_Key_vod__c, 'MX;QA:'+inserted.Profile_Name_vod__c+':Account::Name');
    }
    
    static testMethod void testInsertDuplicateCountry() {
        DCR_Field_Type_vod__c fieldType = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c='QA;US;CA;MX;HN;ZZ',
                                                                   Record_Type_vod__c='Professional_vod',
                                                                   Field_API_Name_vod__c='Name',
                                                                   Field_Type_vod__c='DCR_Required_vod');
        DCR_Field_Type_vod__c fieldTypeOK = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c='QA;US;CA;MX;HN;ZZ',
                                                                   Record_Type_vod__c='Hospital_vod',
                                                                   Field_API_Name_vod__c='Name',
                                                                   Field_Type_vod__c='DCR_Required_vod');
        DCR_Field_Type_vod__c fieldTypeDup = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c='HN',
                                                                   Record_Type_vod__c='Professional_vod',
                                                                   Field_API_Name_vod__c='Name',
                                                                   Field_Type_vod__c='DCR_Required_vod');
        insert fieldType;
        System.Test.startTest();
        insert fieldTypeOK;
        try {
            insert fieldTypeDup;
            System.assert(false, 'Should have thrown exception.');
        } catch (DMLException e) {
            Integer count = [SELECT COUNT() FROM DCR_Field_Type_vod__c WHERE Country_vod__c LIKE '%HN%'
                             AND Object_API_Name_vod__c='Account'
                             AND Record_Type_vod__c = 'Professional_vod' AND Field_API_Name_vod__c = 'Name'];
            System.assertEquals(count, 1, 'Should only have one DCR Field Type for Professional_vod, Name with HN in Country list');
        }
        System.Test.stopTest();
        DCR_Field_Type_vod__c inserted = [SELECT Id, Profile_Name_vod__c,Unique_Key_vod__c FROM DCR_Field_Type_vod__c
                                          WHERE Id= :fieldTypeOK.Id];
        System.assert(inserted != null);
        System.assert(inserted.Profile_Name_vod__c == null);
        System.assertEquals(inserted.Unique_Key_vod__c, 'CA;HN;MX;QA;US;ZZ::Account:Hospital_vod:Name');
    }
    
    static testMethod void testLongCountryField() {
        List<String> countries = new List<String>(); 
        String[] letters = new String[]{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q'};
        // 17*5 = 85 * 3 - 1 = 254
        for (Integer i=0; i < 17; i++) {
            for (Integer j=0; j < 5; j++) {
                countries.add(letters[i] + letters[j]);
            }	    
        }
        System.assertEquals(85, countries.size(), 'Wrong size list.');
		String countryStr = String.join(countries,';');
        System.assertEquals(254, countryStr.length(), countryStr);
        DCR_Field_Type_vod__c fieldType = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c=countryStr,
                                                                   Record_Type_vod__c='Hospital_vod',
                                                                   Field_API_Name_vod__c='Name',
                                                                   Field_Type_vod__c='DCR_Required_vod');
        System.Test.startTest();
        insert fieldType;
        System.Test.stopTest();
        DCR_Field_Type_vod__c inserted = [SELECT Id,Country_vod__c,Unique_Key_vod__c FROM DCR_Field_Type_vod__c WHERE Id = :fieldType.Id];
        String unique = inserted.Unique_Key_vod__c;
        System.assert(String.isNotBlank(unique), 'Should have a unique key');
        System.assert(unique.endsWith('::Account:Hospital_vod:Name'), 'Insert did not properly truncate end');
		System.assert(unique.startsWith('AA;AB;AC;AD;AE;BA;BB;BC;BD;BE'), 'Insert did not properly truncate country.');        
    }
        
    static testMethod void testInsertDuplicateCountryDifferentField() {
        DCR_Field_Type_vod__c fieldType = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c='QA;US;CA;MX;HN;ZZ',
                                                                   Record_Type_vod__c='Professional_vod',
                                                                   Field_API_Name_vod__c='Name',
                                                                   Field_Type_vod__c='DCR_Required_vod');
        DCR_Field_Type_vod__c fieldTypeOK = new DCR_Field_Type_vod__c(Object_API_Name_vod__c='Account',
                                                                    Country_vod__c='HN',
                                                                   Record_Type_vod__c='Professional_vod',
                                                                   Field_API_Name_vod__c='Specialty_vod__c',
                                                                   Field_Type_vod__c='DCR_Required_vod');
        insert fieldType;
        System.Test.startTest();
        insert fieldTypeOK;
        System.Test.stopTest();
        DCR_Field_Type_vod__c inserted = [SELECT Id, Profile_Name_vod__c,Unique_Key_vod__c FROM DCR_Field_Type_vod__c
                                          WHERE Id= :fieldTypeOK.Id];
        System.assert(inserted != null);
        System.assert(inserted.Profile_Name_vod__c == null);
        System.assertEquals(inserted.Unique_Key_vod__c, 'HN::Account:Professional_vod:Specialty_vod__c');
    }
}