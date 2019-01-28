trigger Child_Account_After_Delete on Child_Account_vod__c (after delete) {
    
    if (VOD_Utils.getUpdateAccount())
        return;

    Map<Id, Set<Id>> parentsMap = new Map<Id, Set<Id>>();
    for (Child_Account_vod__c child : Trigger.oldMap.values()){
        Set<Id> parents = parentsMap.get(child.Child_Account_vod__c);
        if (parents == null) {
            parents = new Set<Id>();
            parentsMap.put(child.Child_Account_vod__c, parents);
        }
        parents.add(child.Parent_Account_vod__c);		  
    }
    
    List<Account> accounts = new List<Account>();
    Set<Id> acctIds = parentsMap.keySet();
    if (acctIds.size() > 0)
        for (Account account : [select Id, Primary_Parent_vod__c from Account where Id in :acctIds]) {
            if (parentsMap.get(account.Id).contains(account.Primary_Parent_vod__c)) {
                account.Primary_Parent_vod__c = null;
                accounts.add(account);
            }
        }
    
    if (accounts.size() > 0) {
        VOD_Utils.setUpdateChildAccount(true);
        try {
          update accounts;
        }
        finally {
          VOD_Utils.setUpdateChildAccount(false);
        }
    }

}