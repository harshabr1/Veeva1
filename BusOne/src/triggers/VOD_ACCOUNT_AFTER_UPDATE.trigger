// If an account's record type is changed, 
// update its territory's record type accordingly.
trigger VOD_ACCOUNT_AFTER_UPDATE on Account (after update) {
    
    // collect accounts with record type changes
    Set<String> acctIds = new Set<String>();
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        Account oldAcct = Trigger.old[i];
        Account newAcct = Trigger.new[i];
        if (oldAcct.RecordTypeId != newAcct.RecordTypeId)
           acctIds.add(newAcct.id);     
    }
    if (acctIds.size() > 0)
        VOD_ProcessTSF.updateRecType(acctIds);
    
    // process primary parent change
    boolean networkEnabled = VOD_Utils.isNetworkEnabled();
	if (!VOD_Utils.getUpdateChildAccount() && !networkEnabled) {
    	boolean isSimpleHierarchy = VeevaSettings.isSimpleHierarchy();
	    Set<String> toDelete = new Set<String>();
	    Map<String, Child_Account_vod__c> toUpsert = new Map<String, Child_Account_vod__c>();
	    Set<String> externIds = new Set<String>();
	    String extern;
	    for (Integer i = 0; i < Trigger.size; i++) {
	        String oldPrimary = Trigger.old[i].Primary_Parent_vod__c;
	        String newPrimary = Trigger.new[i].Primary_Parent_vod__c;
	        String id = Trigger.old[i].Id;
	        if (oldPrimary != newPrimary) {
	            if (isSimpleHierarchy) { 
	                if (oldPrimary != null) 
	                    toDelete.add(oldPrimary + '__' + id);
	                if (newPrimary != null)
	                   toDelete.add(newPrimary + '__' + id);
	            }
	            
                if (newPrimary != null) {
                    extern = newPrimary + '__' + id;
                    if (!isSimpleHierarchy)
                        externIds.add(extern);
                    toUpsert.put(extern, new Child_Account_vod__c(External_ID_vod__c = extern,
                               Parent_Account_vod__c = newPrimary,
                               Child_Account_vod__c = id));	
                }                
	        }
	    }
	    
	    if (externIds.size() > 0)
		    for (Child_Account_vod__c x : [select External_ID_vod__c from Child_Account_vod__c where External_ID_vod__c in :externIds ]){
		    	toUpsert.remove(x.External_ID_vod__c);
		    }
	    
	    try {
	    	VOD_Utils.setUpdateAccount(true);
	    	if (toDelete.size() > 0) {
	    	  for (Child_Account_vod__c[] x : [select Id from Child_Account_vod__c where External_ID_vod__c in :toDelete])
                    delete x;
	    	}
	        upsert toUpsert.values() External_ID_vod__c;
	    }finally {
	        VOD_Utils.setUpdateAccount(false);
	    }
    }
}