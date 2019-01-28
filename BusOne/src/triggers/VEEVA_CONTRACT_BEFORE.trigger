trigger VEEVA_CONTRACT_BEFORE on Contract_vod__c (before insert, before delete, before update) {
    Set<Id> contractIds = new Set<Id>();
    Map<Id, Contract_vod__c> oldMap = new Map<Id, Contract_vod__c>();
    VEEVA_CONTRACT_HEADER_CLASS.setFromContractBeforeTrigger(true);

    if(Trigger.old != null) {
        oldMap = Trigger.oldMap;
        contractIds.addAll(oldMap.keySet());
    }

    if(Trigger.new != null) {
        for(Contract_vod__c newContract : Trigger.new) {
            Contract_vod__c oldContract = oldMap.get(newContract.Id);

            boolean activated = newContract.Status_vod__c == 'Activated_vod';
            boolean locked = newContract.Lock_vod__c;

            if(activated || locked && !(activated && locked)) {
                if(oldContract != null) {
                    if(locked != oldContract.Lock_vod__c) {
                        if(locked) {
                            newContract.Status_vod__c = 'Activated_vod';
                        } else {
                            newContract.Status_vod__c = 'Draft_vod';
                        }
                    } else if(oldContract.Status_vod__c != newContract.Status_vod__c) {
                        if(activated) {
                            newContract.Lock_vod__c = true;
                        } else {
                            newContract.Lock_vod__c = false;
                        }
                    } else {
                        newContract.Status_vod__c = 'Activated_vod';
                        newContract.Lock_vod__c = true;
                    }
                } else {
                    newContract.Status_vod__c = 'Activated_vod';
                    newContract.Lock_vod__c = true;
                }
            }

            if(oldContract != null) {
                if(oldContract.Lock_vod__c && !oldContract.Override_Lock_vod__c
                        && newContract.Lock_vod__c && !newContract.Override_Lock_vod__c) {
                    newContract.addError('Contract is locked', false);
                } else if (newContract.Override_Lock_vod__c) {
                    newContract.Override_Lock_vod__c = false;
                }
            }
        }
    } else {
        for(Contract_vod__c oldContract : Trigger.old) {
            if(oldContract.Lock_vod__c) {
                oldContract.addError('Contract is locked', false);
            }
        }
    }
}