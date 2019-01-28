trigger VEEVA_CONTRACT_AFTER_UPDATE on Contract_vod__c (after update) {
    // For updating record types of Contract Lines and Contract Partners
    List<Contract_vod__c> typeChangedContracts = new List<Contract_vod__c>();
    // For updating lock status of Contract Lines
    List<Contract_vod__c> lockChangedContracts = new List<Contract_vod__c>();
    // For updating the status of Contract Partners when Contract status changes from Signed_vod, for Contract Agreements
    List<Contract_vod__c> unsignedAgreements = new List<Contract_vod__c>();
    Set<String> contractTypeIds = new Set<String>();
    // For updating currency
    List<Contract_vod__c> currencyChangedContracts = new List<Contract_vod__c>();
    boolean isMultiCurrency = Schema.SObjectType.Contract_vod__c.fields.getMap().containsKey('CurrencyIsoCode');

    Map<String, Id> lineTypeNameToIdMap = new Map<String, Id>();
    Map<String, Id> partnerTypeNameToIdMap = new Map<String, Id>();

    for(Contract_vod__c newContract : Trigger.new) {
        Contract_vod__c oldContract = Trigger.oldMap.get(newContract.Id);

        if(oldContract.RecordTypeId != newContract.RecordTypeId) {
            typeChangedContracts.add(newContract);
            contractTypeIds.add(newContract.RecordTypeId);
        }

        if(oldContract != null && oldContract.Lock_vod__c != newContract.Lock_vod__c) {
            lockChangedContracts.add(newContract);
        }
        
        if(newContract.Agreement_vod__c && oldContract.Status_vod__c == 'Signed_vod' && newContract.Status_vod__c != 'Signed_vod') {
            unsignedAgreements.add(newContract);
        }

        if(isMultiCurrency) {
            if(oldContract != null && oldContract.get('CurrencyIsoCode') != newContract.get('CurrencyIsoCode')) {
                currencyChangedContracts.add(newContract);
            }
        }
    }

    if(typeChangedContracts.isEmpty() && lockChangedContracts.isEmpty() && currencyChangedContracts.isEmpty() && unsignedAgreements.isEmpty()) {
        return;
    }

    Set<String> typeDeveloperNames = new Set<String>();
    for(RecordType recordType : [SELECT DeveloperName FROM RecordType WHERE ID IN :contractTypeIds]) {
        typeDeveloperNames.add(recordType.DeveloperName);
    }

    for(RecordType recordType : [SELECT Id, DeveloperName, SobjectType
                                    FROM RecordType
                                    WHERE SobjectType IN ('Contract_Line_vod__c', 'Contract_Partner_vod__c')
                                        AND DeveloperName IN :typeDeveloperNames]) {
        if(recordType.SobjectType == 'Contract_Line_vod__c') {
            lineTypeNameToIdMap.put(recordType.DeveloperName, recordType.Id);
        } else {
            partnerTypeNameToIdMap.put(recordType.DeveloperName, recordType.Id);
        }
    }

    Map<Id, Contract_Line_vod__c> linesToUpdate = new Map<Id, Contract_Line_vod__c>();
    Map<Id, Contract_Partner_vod__c> partnersToUpdate = new Map<Id, Contract_Partner_vod__c>();

    for(Contract_Line_vod__c line : [SELECT Id, Contract_vod__r.RecordType.DeveloperName, RecordType.DeveloperName
                                        FROM Contract_Line_vod__c
                                        WHERE Contract_vod__c IN :typeChangedContracts]) {
        if(line.Contract_vod__r.RecordType.DeveloperName != line.RecordType.DeveloperName) {
            line.RecordTypeId = lineTypeNameToIdMap.get(line.Contract_vod__r.RecordType.DeveloperName);
            linesToUpdate.put(line.Id, line);
        }
    }

    for(Contract_Partner_vod__c partner : [SELECT Id, Contract_vod__r.RecordType.DeveloperName, RecordType.DeveloperName
                                        FROM Contract_Partner_vod__c
                                        WHERE Contract_vod__c IN :typeChangedContracts]) {
        if(partner.Contract_vod__r.RecordType.DeveloperName != partner.RecordType.DeveloperName) {
            partner.RecordTypeId = partnerTypeNameToIdMap.get(partner.Contract_vod__r.RecordType.DeveloperName);
            partnersToUpdate.put(partner.Id, partner);
        }
    }

    List<Contract_Line_vod__c> lockChangedLines = [SELECT Id, Contract_vod__r.Lock_vod__c
                                        FROM Contract_Line_vod__c
                                        WHERE Contract_vod__c IN :lockChangedContracts];
    for(Contract_Line_vod__c line : lockChangedLines) {
        boolean newLockValue = line.Contract_vod__r.Lock_vod__c;
        if(linesToUpdate.containsKey(line.Id)) {
            linesToUpdate.get(line.Id).Lock_vod__c = newLockValue;
            linesToUpdate.get(line.Id).Override_Lock_vod__c = true;
        } else {
            linesToUpdate.put(line.Id, new Contract_Line_vod__c(Id = line.Id, Lock_vod__c = newLockValue, Override_Lock_vod__c = true));
        }
    }
    
    for (Contract_Partner_vod__c partner : [SELECT Id, Status_vod__c FROM Contract_Partner_vod__c WHERE Contract_vod__c IN :unsignedAgreements]) {  
        if (partner.Status_vod__c == 'Signed_vod') {
            if (partnersToUpdate.containsKey(partner.Id)) {
                Contract_Partner_vod__c curPartner = partnersToUpdate.get(partner.Id);
                curPartner.Status_vod__c = 'Saved_vod';
                curPartner.Lock_vod__c = false;
                curPartner.Override_Lock_vod__c = true;
            } else {
                partnersToUpdate.put(partner.Id, new Contract_Partner_vod__c(Id = partner.Id, Lock_vod__c = false, Override_Lock_vod__c = true, Status_vod__c = 'Saved_vod'));
            }    
        }                                            
    }

    // We only need to update the LastModifiedDate so that offline platforms can detect these Contract Partners and force a sync
    for(Contract_Partner_vod__c partner : [SELECT Id FROM Contract_Partner_vod__c WHERE Contract_vod__c IN :lockChangedContracts]) {
        if(!partnersToUpdate.containsKey(partner.Id)) {
            partnersToUpdate.put(partner.Id, new Contract_Partner_vod__c(Id = partner.Id));
        }
    }

    if(isMultiCurrency) {
        for(Contract_Partner_vod__c partner : Database.query('SELECT Id, Contract_vod__r.CurrencyIsoCode, CurrencyIsoCode ' +
                                        'FROM Contract_Partner_vod__c ' +
                                        'WHERE Contract_vod__c IN :currencyChangedContracts')) {
            if(partner.get('CurrencyIsoCode') != partner.Contract_vod__r.get('CurrencyIsoCode')) {
                String CurrencyIsoCode = (String) partner.Contract_vod__r.get('CurrencyIsoCode');
                if(partnersToUpdate.containsKey(partner.Id)) {
                    partnersToUpdate.get(partner.Id).put('CurrencyIsoCode', CurrencyIsoCode);
                } else {
                    Contract_Partner_vod__c newPartner = new Contract_Partner_vod__c(Id = partner.Id);
                    newPartner.put('CurrencyIsoCode', CurrencyIsoCode);
                    partnersToUpdate.put(partner.Id, newPartner);
                }
            }
        }

        for(Contract_Line_vod__c line : Database.query('SELECT Id, Contract_vod__r.CurrencyIsoCode, CurrencyIsoCode ' +
                                        'FROM Contract_Line_vod__c ' +
                                        'WHERE Contract_vod__c IN :currencyChangedContracts')) {
            if(line.get('CurrencyIsoCode') != line.Contract_vod__r.get('CurrencyIsoCode')) {
                String CurrencyIsoCode = (String) line.Contract_vod__r.get('CurrencyIsoCode');
                if(linesToUpdate.containsKey(line.Id)) {
                    linesToUpdate.get(line.Id).put('CurrencyIsoCode', CurrencyIsoCode);
                } else {
                    Contract_Line_vod__c newLine = new Contract_Line_vod__c(Id = line.Id);
                    newLine.put('CurrencyIsoCode', CurrencyIsoCode);
                    linesToUpdate.put(line.Id, newLine);
                }
            }
        }
    }

    // Set this to true, so we can skip all logic in VEEVA_CONTRACT_LINE_BEFORE trigger
    VEEVA_CONTRACT_HEADER_CLASS.setFromContractAfterTrigger(true);

    Database.update(linesToUpdate.values());
    Database.update(partnersToUpdate.values());

    // Unset Override_Lock_vod__c for Contract Lines
    for(Contract_Line_vod__c line : lockChangedLines) {
        line.Override_Lock_vod__c = false;
    }
    Database.update(lockChangedLines);
}