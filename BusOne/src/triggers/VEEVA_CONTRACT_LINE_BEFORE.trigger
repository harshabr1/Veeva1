trigger VEEVA_CONTRACT_LINE_BEFORE on Contract_Line_vod__c (before insert, before delete, before update) {

    // This is being called as a result of the Contract After trigger. Skip all logic below.
    if(VEEVA_CONTRACT_HEADER_CLASS.isFromContractAfterTrigger()) {
        return;
    }

    List<Contract_Line_vod__c> modifiedLines = new List<Contract_Line_vod__c>();
    Set<Id> contractIds = new Set<Id>();

    if (Trigger.new != null) {
        modifiedLines.addAll(Trigger.new);
    } else if (Trigger.old != null) {
        modifiedLines.addAll(Trigger.old);
    }

    for(Contract_Line_vod__c line : modifiedLines) {
        contractIds.add(line.Contract_vod__c);
    }

    boolean isMultiCurrency = Schema.SObjectType.Contract_Line_vod__c.fields.getMap().containsKey('CurrencyIsoCode');
    String contractParentQuery;
    if(isMultiCurrency) {
        contractParentQuery = 'Select Id, Lock_vod__c, Override_Lock_vod__c, Template_vod__c, Agreement_vod__c, CurrencyIsoCode, Status_vod__c ' +
                'FROM Contract_vod__c ' +
                'WHERE Id IN :contractIds';
    } else {
        contractParentQuery = 'Select Id, Lock_vod__c, Override_Lock_vod__c, Template_vod__c, Agreement_vod__c, Status_vod__c ' +
                'FROM Contract_vod__c ' +
                'WHERE Id IN :contractIds';
    }
    Map<Id, Contract_vod__c> contractParents = new Map<Id, Contract_vod__c> (
        (List<Contract_vod__c>) Database.query(contractParentQuery)
    );

    // Locked contract check
    for(Contract_Line_vod__c line : modifiedLines) {
        Contract_Line_vod__c newLine = Trigger.newMap != null ? Trigger.newMap.get(line.Id) : null;
        Contract_Line_vod__c oldLine = Trigger.newMap != null ? Trigger.oldMap.get(line.Id) : null;
        Contract_vod__c contract = contractParents.get(line.Contract_vod__c);

        if((contract.Lock_vod__c && !contract.Override_Lock_vod__c &&
                !((newLine != null && newLine.Override_Lock_vod__c) || (oldLine != null && oldLine.Override_Lock_vod__c))) ||
                (contract.Status_vod__c == 'Signed_vod' && (line.Mobile_ID_vod__c == null || !Trigger.isInsert))) {
            line.addError('Contract is locked', false);
        } else if(oldLine != null && oldLine.Lock_vod__c && !oldLine.Override_Lock_vod__c &&
                (newLine == null || (newLine.Lock_vod__c && !newLine.Override_Lock_vod__c))) {
            line.addError('Contract Line is locked', false);
        } else if (newLine != null && newLine.Override_Lock_vod__c) {
            newLine.Override_Lock_vod__c = false;
        }
    }

    if(Trigger.new != null) {
        List<Contract_Line_vod__c> existingContractLines = [SELECT Product_vod__c, Contract_vod__c, Start_Date_vod__c, End_Date_vod__c, Service_vod__c, RecordType.DeveloperName
            FROM Contract_Line_vod__c
            WHERE Id NOT IN :modifiedLines AND Contract_vod__c IN :contractIds];
        Map<String, Set<Contract_Line_vod__c>> contractProductToLines = new Map<String, Set<Contract_Line_vod__c>>();
        Map<String, Set<Contract_Line_vod__c>> contractServiceToLines = new Map<String, Set<Contract_Line_vod__c>>();

        for(Contract_Line_vod__c line : existingContractLines) {
            if (line.Service_vod__c == null) {
                String contractProductCombo = line.Contract_vod__c + '' + line.Product_vod__c;
                if (!contractProductToLines.containsKey(contractProductCombo)) {
                    contractProductToLines.put(contractProductCombo, new Set<Contract_Line_vod__c>());
                }
                Set<Contract_Line_vod__c> lines = contractProductToLines.get(contractProductCombo);
                lines.add(line);
            }
            if (line.Service_vod__c != null && line.RecordType.DeveloperName == 'EM_Speaker_Contract_vod') {
                String contractServiceCombo = line.Contract_vod__c + '' + line.Service_vod__c;
                if (!contractServiceToLines.containsKey(contractServiceCombo)) {
                    contractServiceToLines.put(contractServiceCombo, new Set<Contract_Line_vod__c>());
                }
                Set<Contract_Line_vod__c> lines = contractServiceToLines.get(contractServiceCombo);
                lines.add(line);
            }
        }

        Map<Id, Product_vod__c> productIdentifierMap = new Map<Id, Product_vod__c>();
        for(Contract_Line_vod__c line : Trigger.new) {
            Contract_vod__c parentContract = contractParents.get(line.Contract_vod__c);

            //Check that start date <= end date
            if (line.Start_Date_vod__c != null && line.End_Date_vod__c != null && 
                line.Start_Date_vod__c > line.End_Date_vod__c) {
                line.addError(VOD_GET_ERROR_MSG.getErrorMsg('START_EQUAL_OR_LESS_THAN_END', 'Common'));    
            }
            
            if (line.Mandatory_Contract_Line_vod__c && !parentContract.Template_vod__c && !parentContract.Agreement_vod__c) {
                line.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('MANDATORY_CONTRACT_LINE_ERROR', 'Contracts', 'Mandatory Contract Lines are only allowed in Contract Templates and Agreements.'));
            }

            if (!parentContract.Template_vod__c && !parentContract.Agreement_vod__c) {
                // Unique product and service check for upserts
                Set<Contract_Line_vod__c> targetLines = new Set<Contract_Line_vod__c>();
                if (line.Service_vod__c == null) {
                    String contractProductCombo = line.Contract_vod__c + '' + line.Product_vod__c;
                    if (!contractProductToLines.containsKey(contractProductCombo)) {
                        contractProductToLines.put(contractProductCombo, new Set<Contract_Line_vod__c>());
                    }
                    targetLines.addAll(contractProductToLines.get(contractProductCombo));
                }
                if (line.Service_vod__c != null && line.RecordType.DeveloperName != 'Sales_vod' && line.RecordType.DeveloperName != 'Listing_vod') {
                    String contractServiceCombo = line.Contract_vod__c + '' + line.Service_vod__c;
                    if (!contractServiceToLines.containsKey(contractServiceCombo)) {
                        contractServiceToLines.put(contractServiceCombo, new Set<Contract_Line_vod__c>());
                    }
                    targetLines.addAll(contractServiceToLines.get(contractServiceCombo));
                }
                boolean addToTargetLines = true;
                for (Contract_Line_vod__c targetLine : targetLines) {
                    if ((line.Start_Date_vod__c == null && line.End_Date_vod__c == null) ||
                        (targetLine.Start_Date_vod__c == null && targetLine.End_Date_vod__c == null)) {
                        line.addError(VOD_GET_ERROR_MSG.getErrorMsg('CONTRACT_LINE_DUPLICATE_ERROR', 'CONTRACTS'));
                        addToTargetLines = false;
                    } else if ((line.Start_Date_vod__c == null && targetLine.Start_Date_vod__c == null) ||
                        (line.End_Date_vod__c == null && targetLine.End_Date_vod__c == null) ||
                        (line.Start_Date_vod__c == null && line.End_Date_vod__c >= targetLine.Start_Date_vod__c) ||
                        (line.End_Date_vod__c == null && line.Start_Date_vod__c <= targetLine.End_Date_vod__c) ||
                        (targetLine.Start_Date_vod__c == null && targetLine.End_Date_vod__c >= line.Start_Date_vod__c) ||
                        (targetLine.End_Date_vod__c == null && targetLine.Start_Date_vod__c <= line.End_Date_vod__c) ||
                        (line.Start_Date_vod__c >= targetLine.Start_Date_vod__c && line.Start_Date_vod__c <= targetLine.End_Date_vod__c) ||
                        (line.End_Date_vod__c >= targetLine.Start_Date_vod__c && line.End_Date_vod__c <= targetLine.End_Date_vod__c) ||
                        (line.Start_Date_vod__c <= targetLine.Start_Date_vod__c && line.End_Date_vod__c >= targetLine.End_Date_vod__c)) {
                        line.addError(VOD_GET_ERROR_MSG.getErrorMsg('CONTRACT_LINE_OVERLAPPING_DATES', 'CONTRACTS'));
                        addToTargetLines = false;
                    }
                }
                if (addToTargetLines) {
                    targetLines.add(line);
                }
            }
            if(line.Product_vod__c != null) {
                productIdentifierMap.put(line.Product_vod__c, null);
            }

            // Currency handling
            if(isMultiCurrency) {
                Contract_vod__c contract = contractParents.get(line.Contract_vod__c);
                String CurrencyIsoCode = (String) contract.get('CurrencyIsoCode');
                line.put('CurrencyIsoCode', CurrencyIsoCode);
            }
        }

        productIdentifierMap = new Map<Id, Product_vod__c>([SELECT Id, Product_Identifier_vod__c FROM Product_vod__c WHERE Id IN :productIdentifierMap.keySet()]);
        for(Contract_Line_vod__c line : Trigger.new) {
            if(line.Product_vod__c != null) {
                line.Product_Identifier_vod__c = productIdentifierMap.get(line.Product_vod__c).Product_Identifier_vod__c;
            }
        }
    }
    
    for(Contract_Line_vod__c line : modifiedLines) {
        Contract_vod__c contract = contractParents.get(line.Contract_vod__c);
        if (line.Mandatory_Contract_Line_vod__c && (contract.Agreement_vod__c || contract.Template_vod__c)) {
            if (Trigger.isDelete && !VEEVA_CONTRACT_HEADER_CLASS.isFromContractBeforeTrigger()) {
                line.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DELETE_MANDATORY_CONTRACT_LINE', 'Contracts', 'This Contract Line is mandatory and cannot be removed.'));
            } else if (Trigger.isUpdate) {
                Contract_Line_vod__c oldLine = Trigger.oldMap.get(line.Id);
                if (oldLine.Product_vod__c != line.Product_vod__c) {
                    line.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DELETE_MANDATORY_CONTRACT_LINE', 'Contracts', 'This Contract Line is mandatory and cannot be removed.'));
                }
            }
        }
    }
}