trigger OH_Address_trigger_vod on Address_vod__c bulk (after insert, after update) {

    // Check that the current user is the network integration user before attempting any OH address cleanup
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

    Set<Id> changedOHAddresses = new Set<Id>();
    Set<String> changedOHLicenses = new Set<String>();
    Set<Id> accounts = new Set<Id>();
    
    // Collect addresses with new / modified OH license values
    for (Integer i = Trigger.new.size() - 1; i >= 0; i--) {
        Address_vod__c addr_new = Trigger.new[i];
        
        if (addr_new.State_Distributor_vod__c == null || addr_new.State_Distributor_vod__c.length() == 0) {
            // Skip this address since the OH license field isn't set
            continue;
        }

        if (!('Valid_vod'.equals(addr_new.State_Distributor_Status_vod__c))) {
            // We're only concerned about valid OH licenses
            continue;
        }
        
        // Check for changed/added valid OH licenses and save the information
        if (Trigger.isUpdate) {
            Address_vod__c addr_old = Trigger.old[i];
            if (addr_new.State_Distributor_vod__c.equals(addr_old.State_Distributor_vod__c) && 'Valid_vod'.equals(addr_old.State_Distributor_Status_vod__c)) {
                continue;
            }
        }

        changedOHLicenses.add(addr_new.State_Distributor_vod__c);
        changedOHAddresses.add(addr_new.Id);
        accounts.add(addr_new.Account_vod__c);
    }

    if (changedOHAddresses.size() == 0) {
        System.debug('No changed OH addresses found');
        return;
    } else {
        System.debug('Changed OH addresses ' + changedOHAddresses);
    }
    
    // Find addresses that have matching OH license values
    List<Address_vod__c> ohAddrToClear = new List<Address_vod__c>();
    Schema.DescribeFieldResult ohEntityDescribe = Address_vod__c.Network_Distributor_Entity_ID_vod__c.getDescribe();
    for (Address_vod__c addrToCheck : [Select Id From Address_vod__c Where Account_vod__c IN :accounts And State_Distributor_vod__c In :changedOHLicenses And State_Distributor_Status_vod__c='Valid_vod']) {
        if (changedOHAddresses.contains(addrToCheck.Id)) {
            // It found the one that's being changed, skip
            continue;
        }
        
        // Add to the set of addresses that will be cleared
        addrToCheck.State_Distributor_Status_vod__c = 'Invalid_vod';

        if (ohEntityDescribe != null && ohEntityDescribe.isUpdateable()) {
            addrToCheck.Network_Distributor_Entity_ID_vod__c = null;
        }
        ohAddrToClear.add(addrToCheck);
    }
    
    if (ohAddrToClear.size() == 0) {
        System.debug('No matching OH license values found');
        return;
    }
    
    // Start clearing addresses
    System.debug('Clearing OH license values for these addresses -  ' + ohAddrToClear);
    try {
        update ohAddrToClear;
    } catch (System.DmlException e) {
        Integer numErrors = e.getNumDml();
        String error = '';
        for (Integer i = 0; i < numErrors; i++) {
            Id thisId = e.getDmlId(i);
            if (thisId != null) {
                error += thisId + ' - ' + e.getDmlMessage(i) + '\n';
            }
        }
        System.debug('Error handling OH addr updates:' + error);
    }    
}