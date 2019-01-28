@isTest
public class VEEVA_ACCOUNT_TRIGGER_VOD_TEST {

    static testMethod void testATLExternalIdHandlingNoATLOnWinner() {
        RecordType proAccountType = [SELECT Id,DeveloperName FROM RecordType WHERE SobjectType = 'Account'
                                    AND DeveloperName = 'Professional_vod'];
        Account mergeWinner = new Account(FirstName = 'Unit', LastName='MergeTest', RecordTypeId = proAccountType.Id);
        Account mergeLoser = new Account(FirstName = 'UnitLoser', LastName='MergeTest', RecordTypeId = proAccountType.Id);
        Account[] accounts = new Account[]{mergeWinner, mergeLoser};
        insert accounts;
        
        Territory testTerritory = [SELECT Id, Name FROM Territory LIMIT 1];
        Account_Territory_Loader_vod__c loserAtl = 
            new Account_Territory_Loader_vod__c(Account_vod__c = mergeLoser.Id,
                                                Territory_vod__c = ';' + testTerritory.Name + ';');
        insert loserAtl;
        
        System.Test.startTest();
        
        merge mergeWinner mergeLoser;
        
        System.Test.stopTest();
        
        Account_Territory_Loader_vod__c winnerAtl = [SELECT Id, Account_vod__c, Territory_vod__c, External_ID_vod__c
                                                    FROM Account_Territory_Loader_vod__c WHERE Account_vod__c = :mergeWinner.Id];
        System.assert(winnerAtl != null, 'Should have an ATL on the winner');
        System.assertEquals(loserAtl.Id, winnerAtl.Id, 'Merge should have re-parented the ATL');
        System.assertEquals(loserAtl.Territory_vod__c, winnerAtl.Territory_vod__c, 'Should have preserved territory.');
        System.assertEquals(mergeWinner.Id, winnerAtl.External_ID_vod__c, 'Merge should have updated the ATL external ID');
    }
    
    static testMethod void testChildAccountExternalIdHandlingNoChildAccountOnWinner() {
        RecordType proAccountType = [SELECT Id,DeveloperName FROM RecordType WHERE SobjectType = 'Account'
                                    AND DeveloperName = 'Professional_vod'];
        Account mergeWinner = new Account(FirstName = 'Unit', LastName='MergeTest', RecordTypeId = proAccountType.Id);
        Account mergeLoser = new Account(FirstName = 'UnitLoser', LastName='MergeTest', RecordTypeId = proAccountType.Id);
        Account parent = new Account(Name= 'Acme Test Hospital');
        Account[] accounts = new Account[]{mergeWinner, mergeLoser, parent};
        insert accounts;
        Child_Account_vod__c loserChildAccount = new Child_Account_vod__c(Child_Account_vod__c = mergeLoser.Id,
                                                                         Parent_Account_vod__c = parent.Id);
        insert loserChildAccount;
        
        System.Test.startTest();
        
        merge mergeWinner mergeLoser;
        
        System.Test.stopTest();
        
        Child_Account_vod__c winnerChildAccount = [SELECT Id, Child_Account_vod__c, Parent_Account_vod__c, External_ID_vod__c
                                                  FROM Child_Account_vod__c WHERE Child_Account_vod__c = :mergeWinner.Id];
        System.assert(winnerChildAccount != null, 'Child Account should have been moved to winner.');
        System.assertEquals(loserChildAccount.Id, winnerChildAccount.Id, 'Should have simply reparented the Child Account.');
        System.assert(winnerChildAccount.External_ID_vod__c.contains(mergeWinner.Id),
                      'External ID :' + winnerChildAccount.External_ID_vod__c + ' should contain winner ID: ' + mergeWinner.Id);
        System.assert(winnerChildAccount.External_ID_vod__c.contains(parent.Id),
                      'External ID :' + winnerChildAccount.External_ID_vod__c + ' should contain parent ID: ' + parent.Id);
    }
}