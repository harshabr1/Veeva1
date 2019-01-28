@isTest
public class VOD_APP_LABEL_BEFORE_INS_UPD_TEST {

    /**
     * If ID is specified incoming, then Record Type Name should be populated to match.
     **/
    static testMethod void testInsertDefaultIdNoName() {
    	Application_Label_vod__c original = new Application_Label_vod__c(Object_API_Name_vod__c='Call2_vod__c',
                                                                        Component_Name_vod__c='Label',
                                                                        Label_vod__c='Interaction');
        System.Test.startTest();
       	insert original;
        System.Test.stopTest();
        
        Application_Label_vod__c saved = [SELECT Id, RecordTypeId, Record_Type_Name_vod__c 
                                          FROM Application_Label_vod__c WHERE Id=:original.Id];
        System.assert(saved.RecordTypeId != null);
        RecordType savedType = [SELECT Id, DeveloperName FROM RecordType WHERE Id=:saved.RecordTypeId];
        System.assertEquals(savedType.DeveloperName, saved.Record_Type_Name_vod__c);
    }
    
    /**
     * If RecordType ID and Name are specified, then Name should override ID.
     **/
    static testMethod void testInsertDefaultIdAndNameSpecified() {
        
    	Application_Label_vod__c original = new Application_Label_vod__c(Object_API_Name_vod__c='Call2_vod__c',
                                                                         Field_Or_Layout_vod__c='Medical_Inquiry_vod__c',
                                                                        Component_Name_vod__c='RelatedListLabel',
                                                                        Label_vod__c='Inquiry Interactions',
                                                                        Record_Type_Name_vod__c='CustomField');
        System.Test.startTest();
       	insert original;
        System.Test.stopTest();
        
        Application_Label_vod__c saved = [SELECT Id, RecordTypeId, Record_Type_Name_vod__c 
                                          FROM Application_Label_vod__c WHERE Id=:original.Id];
        System.assert(saved.RecordTypeId != null);
        RecordType savedType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType='Application_Label_vod__c'
                                AND DeveloperName=:original.Record_Type_Name_vod__c];
        System.assertEquals(savedType.Id, saved.RecordTypeId);
    }
    
    /**
     * On Update, if ID is changed and Name is not, Name should be updated to match ID.
     **/
    static testMethod void testUpdateIdChangedNoName() {
    	Application_Label_vod__c original = new Application_Label_vod__c(Object_API_Name_vod__c='Call2_vod__c',
                                                                         Field_Or_Layout_vod__c='Medical_Inquiry_vod__c',
                                                                        Component_Name_vod__c='RelatedListLabel',
                                                                        Label_vod__c='Inquiry Interactions',
                                                                        Record_Type_Name_vod__c='PicklistValue');
       	insert original;
        
        RecordType fixType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType='Application_Label_vod__c'
                              AND DeveloperName='CustomField'];
        System.Test.startTest();
        
        // Oops!
        Application_Label_vod__c fixed = new Application_Label_vod__c(Id=original.Id, RecordTypeId=fixType.Id);
        
        update fixed;
        
        System.Test.stopTest();
        
        Application_Label_vod__c saved = [SELECT Id, RecordTypeId, Record_Type_Name_vod__c 
                                          FROM Application_Label_vod__c WHERE Id=:original.Id];
        System.assertEquals(fixType.Id, saved.RecordTypeId);
        System.assertEquals(fixType.DeveloperName, saved.Record_Type_Name_vod__c);
    }
    
    /**
     * On update, if name is changed and ID is not, ID should be updated to match Name.
     **/
    static testMethod void testUpdateNameChangedNoId() {
    	Application_Label_vod__c original = new Application_Label_vod__c(Object_API_Name_vod__c='Call2_vod__c',
                                                                         Field_Or_Layout_vod__c='Medical_Inquiry_vod__c',
                                                                        Component_Name_vod__c='RelatedListLabel',
                                                                        Label_vod__c='Inquiry Interactions',
                                                                        Record_Type_Name_vod__c='PicklistValue');
       	insert original;

        System.Test.startTest();
        
        // Oops!
        Application_Label_vod__c fixed = new Application_Label_vod__c(Id=original.Id, Record_Type_Name_vod__c='CustomField');
        update fixed;
        
        System.Test.stopTest();

        Application_Label_vod__c saved = [SELECT Id, RecordTypeId, Record_Type_Name_vod__c 
                                          FROM Application_Label_vod__c WHERE Id=:original.Id];
        System.assert(saved.RecordTypeId != null);
        RecordType savedType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType='Application_Label_vod__c'
                                AND DeveloperName=:fixed.Record_Type_Name_vod__c];
        System.assertEquals(saved.RecordTypeId, savedType.Id);
    }
    
    /**
     * On update, if both name and ID are changed, Name overrides and ID should be updated to match.
     **/
    static testMethod void testUpdateNameAndIdChanged() {
    	Application_Label_vod__c original = new Application_Label_vod__c(Object_API_Name_vod__c='Call2_vod__c',
                                                                         Field_Or_Layout_vod__c='Medical_Inquiry_vod__c',
                                                                        Component_Name_vod__c='RelatedListLabel',
                                                                        Label_vod__c='Inquiry Interactions',
                                                                        Record_Type_Name_vod__c='PicklistValue');
       	insert original;
        RecordType fixType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType='Application_Label_vod__c'
                              AND DeveloperName='CustomField'];
        RecordType idType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType='Application_Label_vod__c'
                              AND DeveloperName='Object_vod'];
        
        System.Test.startTest();
        
        // Double Oops!
        Application_Label_vod__c fixed = new Application_Label_vod__c(Id=original.Id, RecordTypeId=idType.Id,
                                                                     Record_Type_Name_vod__c=fixType.DeveloperName);
        
        update fixed;
        
        System.Test.stopTest();
        
        Application_Label_vod__c saved = [SELECT Id, RecordTypeId, Record_Type_Name_vod__c 
                                          FROM Application_Label_vod__c WHERE Id=:original.Id];
        System.assertEquals(fixType.Id, saved.RecordTypeId);
        System.assertEquals(fixType.DeveloperName, saved.Record_Type_Name_vod__c);
    }
}