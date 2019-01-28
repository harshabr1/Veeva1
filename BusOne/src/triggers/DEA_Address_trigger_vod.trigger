trigger DEA_Address_trigger_vod on Address_vod__c bulk (after insert, after update) {

    // Check that the current user is the network integration user before attempting any DEA address cleanup
    boolean networkAdminUserWithNetworkEnabled = false;
    Schema.SObjectField netAdminFld = Schema.SObjectType.User.fields.getMap().get('Network_Admin_vod__c');
    if (netAdminFld != null) {
    	String userId = UserInfo.getUserId();
        List<SObject> thisUser = Database.query('Select Network_Admin_vod__c From User Where Id = :userId');
        if ((thisUser != null) && (thisUser.size() > 0)) {
        	if (thisUser[0].get(netAdminFld) == true) {
				networkAdminUserWithNetworkEnabled = VOD_Utils.isNetworkEnabled();
			}
		}
	}
    if (!networkAdminUserWithNetworkEnabled) {
		return;
    }

    Set<Id> changedDeaAddresses = new Set<Id>();
    Set<String> changedDeaLicenses = new Set<String>();
    Set<Id> accounts = new Set<Id>();
    
    // Collect addresses with new / modified dea license values
    for (Integer i = Trigger.new.size() - 1; i >= 0; i--) {
        Address_vod__c addr_new = Trigger.new[i];
        
        if (addr_new.DEA_vod__c == null || addr_new.DEA_vod__c.length() == 0) {
            // Skip this address since the DEA license field isn't set
            continue;
        }
        
        if (!('Valid_vod'.equals(addr_new.DEA_Status_vod__c))) {
            // We're only concerned about valid DEA licenses
            continue;
        }
        
        // Check for changed/added valid DEA licenses and save the information
        if (Trigger.isUpdate) {
			Address_vod__c addr_old = Trigger.old[i];
            if (addr_new.DEA_vod__c.equals(addr_old.DEA_vod__c) && 'Valid_vod'.equals(addr_old.DEA_Status_vod__c)) {
                continue;
            }
        }

        changedDeaLicenses.add(addr_new.DEA_vod__c);
        changedDeaAddresses.add(addr_new.Id);
        accounts.add(addr_new.Account_vod__c);
    }

    if (changedDeaAddresses.size() == 0) {
        System.debug('No changed DEA addresses found');
        return;
    } else {
        System.debug('Changed DEA addresses ' + changedDeaAddresses);
    }
    
    // Find addresses that have matching DEA license values
    List<Address_vod__c> deaAddrToClear = new List<Address_vod__c>();
    Schema.DescribeFieldResult deaEntityDescribe = Address_vod__c.Network_DEA_Entity_ID_vod__c.getDescribe();
    for (Address_vod__c addrToCheck : [Select Id From Address_vod__c Where Account_vod__c IN :accounts And DEA_vod__c In :changedDeaLicenses And DEA_Status_vod__c='Valid_vod']) {
        if (changedDeaAddresses.contains(addrToCheck.Id)) {
            // It found the one that's being changed, skip
            continue;
        }
        
        // Add to the set of addresses that will be cleared
        addrToCheck.DEA_Status_vod__c = 'Invalid_vod';

        if (deaEntityDescribe != null && deaEntityDescribe.isUpdateable()) {
            addrToCheck.Network_DEA_Entity_ID_vod__c = null;
        }
        deaAddrToClear.add(addrToCheck);
    }
    
    if (deaAddrToClear.size() == 0) {
        System.debug('No matching DEA license values found');
        return;
    }
    
    // Start clearing addresses
    System.debug('Clearing DEA license values for these addresses -  ' + deaAddrToClear); 
    try {
        update deaAddrToClear;
    } catch (System.DmlException e) {
        Integer numErrors = e.getNumDml();
        String error = '';
        for (Integer i = 0; i < numErrors; i++) {
            Id thisId = e.getDmlId(i);
            if (thisId != null) {
                error += thisId + ' - ' + e.getDmlMessage(i) + '\n';
            }
        }
        System.debug('Error handling DEA addr updates:' + error);
    }    
}