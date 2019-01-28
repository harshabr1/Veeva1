public with sharing class VOD_SHADOW_ACCOUNT {
	
	public static boolean isRejectedShadowAccount(Account account) {
		// "Customer Master Status" on an Account: i.e., our flag for whether or not this Account is a
    	// "Shadow Account". "Shadow Accounts" are simply unverified Network Accounts.
		String customerMasterStatus = account != null ? account.Customer_Master_Status_vod__c : null;
		
		return 'Rejected_vod'.equals(customerMasterStatus);
	}
	
	public static void rejectInvalidAccounts(List<Sobject> sobjects, List<String> accountIdFields) {
		String shadowAccountErrorMessage = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('ENDPOINT_NOT_VALID', 'NETWORK', 
				'Cannot create record because one or both of the referenced accounts are not valid');
	
		List<Id> accountsToQueryFor = new List<Id>();
		
		// Iterate once through the Child Accounts that we're about to insert/update, aggregating a list of Account
		// objects to query for (can't perform a relationship query without the Id of the Child Account or
		// Affiliation record, since the record doesn't exist yet).
	    for (Sobject record : sobjects) {
	    	
	    	// Add both endpoints to the list of Account payloads to query for later.        
	    	for (String accountIdField : accountIdFields) {
	    		accountsToQueryFor.add((Id) record.get(accountIdField));
	    	}
	    }
	    
	    // Do one giant query for all of the Account payloads.
	    Map<Id, Account> accountPayloads = new Map<Id, Account>(
	    	[select Id, Name, Customer_Master_Status_vod__c from Account where Id IN :accountsToQueryFor]);
	    			
	    // Iterate a second time through the records that we're about to insert/update, checking to see if any 
	    // of the Accounts are rejected. If so, bounce that record.
	    for (Sobject record : sobjects) {
	    	for (String accountIdField : accountIdFields) {
	    		Account account = accountPayloads.get((Id) record.get(accountIdField));
	    		
	    		// Bounce any Child Account records that attempt to affiliate unverified Accounts.
	    		if (VOD_SHADOW_ACCOUNT.isRejectedShadowAccount(account)) {
	    			record.addError(shadowAccountErrorMessage);
	    		}
	    	}
	    }
	}
}