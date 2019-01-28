@isTest
public class VOD_ACCOUNT_TO_TERRITORY_TRIGGER_TEST {

    static testMethod void testDropTerritoriesSpecialChars() {
        // Due to MIXED_DML_OPERATION restriction, can't create a territory and other records in one test method.
        List<Territory> territories = [SELECT Id, Name FROM Territory WHERE Name LIKE '%(%)%'];
        if (territories.size() > 0) {
            Territory territory = territories.get(0);
            List<Group> terrGroups = [Select Id, RelatedId from Group where Type = 'Territory' and RelatedId = :territory.Id];
            if (terrGroups.size() > 0) {
                RecordType pro = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName='Professional_vod'
                                 AND SobjectType='Account'];            
        
                Account testAccount = new Account(FirstName='Test', LastName='Atl', RecordTypeId=pro.Id);
                insert testAccount;
                String territoryString = ';'+territory.Name+';';
                Account_Territory_Loader_vod__c atl = 
                    new Account_Territory_Loader_vod__c(Account_vod__c=testAccount.Id,
                                                        Territory_to_Add_vod__c=territoryString);
                insert atl;
                List<AccountShare> accountShares = [SELECT Id,AccountId,UserOrGroupId FROM AccountShare WHERE AccountId = :testAccount.Id
                                                   AND UserOrGroupId IN :terrGroups];
                System.assert(accountShares.size() > 0, 'Initial territory add did not update account');
        
                System.Test.startTest();
                
                Account_Territory_Loader_vod__c atlDrop = 
                                    new Account_Territory_Loader_vod__c(Id=atl.Id,
                                                                       Territory_to_Drop_vod__c=territoryString);
                update atlDrop;
                
                System.Test.stopTest();

                Account_Territory_Loader_vod__c atlResult = [SELECT Id, Territory_vod__c, Territory_to_Drop_vod__c FROM Account_Territory_Loader_vod__c WHERE Id=:atl.Id];
                System.assert(atlResult.Territory_vod__c == null || atlResult.Territory_vod__c.length() == 0, 'Did not change Territory field on ATL:' + atlResult.Territory_vod__c);

                accountShares = [SELECT Id,AccountId,UserOrGroupId FROM AccountShare WHERE AccountId = :testAccount.Id
                                                   AND UserOrGroupId in :terrGroups];
                System.assertEquals(0, accountShares.size(), 'Territory drop failed.');  
            } else {
                System.debug('Skipping unit test - territory has no groups for some reason.');
            }
        } else {
            System.debug('Skipping unit test - cannot find useful Territory,' 
                         + ' and cannot create/edit one due to MIXED_DML_OPERATION restriction.');
        }
    }
}