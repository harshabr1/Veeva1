@isTest
public class Child_Account_After_UPDINS_TEST {

    static testMethod void testInsertOnlyChildAccount() {
        boolean isSimpleHierarchy = VeevaSettings.isSimpleHierarchy();
        if (isSimpleHierarchy) {
        	return;    
        }
        RecordType childType = [SELECT Id,DeveloperName FROM RecordType
                               WHERE SobjectType = 'Account' AND DeveloperName = 'Professional_vod'];
        RecordType parentType = [SELECT Id,DeveloperName FROM RecordType
                                WHERE SobjectType = 'Account' AND DeveloperName = 'MCO_vod'];
        Account child = new Account(FirstName='Unit', LastName='Test', RecordTypeId=childType.Id);
        Account parent1 = new Account(Name='Primary Managed Care', RecordTypeId=parentType.Id);
        Account parent2 = new Account(Name='Secondary Managed Care', RecordTypeId=parentType.Id);
        List<Account> toInsert = new List<Account>{child, parent1, parent2};
        insert toInsert;

        System.Test.startTest();
        // First will be set to primary, just because it is first.
        Child_Account_vod__c primary = new Child_Account_vod__c(Parent_Account_vod__c = parent1.Id,
                                                                  Child_Account_vod__c = child.Id);
        Child_Account_vod__c secondary = new Child_Account_vod__c(Parent_Account_vod__c = parent2.Id,
                                                                  Child_Account_vod__c = child.Id);
        
        List<Child_Account_vod__c> childrenToInsert = new List<Child_Account_vod__c>{primary, secondary};
        
        insert childrenToInsert;
        
        System.Test.stopTest();
        
        Account actualChild = [SELECT Id,Primary_Parent_vod__c FROM Account WHERE Id = :child.Id];
        System.assertEquals(parent1.Id, actualChild.Primary_Parent_vod__c, 'Did not set primary parent properly');
    }

    static testMethod void testInsertNetworkPrimary() {
        boolean isSimpleHierarchy = VeevaSettings.isSimpleHierarchy();
        if (isSimpleHierarchy) {
        	return;    
        }
        RecordType childType = [SELECT Id,DeveloperName FROM RecordType
                               WHERE SobjectType = 'Account' AND DeveloperName = 'Professional_vod'];
        RecordType parentType = [SELECT Id,DeveloperName FROM RecordType
                                WHERE SobjectType = 'Account' AND DeveloperName = 'MCO_vod'];
        Account child = new Account(FirstName='Unit', LastName='Test', RecordTypeId=childType.Id);
        Account parent1 = new Account(Name='Test Managed Care', RecordTypeId=parentType.Id);
        Account parent2 = new Account(Name='Primary Managed Care', RecordTypeId=parentType.Id);
        List<Account> toInsert = new List<Account>{child, parent1, parent2};
        insert toInsert;

        System.Test.startTest();
        
        Child_Account_vod__c nonPrimary = new Child_Account_vod__c(Parent_Account_vod__c = parent1.Id,
                                                                  Child_Account_vod__c = child.Id);

        Child_Account_vod__c netPrimary = new Child_Account_vod__c(Parent_Account_vod__c = parent2.Id,
                                                                  Child_Account_vod__c = child.Id,
                                                                  Network_Primary_vod__c = true);
        
        List<Child_Account_vod__c> childrenToInsert = new List<Child_Account_vod__c>{nonPrimary, netPrimary};
        
        insert childrenToInsert;
        
        System.Test.stopTest();
        
        Account actualChild = [SELECT Id,Primary_Parent_vod__c FROM Account WHERE Id = :child.Id];
        System.assertEquals(parent2.Id, actualChild.Primary_Parent_vod__c, 'Did not set primary parent properly');
    }
}