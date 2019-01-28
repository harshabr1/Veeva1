trigger VOD_CONTRACT_PARTNER_AFTER_INS_UPD_DEL on Contract_Partner_vod__c (after insert, after delete, after update) {
    List<Contract_vod__c> contractsToUpdate = new List<Contract_vod__c>();
    Map<Id, Contract_Partner_vod__c> newMap = new Map<Id, Contract_Partner_vod__c>();
    Map<Id, Contract_Partner_vod__c> oldMap = new Map<Id, Contract_Partner_vod__c>();
    if (Trigger.isInsert || Trigger.isUpdate) {
        newMap = Trigger.newMap;
    }
    if (Trigger.isDelete || Trigger.isUpdate) {
        oldMap = Trigger.oldMap;
    }
    if (Trigger.isInsert || Trigger.isUpdate) {
        List<Id> newContractIds = new List<Id>();
        for (Contract_Partner_vod__c newPartner : Trigger.new) {
            Contract_Partner_vod__c oldPartner = oldMap.get(newPartner.Id);
            if (newPartner.Contract_vod__c != null &&
                (Trigger.isInsert || (oldPartner != null && newPartner.Contract_vod__c != oldPartner.Contract_vod__c))) {
                newContractIds.add(newPartner.Contract_vod__c);
            }
        }
        if (newContractIds.size() > 0) {
            for (Contract_vod__c contract : [SELECT Id, Lock_vod__c
                                             FROM Contract_vod__c
                                             WHERE Id IN :newContractIds
                                             AND Template_vod__c = true
                                             AND Account_Specific_Template_vod__c = false]) {
                Contract_vod__c acctContract =
                    new Contract_vod__c(Id = contract.Id,
                                        Account_Specific_Template_vod__c = true);
                if (contract.Lock_vod__c) {
                    acctContract.Override_Lock_vod__c = true;
                }
                contractsToUpdate.add(acctContract);
            }
        }
    }
    if (Trigger.isUpdate || Trigger.isDelete) {
        List<Id> oldContractIds = new List<Id>();
        for (Contract_Partner_vod__c oldPartner : Trigger.old) {
            Contract_Partner_vod__c newPartner = newMap.get(oldPartner.Id);
            if (oldPartner.Contract_vod__c != null && 
               (Trigger.isDelete || (newPartner != null && oldPartner.Contract_vod__c != newPartner.Contract_vod__c))) {
                oldContractIds.add(oldPartner.Contract_vod__c);
            }
        }
        if (oldContractIds.size() > 0) {
            for (Contract_vod__c contract : [SELECT Id, Lock_vod__c,
                                                (SELECT Id 
                                                 FROM Contract_Partners_vod__r)
                                             FROM Contract_vod__c
                                             WHERE Id IN :oldContractIds
                                             AND Template_vod__c = true
                                             AND Account_Specific_Template_vod__c = true]) {
                List<Contract_Partner_vod__c> contractPartners = contract.Contract_Partners_vod__r;
                if (contractPartners == null || contractPartners.size() == 0) {                                 
                    Contract_vod__c uncheckContract =
                        new Contract_vod__c(Id=contract.Id,
                                            Account_Specific_Template_vod__c= false);
                    if (contract.Lock_vod__c) {
                        uncheckContract.Override_Lock_vod__c = true;
                    }
                    contractsToUpdate.add(uncheckContract);
                }
            }
        }
    }
    update contractsToUpdate;
}