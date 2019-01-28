trigger VOD_ACCOUNT_MERGE_CAPTURE_TRIGGER on Account (after delete) {

    List <Account_Merge_History_vod__c> newMergeRecords = new List<Account_Merge_History_vod__c> ();
    Set <Id> accts = new Set<Id> ();
    
    for (Account act: Trigger.old) {
        if (act.MasterRecordId != null && act.IsPersonAccount == true) {
        accts.add (act.MasterRecordId); 
        }
    }
    
    Map<Id, Account> accMap = null;
    
    if (accts.size() > 0) {
        accMap = new Map<Id,Account> ([SELECT Id,PersonContactId FROM Account where Id in :accts]);
    }
    
    for (Account act: Trigger.old) {
        // if the Master != null then we have a merge.
        if (act.MasterRecordId != null) {
            Account_Merge_History_vod__c newMerge = new Account_Merge_History_vod__c (Name = act.Id, Account_vod__c  = act.MasterRecordId);
            if (act.IsPersonAccount == true) {
                if (accMap != null) {
                    Account lAcct = accMap.get(act.MasterRecordId);
                    if (lAcct != null) {
                        newMerge.PersonContactId_vod__c = act.PersonContactId;
                        newMerge.Account_PersonContactId_vod__c = lAcct.PersonContactId; 
                    }
                }
            
            }
            newMergeRecords.add(newMerge);
        }
    }
    
    if (newMergeRecords.size() > 0 ) {
        insert newMergeRecords;
    }
}