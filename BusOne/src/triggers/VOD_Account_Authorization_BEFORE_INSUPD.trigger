trigger VOD_Account_Authorization_BEFORE_INSUPD on Account_Authorization_vod__c (before insert, before update) {
    // check for overlapping start / end date combinations 
    Set<String> accounts = new Set<String>();
    Set<String> supervisingAccounts = new Set<String>();
    Set<String> allSupervisingAccounts = new Set<String>();
    Map<String, List<VOD_AccountAuthorizationWrapper>> dataSet = new Map<String, List<VOD_AccountAuthorizationWrapper>>();
    Set<Id> updatingRecords = new Set<Id>();
    for (Account_Authorization_vod__c aa : Trigger.new) {
        // store later to grab supervising account name
        allSupervisingAccounts.add(aa.Supervising_Account_vod__c);

        // ignore inactive relationships
        if (aa.Collaborative_Relationship_Inactive_vod__c == false) {
            // build data set
            accounts.add(aa.Account_vod__c);
            supervisingAccounts.add(aa.Supervising_Account_vod__c);
            String dataKey = aa.Account_vod__c + '_' + aa.Supervising_Account_vod__c + '_' + aa.Collaborative_Relationship_State_vod__c;
            List<VOD_AccountAuthorizationWrapper> aaList = dataSet.get(dataKey);
            if (aaList == null) {
                aaList = new List<VOD_AccountAuthorizationWrapper>();
                dataSet.put(dataKey, aaList);
            }
            aaList.add(new VOD_AccountAuthorizationWrapper(aa, true));
        }
        
        if (aa.Id != null) {
            updatingRecords.add(aa.Id);
        }
    }
    
    // find matching records
    List<Account_Authorization_vod__c> existingaas = [Select Id, 
            Account_vod__c, Supervising_Account_vod__c, 
            Collaborative_Relation_Start_Date_vod__c, Collaborative_Relation_End_Date_vod__c, 
            Collaborative_Relationship_State_vod__c
        From Account_Authorization_vod__c 
        Where Collaborative_Relationship_Inactive_vod__c = False And Account_vod__c In :accounts 
            And Supervising_Account_vod__c In :supervisingAccounts];
    
    for (Account_Authorization_vod__c existingaa : existingaas) {
        if (updatingRecords.contains(existingAa.Id)) {
            // ignore existing records that we are updating
            continue;
        }
        String dataKey = existingaa.Account_vod__c + '_' + existingaa.Supervising_Account_vod__c + '_' + existingaa.Collaborative_Relationship_State_vod__c;
        List<VOD_AccountAuthorizationWrapper> aaList = dataSet.get(dataKey);
        if (aaList != null) {
            aaList.add(new VOD_AccountAuthorizationWrapper(existingaa, false));
        } 
    }
    
    String errorMsgText = VOD_GET_ERROR_MSG.getErrorMsg('COLLABORATIVE_RELATIONSHIP_DUPLICATE', 'Account');
    // test each and see if there is a duplicate
    for (List<VOD_AccountAuthorizationWrapper> aaList : dataSet.values()) {
        // if there's only one item, there are no found dups
        if (aaList.size() > 1) {
            aaList.sort();
            VOD_AccountAuthorizationWrapper first = null;
            VOD_AccountAuthorizationWrapper second = null;
            for (VOD_AccountAuthorizationWrapper aaWrapper : aaList) {
                if (second == null) {
                    second = aaWrapper;
                    continue;
                }
                else {
                    first = second;
                    second = aaWrapper;
                }
                 //a null end date means an infinite end date which is definitely >= the second start date
                if ((first.aaObj.Collaborative_Relation_Start_Date_vod__c == null && first.aaObj.Collaborative_Relation_End_Date_vod__c == null) ||
                    (second.aaObj.Collaborative_Relation_Start_Date_vod__c == null && second.aaObj.Collaborative_Relation_End_Date_vod__c == null) ||
                    first.aaObj.Collaborative_Relation_End_Date_vod__c >= second.aaObj.Collaborative_Relation_Start_Date_vod__c) {
                    if (first.modified == true) {
                        first.aaObj.addError(errorMsgText);
                    }
                    if (second.modified == true) {
                        second.aaObj.addError(errorMsgText);
                    }
                }
            }
        }
    }
 
    // gather supervising account names and stamp the record
    Map<Id, String> accountNames = new Map<Id, String>();
    for (Account accountObj : [Select Id, Formatted_Name_vod__c From Account
            Where Id In :allSupervisingAccounts]) {
        accountNames.put(accountObj.Id, accountObj.Formatted_Name_vod__c);
    }
            
    for (Account_Authorization_vod__c aa : Trigger.new) {
        // stamp supervising account's name
        String accountName = accountNames.get(aa.Supervising_Account_vod__c);
        if (accountName == null) {
            accountName = aa.Supervising_Account_vod__c;
        }
        aa.Supervising_Account_Name_vod__c = accountName;
    }        
}