trigger Account_trigger_vod on Account bulk (before delete, after delete) {
 
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
    Map <Id,Account> accMap = null;
    if (Trigger.isBefore) { 
        accMap = new Map <Id,Account> ([Select Id, 
                                                (Select Id from Call2_vod__r 
                                                     where Status_vod__c != 'Planned_vod'),
                                                (Select Id, Primary_vod__c from Address_vod__r),
                                                (Select Id From TSF_vod__r),
                                                (Select Id From Affiliation_vod__r),
                                                (Select Id From Affiliation_vod1__r),
                                                (Select Id From Affiliation_vod__pr),
                                                (Select Id From Affiliation_vod1__pr),
                                                (Select Id From MC_Cycle_Plan_Targets_vod__r),
                                                (Select Id From MC_Cycle_Plan_Targets_Location_vod__r),
                                                (Select Id From Cycle_Plan_Targets__r),
                                                (Select Id From Pricing_Rules_vod__r),
                                                (select Id, Child_Account_vod__c from Parent_Account_vod__r),
                                                (select Id, Parent_Account_vod__c from Child_Account_vod__r),
                                                (Select Id From R00NT0000000lj9mMAA__r), // Account_Territory_Loader_vod__c
                                                (Select Id From Sample_Limit_vod__r)
                                        from Account where ID in :Trigger.old]);             
        VOD_ACCOUNT_TRIG.setDeleteMap (accMap);
    } else {
        accMap =  VOD_ACCOUNT_TRIG.getDeleteMap();                                                 
        Set<Id> TSFList = new Set<Id> ();
        Set<Id> AddressList = new Set<Id> ();
        Set<Id> SetPrimaryAddr = new Set<Id>();
        Set<Id> AffiliationList = new Set<Id> ();
        Set<Id> PriceList = new Set<Id> ();
        Map<Id, Id> MCTargets = new Map<Id,Id> ();
        Map<Id, Id> MCTargetLocations = new Map<Id, Id> ();
        Map<Id, Id> Targets = new Map<Id,Id> ();
        Map<String, Child_Account_vod__c> ChildToUpd = new Map<String, Child_Account_vod__c>(); 
        List<Child_Account_vod__c> ChildToDel =  new List<Child_Account_vod__c> (); 
        List<Affiliation_vod__c> affiliationToDel = new List<Affiliation_vod__c> ();
        Set<String> externIds = new Set<String> ();
        String extern;
        Map<Id, String> losingAtlWinningAccountList = new Map<Id, String>();
        Set<String> masterRecordIds = new Set<String> ();
        Map<Id, Set<Id>> masterToValidPrimariesIdMap = new Map<Id, Set<Id>>();
        Map<Id, List<Id>> masterToLoserPrimaries = new Map<Id, List<Id>>();
        Map<Id, Id> sampleLimits = new Map<Id, Id>();
        for (Id id : accMap.keySet()) {
            Account acct = accMap.get(id);
            Id masterRecordId = Trigger.oldMap.get(id).masterRecordId;
            if (masterRecordId != null) {
                System.debug('Saving Master Record for later processing' + masterRecordId);
                masterRecordIds.add(masterRecordId);

                for (Address_vod__c address : acct.Address_vod__r) {
            	  	AddressList.add(address.Id);
                    if (address.Primary_vod__c) {
                        List<Id> loserPrimaries = masterToLoserPrimaries.get(masterRecordId);
                        if (loserPrimaries == null) {
                            loserPrimaries = new List<Id>();
                            masterToLoserPrimaries.put(masterRecordId, loserPrimaries);
                        }
                        loserPrimaries.add(address.Id);
                    }
                }

                for (Affiliation_vod__c afilRec : acct.Affiliation_vod__r) {
                    AffiliationList.add(afilRec.Id);
                }
                            
                for (Affiliation_vod__c afilRec : acct.Affiliation_vod1__r) {
                    AffiliationList.add(afilRec.Id);
                }
                for (Affiliation_vod__c afilRec : acct.Affiliation_vod__pr) {
                    AffiliationList.add(afilRec.Id);
                }
                for (Affiliation_vod__c afilRec : acct.Affiliation_vod1__pr) {
                    AffiliationList.add(afilRec.Id);
                }
                
                for(MC_Cycle_Plan_Target_vod__c target : acct.MC_Cycle_Plan_Targets_vod__r) {                                     
                    MCTargets.put(target.id, masterRecordId);
                }
                for(MC_Cycle_Plan_Target_vod__c target : acct.MC_Cycle_Plan_Targets_Location_vod__r) {                                     
                    MCTargets.put(target.id, masterRecordId);
                }
                
                for(Cycle_Plan_Target_vod__c target : acct.Cycle_Plan_Targets__r) {                                    
                    Targets.put(target.id, masterRecordId);     
                }
                            
                for (TSF_vod__c tsfRec : acct.Tsf_vod__r) {
                    TSFList.add(tsfRec.Id);
                }
                            
                for (Pricing_Rule_vod__c prc: acct.Pricing_Rules_vod__r) {
                    PriceList.add(prc.Id);
                }
                for (Child_Account_vod__c child: acct.Parent_Account_vod__r) {
                    if (masterRecordId == child.Child_Account_vod__c)
                       ChildToDel.add(new Child_Account_vod__c(Id = child.Id));
                    else {
                        extern = masterRecordId + '__' + child.Child_Account_vod__c;
                        if (externIds.contains(extern))
                            ChildToDel.add(new Child_Account_vod__c(Id = child.Id));
                        else {
                            ChildToUpd.put(extern, new Child_Account_vod__c(Id = child.Id, External_Id_vod__c = ''));
                            externIds.add(extern);
                        }
                    }
                }
                for (Child_Account_vod__c child: acct.Child_Account_vod__r) {
                    if (child.Parent_Account_vod__c == masterRecordId)
                       ChildToDel.add(new Child_Account_vod__c(Id = child.Id));
                    else {
                        extern = child.Parent_Account_vod__c + '__' + masterRecordId;
                        if (externIds.contains(extern))
                            ChildToDel.add(new Child_Account_vod__c(Id = child.Id));
                        else {
                            ChildToUpd.put(extern, new Child_Account_vod__c(Id = child.Id, External_Id_vod__c = ''));
                            externIds.add(extern);
                        }
                    }
                }
                for (Account_Territory_Loader_vod__c tmpAtl : acct.R00NT0000000lj9mMAA__r) {
                    // if for some reason there are multiple ATL records, should really only be 1
                    System.debug('Adding ATL to be processed: ' + tmpAtl.Id);
                    losingAtlWinningAccountList.put(tmpAtl.Id, masterRecordId);
                }
                for (Sample_Limit_vod__c lim : acct.Sample_Limit_vod__r) {
                    sampleLimits.put(lim.Id, id);
                }
            }
            else {
                if (acct.Call2_vod__r.size() > 0) {
                    Trigger.oldMap.get(acct.Id).addError(bundle.getErrorMsg('NO_DEL_ACCOUNT'), false);
                }
                else {
                    for (Child_Account_vod__c child: acct.Child_Account_vod__r) 
                        ChildToDel.add(new Child_Account_vod__c(Id = child.Id));
                        
                    for (Affiliation_vod__c afilRec : acct.Affiliation_vod__r) {
                        affiliationToDel.add(new Affiliation_vod__c(Id = afilRec.Id));
                    }
   
                    for (Affiliation_vod__c afilRec : acct.Affiliation_vod__pr) {
                        affiliationToDel.add(new Affiliation_vod__c(Id = afilRec.Id));
                    }
                    
                }
            }
        }

        if (masterRecordIds.size() > 0) {
            // We have one or more master records to process
        	Map<Id, Account> masterAcctQueryResults = new Map<Id, Account>([Select Id, (Select Id, Primary_vod__c from Address_vod__r where Primary_vod__c = true) from Account where Id in :masterRecordIds]);
            if (masterAcctQueryResults.size() > 0) {
                for (Id masterRecordId : masterRecordIds) {
                    Account masterAccount = masterAcctQueryResults.get(masterRecordId);
                    
                    // Determine set of primary addresses that we think are valid for the master account
                    // Initially all primaries will be valid until determined otherwise
                    Set<Id> validPrimariesForMaster = new Set<Id>();
                    for (Address_vod__c address : masterAccount.Address_vod__r) {
                        validPrimariesForMaster.add(address.Id);
                    }
                    masterToValidPrimariesIdMap.put(masterRecordId, validPrimariesForMaster);
                }
                
                // Loop through all loser primaries and remove them from valid list
                for (Id masterRecordId : masterToLoserPrimaries.keySet()) {
                	List<Id> loserPrimaries = masterToLoserPrimaries.get(masterRecordId);
                	Set<Id> validPrimaries = masterToValidPrimariesIdMap.get(masterRecordId);
                	// Remove the loser primaries from valid list as they are new and weren't original primary
                	validPrimaries.removeAll(loserPrimaries);
                }
            }

        	// At this point, deleted merge loser accounts have all been processed if it was a merge so we can calculate which
        	// values should be set to primary for any merge winners.
        	Set<Id> mergeWinnerIds = masterToValidPrimariesIdMap.keySet();
        	for (Id winnerId : mergeWinnerIds) {
            	Set<Id> validPrimaries = masterToValidPrimariesIdMap.get(winnerId);
                System.debug('Master and valid primaries: ' + winnerId + ', primaries ' + validPrimaries);
            	if (validPrimaries != null && validPrimaries.size() > 0) {
                	// Add all existing primaries that weren't removed due to being "new"
                	SetPrimaryAddr.addAll(validPrimaries);
                	System.debug('Ensuring existing primaries will be set for master ' + winnerId + ' to ' + validPrimaries);
            	} else {
                	// No existing primary for this merge winner, use one of the loser primaries if any
                	List<Id> loserPrimaries = masterToLoserPrimaries.get(winnerId);
                	if (loserPrimaries != null && loserPrimaries.size() > 0) {
						Id potentialPrimary = loserPrimaries.get(0); // Just grab first loser primary found to use as new primary
	                	System.debug('Did not find existing primary for master ' + winnerId + ' using address ' + potentialPrimary);
                        SetPrimaryAddr.add(potentialPrimary);
                	}
            	}
        	}        
        }                
        
        if (externIds.size() > 0)
            for (Child_Account_vod__c child : [select External_Id_vod__c from Child_Account_vod__c where External_Id_vod__c in :externIds]){
                Child_Account_vod__c toRemove = ChildToUpd.remove(child.External_Id_vod__c);
                ChildToDel.add(new Child_Account_vod__c(Id = toRemove.Id));
            }
        
        VOD_Utils.setUpdateAccount(true);
        VOD_Utils.setisMergeAccountProcess(true);
        try {
            delete ChildToDel;
            update ChildToUpd.values();
        } finally {
            VOD_Utils.setUpdateAccount(false);  
            VOD_Utils.setisMergeAccountProcess(false);
        }    
        
        delete affiliationToDel;
            
        // condition check here to reduce the number of @future method invocation
        if ('false'.equalsIgnorecase (System.Label.DISABLE_VEEVA_MERGE_vod) && 
            (TSFList.size() > 0 || AddressList.size() > 0 || AffiliationList.size() > 0 
                || PriceList.size() > 0 || losingAtlWinningAccountList.size() > 0) || MCTargets.size() > 0 || Targets.size() > 0 || sampleLimits.size() > 0) {
            VEEVA_Merge.ProcessAccountMerge(TSFList, AddressList, AffiliationList, PriceList, losingAtlWinningAccountList, MCTargets, Targets, SetPrimaryAddr, sampleLimits);
        }
        else
            System.debug('Not executing VEEVA_Merge: ' + System.Label.DISABLE_VEEVA_MERGE_vod);
    }
                    
}