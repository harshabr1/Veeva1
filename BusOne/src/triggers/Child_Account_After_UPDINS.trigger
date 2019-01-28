trigger Child_Account_After_UPDINS on Child_Account_vod__c (after insert, after update) {

    boolean isSimpleHierarchy = VeevaSettings.isSimpleHierarchy();
    if (!VOD_Utils.getUpdateAccount()) {
        List<Account> accounts = new List<Account>();
        Set<Id> accountIds = new Set<Id>(); 
        if (isSimpleHierarchy) {
            for (Child_Account_vod__c child : Trigger.new) {
                if (!accountIds.contains(child.Child_Account_vod__c)) {
                    accounts.add(new Account(Id = child.Child_Account_vod__c, 
                                         Primary_Parent_vod__c = child.Parent_Account_vod__c));
                    accountIds.add(child.Child_Account_vod__c);
                }
            }
        } else {
            
            Set<Id> upd = new Set<Id>();

            for (Child_Account_vod__c child : Trigger.new) {
                if (child.Network_Primary_vod__c) {
                    if (!accountIds.contains(child.Child_Account_vod__c)) {
                        accounts.add(new Account(Id = child.Child_Account_vod__c, 
                                             Primary_Parent_vod__c = child.Parent_Account_vod__c));
                        accountIds.add(child.Child_Account_vod__c);
                    }
                } else {
                    upd.add(child.Child_Account_vod__c);
                }
            }
                                                
            for (Account[] noParents : [select Id from Account where Id in:upd and Primary_Parent_vod__c = '']) { 
                for (Account acct : noParents) {
                    for (Child_Account_vod__c child : Trigger.new) {
                        if (child.Child_Account_vod__c == acct.Id && !accountIds.contains(acct.Id)) {
                            accounts.add(new Account(Id = acct.Id,
                                Primary_Parent_vod__c = child.Parent_Account_vod__c));
                            accountIds.add(acct.Id);
                            break;
                        }
                    }
                }
            }
        }
        VOD_Utils.setUpdateChildAccount(true);  
        try {      
            update accounts;  
        } catch (System.DmlException e) {
            throw e;
        } finally {             
            VOD_Utils.setUpdateChildAccount(false); 
        }
    }
}