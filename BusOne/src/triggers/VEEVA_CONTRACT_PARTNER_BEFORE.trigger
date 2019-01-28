trigger VEEVA_CONTRACT_PARTNER_BEFORE on Contract_Partner_vod__c (before insert, before delete, before update) {

    // This is being called as a result of the Contract After trigger. Skip all logic below.
    if(VEEVA_CONTRACT_HEADER_CLASS.isFromContractAfterTrigger()) {
        return;
    }

    Set<Id> contractIds = new Set<Id>();
    Map<Id, Contract_Partner_vod__c> oldMap = new Map<Id, Contract_Partner_vod__c>();

    if(Trigger.old != null) {
        oldMap = Trigger.oldMap;
        for(Contract_Partner_vod__c oldContractPartner : Trigger.old) {
            contractIds.add(oldContractPartner.Contract_vod__c);
        }
    }
    if(Trigger.new != null) {
        for(Contract_Partner_vod__c newContractPartner : Trigger.new) {
            contractIds.add(newContractPartner.Contract_vod__c);
        }
    }

    boolean isMultiCurrency = Schema.SObjectType.Contract_Partner_vod__c.fields.getMap().containsKey('CurrencyIsoCode');
    String contractParentQuery;
    if(isMultiCurrency) {
        contractParentQuery = 'Select Id, CurrencyIsoCode, Template_vod__c, Status_vod__c, Lock_vod__c ' +
                'FROM Contract_vod__c ' +
                'WHERE Id IN :contractIds';
    } else {
        contractParentQuery = 'Select Id, Template_vod__c, Status_vod__c, Lock_vod__c ' +
                'FROM Contract_vod__c ' +
                'WHERE Id IN :contractIds';
    }
    Map<Id, Contract_vod__c> contractParents = new Map<Id, Contract_vod__c> (
        (List<Contract_vod__c>) Database.query(contractParentQuery)
    );

    if(Trigger.new != null) {
        for(Contract_Partner_vod__c newContractPartner : Trigger.new) {
            Contract_vod__c contract = contractParents.get(newContractPartner.Contract_vod__c);
            if (contract != null && contract.Template_vod__c && (contract.Lock_vod__c || contract.Status_vod__c == 'Activated_vod')) {
                newcontractPartner.addError('Contract is locked', false);
            }
            Contract_Partner_vod__c oldContractPartner = oldMap.get(newContractPartner.Id);

            // Locked Contract Partner check
            boolean activated = newContractPartner.Status_vod__c == 'Activated_vod';
            boolean alreadySigned = oldContractPartner != null && oldContractPartner.Status_vod__c == 'Signed_vod';
            boolean locked = newContractPartner.Lock_vod__c;

            if(activated || locked && !(activated && locked)) {
                if(oldContractPartner != null) {
                    if(locked != oldContractPartner.Lock_vod__c) {
                        if(locked) {
                            newContractPartner.Status_vod__c = 'Activated_vod';
                        } else {
                            newContractPartner.Status_vod__c = 'Saved_vod';
                        }
                    } else if(oldContractPartner.Status_vod__c != newContractPartner.Status_vod__c) {
                        if(activated) {
                            newContractPartner.Lock_vod__c = true;
                        } else {
                            newContractPartner.Lock_vod__c = false;
                        }
                    } else {
                        newContractPartner.Status_vod__c = 'Activated_vod';
                        newContractPartner.Lock_vod__c = true;
                    }
                } else {
                    newContractPartner.Status_vod__c = 'Activated_vod';
                    newContractPartner.Lock_vod__c = true;
                }
            }

            if((oldContractPartner!= null && oldContractPartner.Lock_vod__c && !oldContractPartner.Override_Lock_vod__c
                    && newContractPartner.Lock_vod__c && !newContractPartner.Override_Lock_vod__c) && (!newContractPartner.Agreement_vod__c || alreadySigned)) {
                newContractPartner.addError('Contract Partner is locked', false);
            }

            // Currency handling
            if(isMultiCurrency && contract != null) {
                String CurrencyIsoCode = (String) contract.get('CurrencyIsoCode');
                newContractPartner.put('CurrencyIsoCode', CurrencyIsoCode);
            }

            // Stamping Device Type for calls that were created online
            if (Trigger.isInsert && (newContractPartner.Device_Type_vod__c == null || newContractPartner.Device_Type_vod__c.trim() == '' )) {
                newContractPartner.Device_Type_vod__c = 'Online_vod';
            }
        }
    } else {
        for(Contract_Partner_vod__c oldContractPartner : Trigger.old) {
            if(oldContractPartner.Lock_vod__c || oldContractPartner.Status_vod__c == 'Signed_vod') {
                oldContractPartner.addError('Contract Partner is locked', false);
            }
            Contract_vod__c contract = contractParents.get(oldContractPartner.Contract_vod__c);
            if (contract != null && contract.Template_vod__c && (contract.Lock_vod__c || contract.Status_vod__c == 'Activated_vod')) {
                oldcontractPartner.addError('Contract is locked', false);
            }
        }
    }
}