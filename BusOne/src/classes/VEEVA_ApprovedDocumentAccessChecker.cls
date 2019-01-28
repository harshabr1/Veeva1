global with sharing class VEEVA_ApprovedDocumentAccessChecker{
        
    Global Map<Id, Boolean> userHasAccessToApprovedDocuments(Set<Id> documentIds) {
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        Map<Id, Approved_Document_vod__c> docMap = new Map<Id, Approved_Document_vod__c>([select Id, Name from Approved_Document_vod__c where id IN :documentIds]);
        for(Id docId: documentIds){
            result.put(docId, docMap.containsKey(docId));            
        }
        return result;
    }
    
    Global Map<Id, Boolean> userHasAccessToAccounts(Set<Id> accountIds) {
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        Map<Id, Account> accountMap = new Map<Id, Account>([select Id, Name from Account where id IN :accountIds]);
        for(Id accountId: accountIds){
            result.put(accountId, accountMap.containsKey(accountId));            
        }
        return result;
    }

    Global Map<Id, Boolean> userHasAccessToUsers(Set<Id> userIds) {
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        Map<Id, User> userMap = new Map<Id, User>([select Id, Name from User where id IN :userIds]);
        for(Id userId: userIds){
            result.put(userId, userMap.containsKey(userId));
        }
        return result;
    }

}