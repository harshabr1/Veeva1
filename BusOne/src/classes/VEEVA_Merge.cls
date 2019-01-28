public class VEEVA_Merge {
    
    public static boolean isAddressMerge = false;
    
    public static void ProcessAccountMerge (Set<Id> tsfIds,  Set<Id> addrIds, Set<Id> affilIds, Set<Id> prIds, Map<Id,String> losingAtlWinningAccountList) {
        ProcessAccountMerge(tsfIds, addrIds, affilIds, prIds, losingAtlWinningAccountList, null, null);
    }
    
    public static void ProcessAccountMerge (Set<Id> tsfIds,  Set<Id> addrIds, Set<Id> affilIds, Set<Id> prIds, Map<Id,String> losingAtlWinningAccountList, Map<Id, Id> mcCptIds, Map<Id, Id> cptIds) {
        ProcessAccountMerge(tsfIds, addrIds, affilIds, prIds, losingAtlWinningAccountList, mcCptIds, cptIds, null, null);
    }

    public static void ProcessAccountMerge (Set<Id> tsfIds,  Set<Id> addrIds, Set<Id> affilIds, Set<Id> prIds, Map<Id,String> losingAtlWinningAccountList, Map<Id, Id> mcCptIds, Map<Id, Id> cptIds, Set<Id> setPrimaryAddress, Map<Id, Id> sampleLimits) {
        if (System.isFuture() || System.isBatch()) {
            ProcessAccountMergeNow(tsfIds, addrIds, affilIds, prIds, losingAtlWinningAccountList, mcCptIds, cptIds, setPrimaryAddress, sampleLimits);
        } else {
            ProcessAccountMergeFuture(tsfIds, addrIds, affilIds, prIds, losingAtlWinningAccountList, mcCptIds, cptIds, setPrimaryAddress, sampleLimits);
        }
    }

    @future
    public static void ProcessAccountMergeFuture (Set<Id> tsfIds,  Set<Id> addrIds, Set<Id> affilIds, Set<Id> prIds, Map<Id,String> losingAtlWinningAccountList, Map<Id, Id> mcCptIds, Map<Id, Id> cptIds, Set<Id> setPrimaryAddress, Map<Id, Id> sampleLimits) {
        ProcessAccountMergeNow(tsfIds, addrIds, affilIds, prIds, losingAtlWinningAccountList, mcCptIds, cptIds, setPrimaryAddress, sampleLimits);
    }

    public static void ProcessAccountMergeNow (Set<Id> tsfIds,  Set<Id> addrIds, Set<Id> affilIds, Set<Id> prIds, Map<Id,String> losingAtlWinningAccountList, Map<Id, Id> mcCptIds, Map<Id, Id> cptIds, Set<Id> setPrimaryAddress, Map<Id, Id> sampleLimits) {
        
        VOD_ACCOUNT_TRIG.accountMergeSampleLimit = true;
        if (affilIds != null) {
            
            Set<String> affDelSet = new Set<String> ();
            List <Affiliation_vod__c> AffilToUpdate = new List<Affiliation_vod__c> ();
            for (Id affilId : affilIds) {
                System.debug('VEEVADEBUG:Processing the affiliation Id =' + affilID);
                Affiliation_vod__c afil  = new Affiliation_vod__c (Id = affilId,
                                                                   External_Id_vod__c = '');
                AffilToUpdate.add(afil);
                
            }            
            
            try {
                VOD_AFFILIATIONS.setMerge(true);
                update AffilToUpdate;
                VOD_AFFILIATIONS.setMerge(false);
            }  catch (System.DmlException e) {
                System.debug('VEEVADEBUG: Entering Error Logic');
                List <Affiliation_vod__c> AffilToDelete = new List<Affiliation_vod__c> ();
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    VOD_AFFILIATIONS.setMerge(false);
                    // Process exception here
                    Id id  = e.getDmlId(i);
                    String codered = e.getDmlStatusCode(i);
                    System.Debug('VEEVADEBUG - Affiliation error- ' + id );                           
                    if (codered  == 'DUPLICATE_VALUE' || codered == 'FIELD_CUSTOM_VALIDATION_EXCEPTION') {
                        Affiliation_vod__c ntsf = new Affiliation_vod__c (Id = id);
                        AffilToDelete.add(ntsf);
                        affDelSet.add(id);
                    } else {
                        System.Debug(codered);  
                        System.Debug('VEEVADEBUG - THROW' + e );  
                        throw e;
                    }
                }
                System.Debug('VEEVADEBUG - Executing Delete' + e );
                try {
                    delete AffilToDelete;
                } catch (System.DmlException e2) {
                    for (Integer i = 0; i < e2.getNumDml(); i++) 
                    {
                        Id id2  = e2.getDmlId(i);
                        System.Debug ('VEEVADEBUG - Error deleting Affiliation:' + id2 + e2.getDmlStatusCode(i));
                    }
                    
                }
                System.Debug('VEEVADEBUG - Finished Delete' + e );
                AffilToUpdate.clear();
                for (Id affilId : affilIds) {
                    if (affDelSet.contains(affilId)) {
                        System.Debug('VEEVADEBUG - Skipping Affiliation because it was a dup- ' + affilId );
                        continue;
                    }
                    
                    System.Debug('VEEVADEBUG - Adding this affilID to be updated again :  ' + affilId );
                    Affiliation_vod__c afil  = new Affiliation_vod__c (Id = affilId, External_Id_vod__c = '');
                    AffilToUpdate.add(afil);
                    
                }
                
                try {
                    System.Debug('VEEVADEBUG - Affiliation - ' + AffilToUpdate );
                    VOD_AFFILIATIONS.setMerge(true);
                    update AffilToUpdate;
                    VOD_AFFILIATIONS.setMerge(false);
                }  catch (System.DmlException e2) {
                    VOD_AFFILIATIONS.setMerge(false);
                    System.Debug('VEEVADEBUG - throw e2 :  ');
                    
                    throw e2;
                }            
            }          
        }       
        if (tsfIds != null) {
            Set<String> tsfDelSet = new Set<String> ();
            System.Debug('TSF - ' + tsfIds );
            List <TSF_vod__c> tsfToUpdate = new List<TSF_vod__c> ();
            for (Id tsfid : tsfIds) {
                TSF_vod__c tsf  = new TSF_vod__c (Id = tsfid, 
                                                  External_Id_vod__c = '');
                tsfToUpdate.add(tsf);
            }
            try {
                update tsfToUpdate;
            }  catch ( System.DmlException e) {
                List <TSF_vod__c> tsfToDelete = new List<TSF_vod__c> ();
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    // Process exception here
                    Id id  = e.getDmlId(i);
                    String codered = e.getDmlStatusCode(i);
                    
                    if (codered  == 'DUPLICATE_VALUE') {
                        TSF_vod__c ntsf = new TSF_vod__c (Id = id);
                        System.Debug('VEEVADEBUG - Delete the following TSFId- ' + id );
                        tsfToDelete.add(ntsf);
                        tsfDelSet.add(id);
                    } else {  
                        System.Debug('VEEVADEBUG TSF MERGE ERR' + codered);  
                        System.Debug('VEEVADEBUG TSF MERGE ERR - THROW' + e );  
                        throw e;
                    }
                }
                
                try{
                    delete tsfToDelete;  
                } catch (System.DmlException e2) {
                    for (Integer i = 0; i < e2.getNumDml(); i++) 
                    {
                        Id id2  = e2.getDmlId(i);
                        System.Debug ('VEEVADEBUG - Error deleting TSF:' + id2 + e2.getDmlStatusCode(i));
                    }
                }
                
                tsfToUpdate.clear();                
                
                for (Id tsfid : tsfIds) {
                    if (tsfDelSet.contains(tsfid)) {
                        System.Debug('VEEVADEBUG - Skipping TSF because it was a dup- ' + tsfid );
                        continue;
                    }
                    TSF_vod__c tsf  = new TSF_vod__c (Id = tsfid, 
                                                      External_Id_vod__c = '');
                    tsfToUpdate.add(tsf);
                }
                
                try {
                    update tsfToUpdate;
                }  catch ( System.DmlException e2) {
                    System.Debug('VEEVADEBUG TSF - THROW e2 :  ' + e2);
                    throw e2;
                } 
                
            }
        }                  

        if (addrIds != null) {  
            System.Debug('Address - ' + addrIds );  
            List <Address_vod__c> AddressToUpdate = new List<Address_vod__c> ();            
            for (Id addid : addrIds) {                
                Address_vod__c addr  = new Address_vod__c (Id = addid);
                
                if ('ACTIVE'.equalsIgnoreCase(System.Label.ACCOUNT_ADDRESS_MERGE_BEHAVIOR) == true) {
                    addr.Inactive_vod__c  = false;
                } else if ('ASIS'.equalsIgnoreCase(System.Label.ACCOUNT_ADDRESS_MERGE_BEHAVIOR) == true) {
                    // do nothing
                }  else {
                    addr.Inactive_vod__c  = true;
                }
                
                if (setPrimaryAddress != null && setPrimaryAddress.contains(addid)) {
                    addr.Primary_vod__c = true;
                } else {
                    addr.Primary_vod__c = false;
                }
                
                AddressToUpdate.add(addr);
            }
            
            if (AddressToUpdate.size() > 0) {
                isAddressMerge = true;
                //adding a try catch for capturing if addresses are getting updated 
                try{
                    update AddressToUpdate;
                }
                
                catch (System.DmlException e3) {
                    for (Integer i = 0; i < e3.getNumDml(); i++) 
                    {
                        Id id3  = e3.getDmlId(i);
                        System.Debug ('VEEVADEBUG - Error updating address ' + id3 + e3.getDmlStatusCode(i));
                    }
                } 
                
                isAddressMerge = false;
            }
        } 
        
        if (prIds != null) {   
            System.Debug('PricingToUpdate - ' + prIds );     
            List <Pricing_Rule_vod__c> PricingToUpdate = new List<Pricing_Rule_vod__c> ();            
            for (Id prId : prIds) {               
                Pricing_Rule_vod__c pr  = new Pricing_Rule_vod__c (Id = prId,Active_vod__c = false);
                PricingToUpdate.add(pr);
            }
            
            if (PricingToUpdate.size() > 0) {
                update PricingToUpdate;
            }
        }
        
        List<Account_Territory_Loader_vod__c> updAtls = new List<Account_Territory_Loader_vod__c>();
        List<Account_Territory_Loader_vod__c> delAtls = new List<Account_Territory_Loader_vod__c>();
        List<MC_Cycle_Plan_Target_vod__c> losingMCTargets = new List<MC_Cycle_Plan_Target_vod__c>();
        if (losingAtlWinningAccountList != null) {
            Set<String> winningAcctIds = new Set<String>(losingAtlWinningAccountList.values());
            Set<Id> losingAtlIds = new Set<Id>(losingAtlWinningAccountList.keyset());
            Map<Id, Account> atlData = null;
            if (winningAcctIds.size() > 0) {
                atlData = new Map<Id, Account>([Select Id, (Select Id, Territory_vod__c 
                                                            From R00NT0000000lj9mMAA__r) // Account_Territory_Loader_vod__c
                                                From Account  
                                                Where Id In :winningAcctIds]);
            }          
            if (atlData != null) {
                for (Id tmpAcctId : atlData.keyset()) {
                    Account tmpAcctObj = atlData.get(tmpAcctId);
                    // If there is only one ATL between loser and winner, we dont need to combine territories and update/delete
                    if (tmpAcctObj.R00NT0000000lj9mMAA__r.size() > 1)  {
                        
                        Set<String> combinedTerritoryList = new Set<String>();
                        List<Id> tmpUpdAtls = new List<Id>();
                        
                        for (Account_Territory_Loader_vod__c tmpAtlObj : tmpAcctObj.R00NT0000000lj9mMAA__r) {
                            if (tmpAtlObj.Territory_vod__c != null) {
                                combinedTerritoryList.addAll(tmpAtlObj.Territory_vod__c.split(';'));
                            }
                            if (losingAtlIds.contains(tmpAtlObj.Id)) {
                                delAtls.add(new Account_Territory_Loader_vod__c(Id = tmpAtlObj.Id));
                            }
                            else { // in the case there are duplicates we cant resolve
                                tmpUpdAtls.add(tmpAtlObj.Id);
                            }
                        }
                        String combinedTerritoryValue = '';
                        for (String tmpTerr : combinedTerritoryList) {
                            if (tmpTerr.length() > 0) {
                                combinedTerritoryValue += ';' + tmpTerr;
                            }
                        }
                        if (combinedTerritoryValue.length() > 0) {
                            combinedTerritoryValue += ';';
                        }
                        for (Id tmpAtlId : tmpUpdAtls) {
                            updAtls.add(new Account_Territory_Loader_vod__c(Id=tmpAtlId, Territory_vod__c=combinedTerritoryValue));
                        }
                    } else if (tmpAcctObj.R00NT0000000lj9mMAA__r.size() == 1 && 
                               losingAtlIds.contains(tmpAcctObj.R00NT0000000lj9mMAA__r[0].Id)) {
                                   // if sole survivor is the losers' ATL, then need to reset external ID.
                                   updAtls.add(new Account_Territory_Loader_vod__c(Id=tmpAcctObj.R00NT0000000lj9mMAA__r[0].Id,
                                                                                   External_ID_vod__c = '')); 
                               }
                }
            }
        }
        if(mcCptIds != null) {             
            List<MC_Cycle_Plan_Target_vod__c> tempLosingTargets = null;                                
            tempLosingTargets = [Select Id, Status_vod__c, Cycle_Plan_vod__c, Target_vod__c, Location_vod__c
                                 FROM MC_Cycle_Plan_Target_vod__c
                                 Where Id in :mcCptIds.keySet()];          
            for (MC_Cycle_Plan_Target_vod__c target: tempLosingTargets) {
                List<MC_Cycle_Plan_Target_vod__c> cyclePlanTargets = [Select Id, Status_vod__c
                                                                      From MC_Cycle_Plan_Target_vod__c
                                                                      WHERE Target_vod__c = :target.Target_vod__c AND 
                                                                      Location_vod__c = :target.Location_vod__c AND
                                                                      Cycle_Plan_vod__c = :target.Cycle_Plan_vod__c AND
                                                                      Id != :target.id];
                if(cyclePlanTargets.size() > 0) {
                    target.Status_vod__c = 'Merged_vod';
                    losingMCTargets.add(target);
                }                       
            }
        }
        if (delAtls.size() > 0) {
            delete delAtls;
        }
        if (losingMCTargets.size() > 0) {            
            try {
                update losingMCTargets ;
            }
            catch (System.DmlException e) {
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    Id id  = e.getDmlId(i);
                    System.Debug ('VEEVADEBUG - Error MC Cycle Plan Target update: ' + id + e.getDmlStatusCode(i));
                }
            } 
        }                   
        if (updAtls.size() > 0) {          
            try {
                update updAtls;
            }
            catch (System.DmlException e) {
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    Id id  = e.getDmlId(i);
                    System.Debug ('VEEVADEBUG - Error updating ATL ' + id + e.getDmlStatusCode(i));
                }
            } 
        }
        if (sampleLimits != null) {
            System.Debug('Sample Limits to update - ' + sampleLimits.keySet());
            List <Sample_Limit_vod__c> limitsToUpdate = new List<Sample_Limit_vod__c> ();
            List <Sample_Limit_Transaction_vod__c> sltsToUpdate = new List<Sample_Limit_Transaction_vod__c> ();
            List<Sample_Limit_vod__c> oldSampleLimits = null;
            List<Sample_Limit_vod__c> winningSampleLimits = null;
            Map<Id, Sample_Limit_vod__c> winningLimitsToUpdate = new Map<Id, Sample_Limit_vod__c>();
            List<Sample_Limit_Transaction_vod__c> oldSLTs = null;
            Map<Id, Call2_vod__c> idsToCall = null;
            Set<Id> sltCalls = new Set<Id>();
            String limAccount, limProd, limUser, winningAccount, winningProd, winningUser, conflictId;
            oldSampleLimits = [Select Id, Merged_vod__c, Group_Id_vod__c, Merge_Conflict_Id_vod__c, Account_vod__c, Start_Date_vod__c, End_Date_vod__c,
                                Product_vod__c, User_vod__c, Limit_Quantity_vod__c, Limit_Amount_vod__c
                                FROM Sample_Limit_vod__c
                                Where Id in :sampleLimits.keySet()];
            List<Id> winningAccountIds = new List<Id>();
            for (Sample_Limit_vod__c lim : oldSampleLimits) {
                winningAccountIds.add(lim.Account_vod__c);
            }
            winningSampleLimits = [Select Id, Name, Merged_vod__c, Group_Id_vod__c, Account_vod__c, Start_Date_vod__c, End_Date_vod__c, Limit_Per_Call_vod__c,
                                    Disbursed_Quantity_vod__c, Product_vod__c, User_vod__c, Disbursed_Amount_vod__c, Limit_Quantity_vod__c, Limit_Amount_vod__c
                                FROM Sample_Limit_vod__c
                                Where Account_vod__c IN :winningAccountIds AND Id NOT IN :sampleLimits.keySet()];
            List <Sample_Limit_Transaction_vod__c> allOldSlts = [Select Id, Merged_vod__c, Sample_Limit_vod__c, Sample_Limit_Id_vod__c, Sample_Limit_Name_vod__c, Call2_vod__c, 
                                                                    Quantity_To_Disperse_vod__c, Amount_To_Disburse_vod__c, Product_vod__c, 
                                                                    Limit_Amount_vod__c, Limit_Quantity_vod__c
                                                                    FROM Sample_Limit_Transaction_vod__c WHERE Sample_Limit_vod__c IN :oldSampleLimits AND Call2_vod__c != null];
            Map<Id, List<Sample_Limit_Transaction_vod__c>> sampleLimitToSLTs = new Map<Id, List<Sample_Limit_Transaction_vod__c>>();
            for (Sample_Limit_Transaction_vod__c trans: allOldSlts) {
                if (sampleLimitToSLTs.get(trans.Sample_Limit_vod__c) == null)
                    sampleLimitToSLTs.put(trans.Sample_Limit_vod__c, new List<Sample_Limit_Transaction_vod__c>());
                sampleLimitToSLTs.get(trans.Sample_Limit_vod__c).add(trans);
            }
            for (Sample_Limit_vod__c lim : oldSampleLimits) {
                limAccount = lim.Account_vod__c;
                limProd = lim.Product_vod__c;
                limUser = lim.User_vod__c;
                if (lim.Account_vod__c == null)
                    limAccount = '';
                if (lim.Product_vod__c == null)
                    limProd = '';
                if (lim.User_vod__c == null)
                    limUser = '';
                conflictId = null;
                Sample_Limit_vod__c newLimit = new Sample_Limit_vod__c(Id = lim.Id, Merged_vod__c = true);
                for (Sample_Limit_vod__c winningLimit : winningSampleLimits) {
                    winningAccount = winningLimit.Account_vod__c;
                    winningProd = winningLimit.Product_vod__c;
                    winningUser = winningLimit.User_vod__c;
                    if (winningLimit.Account_vod__c == null)
                        winningAccount = '';
                    if (winningLimit.Product_vod__c == null)
                        winningProd = '';
                    if (winningLimit.User_vod__c == null)
                        winningUser = '';
                    if( VOD_CALL2_CHILD_COMMON.getLimitId(limAccount, limProd, limUser).equals(VOD_CALL2_CHILD_COMMON.getLimitId(winningAccount, winningProd, winningUser)) && 
                        VEEVA_CSL.IsOverLapping(lim, winningLimit) && sampleLimitIsSameType(lim, winningLimit))
                    {
                        conflictId = winningLimit.Id;
                        break;
                    }
                }
                oldSLTs = sampleLimitToSLTs.get(lim.Id);
                idsToCall = null;
                if (oldSLTs != null){
                    for (Sample_Limit_Transaction_vod__c slt : oldSLTs) {
                        sltCalls.add(slt.Call2_vod__c);
                    }
                    idsToCall = new Map<Id, Call2_vod__c>([SELECT Id, Call_Date_vod__c FROM Call2_vod__c where Id IN :sltCalls]);
                }
                if (conflictId != null) {
                    newLimit.Merge_Conflict_Id_vod__c = conflictId;
                    if (oldSLTs != null) {
                        for (Sample_Limit_Transaction_vod__c slt : oldSLTs) {
                            Sample_Limit_Transaction_vod__c newSlt = new Sample_Limit_Transaction_vod__c(Id = slt.Id, Merged_vod__c = true);
                            for (Sample_Limit_vod__c winningLimit : winningSampleLimits) {
                                if(idsToCall != null && idsToCall.get(slt.Call2_vod__c) != null && 
                                    (idsToCall.get(slt.Call2_vod__c).Call_Date_vod__c >= winningLimit.Start_Date_vod__c && 
                                        idsToCall.get(slt.Call2_vod__c).Call_Date_vod__c <= winningLimit.End_Date_vod__c ) &&
                                    isSameLimitType(slt, winningLimit))
                                {
                                    if (winningLimit.Product_vod__c == null || !winningLimit.Product_vod__c.equals(slt.Product_vod__c)) {
                                        continue;
                                    }
                                    newSlt.Sample_Limit_vod__c = winningLimit.Id;
                                    newSlt.Sample_Limit_Id_vod__c = winningLimit.Id;
                                    newSlt.Sample_Limit_Name_vod__c = winningLimit.Name;
                                    if (winningLimit.Limit_Per_Call_vod__c == false) {
                                        if (winningLimitsToUpdate.get(winningLimit.Id) == null) {
                                            winningLimitsToUpdate.put(winningLimit.Id, new Sample_Limit_vod__c(Id = winningLimit.Id, Disbursed_Quantity_vod__c = winningLimit.Disbursed_Quantity_vod__c,
                                                                                                                                    Disbursed_Amount_vod__c = winningLimit.Disbursed_Amount_vod__c));
                                        }
                                        Sample_Limit_vod__c winningLim = winningLimitsToUpdate.get(winningLimit.Id);

                                        if (winningLimit.Limit_Quantity_vod__c != null) {
                                            if (winningLim.Disbursed_Quantity_vod__c == null)
                                                winningLim.Disbursed_Quantity_vod__c = 0;
                                            if (slt.Quantity_To_Disperse_vod__c != null) 
                                                winningLim.Disbursed_Quantity_vod__c += slt.Quantity_To_Disperse_vod__c;
                                        }
                                        if (winningLimit.Limit_Amount_vod__c != null) {
                                            if (winningLim.Disbursed_Amount_vod__c == null)
                                                winningLim.Disbursed_Amount_vod__c = 0;
                                            if (slt.Amount_To_Disburse_vod__c != null)
                                                winningLim.Disbursed_Amount_vod__c += slt.Amount_To_Disburse_vod__c;
                                        } 
                                    }
                                    break;
                                }
                            }
                            sltsToUpdate.add(newSlt);
                        }
                    }
                } else {
                    newLimit.Group_Id_vod__c = VOD_CALL2_CHILD_COMMON.getLimitId(limAccount, limProd, limUser);
                    newLimit.Original_Account_Id_vod__c = sampleLimits.get(lim.Id);
                    if (oldSLTs != null) {
                        for (Sample_Limit_Transaction_vod__c slt : oldSLTs) {
                            Sample_Limit_Transaction_vod__c newSlt = new Sample_Limit_Transaction_vod__c(Id = slt.Id, Merged_vod__c = true);
                            sltsToUpdate.add(newSlt);
                        }
                    }
                }
                limitsToUpdate.add(newLimit);
            }
            if (!winningLimitsToUpdate.isEmpty()) {
                for (Sample_Limit_vod__c lim : winningLimitsToUpdate.values())
                    limitsToUpdate.add(lim);
            }
            if (limitsToUpdate.size() > 0) {
                update limitsToUpdate;
            }
            if (sltsToUpdate.size() > 0) {
                update sltsToUpdate;
            }
        }
        VOD_ACCOUNT_TRIG.accountMergeSampleLimit = false;
    }

    private static Boolean sampleLimitIsSameType(Sample_Limit_vod__c lim1, Sample_Limit_vod__c lim2) {
        if (lim1.Limit_Quantity_vod__c != null && lim2.Limit_Quantity_vod__c != null && 
                    lim1.Limit_Amount_vod__c != null && lim2.Limit_Amount_vod__c != null)
            return true; //both are quantity and amount limits
        else if (lim1.Limit_Amount_vod__c == null && lim2.Limit_Amount_vod__c == null)
            return true; //both are quantity limits
        else if (lim1.Limit_Quantity_vod__c == null && lim2.Limit_Quantity_vod__c == null)
            return true; //both are amount limits
        else 
            return false;
    }

    private static Boolean isSameLimitType(Sample_Limit_Transaction_vod__c slt, Sample_Limit_vod__c lim) {
        if (slt.Limit_Quantity_vod__c != null && lim.Limit_Quantity_vod__c != null && 
                    slt.Limit_Amount_vod__c != null && lim.Limit_Amount_vod__c != null)
            return true; //both are quantity and amount limits
        else if (slt.Limit_Amount_vod__c == null && lim.Limit_Amount_vod__c == null)
            return true; //both are quantity limits
        else if (slt.Limit_Quantity_vod__c == null && lim.Limit_Quantity_vod__c == null)
            return true; //both are amount limits
        else 
            return false;
    }
}