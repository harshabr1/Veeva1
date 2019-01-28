trigger Address_before_del_vod on Address_vod__c bulk (before delete) {

    String ProfileId = UserInfo.getProfileId();
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
    Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
    boolean modAllData = false;
    if (pr != null && pr.PermissionsModifyAllData)
        modAllData = true;

    boolean isNetworkAdminUser = false;
    Schema.SObjectField netAdminFld = Schema.SObjectType.User.fields.getMap().get('Network_Admin_vod__c');
    if (netAdminFld != null) {
        String userId = UserInfo.getUserId();
        List<SObject> thisUser = Database.query('Select Network_Admin_vod__c From User Where Id = :userId');
        if ((thisUser != null) && (thisUser.size() > 0)) {
            if (thisUser[0].get(netAdminFld) == true) {
                isNetworkAdminUser = true;
            }
        }
    }

    Decimal addressDeletionProcess = 0.0;

    if (isNetworkAdminUser) {
        Network_Settings_vod__c networkSettings = Network_Settings_vod__c.getInstance();
        if (networkSettings != null) {
            addressDeletionProcess = networkSettings.NETWORK_ADDRESS_DELETION_PROCESS_vod__c;
        }
    }

    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Address_vod__c.fields.getMap();
    Schema.SObjectField Lock_vod = fieldMap.get('Lock_vod__c');
    Boolean lock = false;
    if (Lock_vod != null) {
        lock = true;
    }

    // Number of addresses for each account referenced by the addresses in the Trigger.old, indexed by the referenced account ID.
    // Only populated when address deletion set at 2.0.
    Map<Id, Integer> addrCountsForAcct = new Map<Id, Integer>();

    if (2.0 == addressDeletionProcess) {
        Set<Id> refAcctIds = new Set<Id>();
        for (Address_vod__c addr : Trigger.old) {
            refAcctIds.add(addr.Account_vod__c);
        }
        for (AggregateResult result : [Select Account_vod__c Id, COUNT(Id) addrCount from Address_vod__c
        where Account_vod__c in :refAcctIds
        group by Account_vod__c]) {
            addrCountsForAcct.put(result.Id, (Integer) result.get('addrCount'));
        }
    }

    Map <Id,Address_vod__c> addMap = new Map <Id,Address_vod__c> ([Select Id, (Select Id from Controlling_Address_vod__r), (Select Id from Call2_vod__r
    where Status_vod__c = 'Submitted_vod' or Status_vod__c = 'Saved_vod'), (Select Id from Medical_Events_vod__r)
    from Address_vod__c where ID in :Trigger.old]);


    for (Integer k =0; k < Trigger.old.size(); k++) {
        boolean isError = false;
        if (modAllData == false &&
                Trigger.old[k].Controlling_Address_vod__c != null &&
                VOD_ADDRESS_TRIG.getChildAccount() == false && !isNetworkAdminUser) {

            Trigger.old[k].Name.addError(bundle.getErrorMsg ('ADDRESS_DEL_LOCK_MSG'), false);
            isError = true;
        }

        if (modAllData == false && Trigger.old[k].DEA_Address_vod__c == true) {
            Trigger.old[k].Name.addError(bundle.getErrorMsg ('NO_DEL_DEA_ADDRESS'), false);
            isError = true;
        }

        if (lock == true && modAllData == false) {

            SObject obj = Trigger.old[k];

            Boolean checkLock = (Boolean) obj.get('Lock_vod__c');
            if (checkLock == true) {
                Trigger.old[k].Name.addError(bundle.getErrorMsg ('NO_DEL_LOCK_ADDRESS'), false);
                isError = true;
            }
        }

        Address_vod__c myAddItem = addMap.get(Trigger.old[k].Id);

        if (!isError && (1.0 == addressDeletionProcess || 2.0 == addressDeletionProcess)) {
            if (myAddItem != null && !myAddItem.Medical_Events_vod__r.isEmpty()) {
                // Do not delete when referenced by Medical Event
                Trigger.old[k].Name.addError(bundle.getErrorMsg('NO_DEL_ME_ADDRESS'), false);
                isError = true;
            }
        }

        Integer countForAcct = addrCountsForAcct.get(Trigger.old[k].Account_vod__c);
        if (countForAcct == null) {
            countForAcct = 0;
        }

        if (!isError && 2.0 == addressDeletionProcess) {
            if (Trigger.old[k].Primary_vod__c) {
                // Do not delete primary address
                Trigger.old[k].Name.addError(bundle.getErrorMsg('NO_DEL_PRIMARY_ADDRESS'), false);
                isError = true;
            } else if (countForAcct < 2) {
                // Do not delete last remaining address of a referenced account
                Trigger.old[k].Name.addError(bundle.getErrorMsg('NO_DEL_LAST_ADDRESS'), false);
                isError = true;
            }
        }

        if (isError == false) {
            if (!addrCountsForAcct.isEmpty()) {
                // This address is to be deleted, decrement the count
                addrCountsForAcct.put(Trigger.old[k].Account_vod__c, countForAcct - 1);
            }
            if (myAddItem != null) {
                for (Address_vod__c myChildren : myAddItem.Controlling_Address_vod__r) {
                    VOD_ADDRESS_TRIG.addDelSet(myChildren.Id);
                }
            }
        }
    }
}