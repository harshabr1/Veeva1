trigger VOD_CONTRACT_LINE_AFTER_INSUPD on Contract_Line_vod__c (after insert, after update) {
    // Skip this logic if Events Management (Speaker Qualifications) is not enabled
    if(!VEEVA_CONTRACT_HEADER_CLASS.isEmSpeakerQualificationEnabled()) {
        return;
    }

    List<Id> contractId = new List<Id>();
    Map<Id, Contract_Line_vod__c> lineMap = new Map<Id, Contract_Line_vod__c>();
    for (Contract_Line_vod__c line : Trigger.new) {
        if (line.Service_vod__c != null) {
            contractId.add(line.Contract_vod__c);
            lineMap.put(line.Id, line);
        }
    }

    Map<Id, Contract_vod__c> contractMap = new Map<Id, Contract_vod__c>([SELECT Id, Status_vod__c, EM_Catalog_vod__c,
                                                                                                   (SELECT EM_Speaker_vod__c, Status_vod__c
                                                                                                    FROM Contract_Partners_vod__r
                                                                                                    WHERE EM_Speaker_vod__c != null)
                                                                         FROM Contract_vod__c
                                                                         WHERE Id IN : contractId]);
    List<EM_Speaker_Qualification_vod__c> existingQualifications = [SELECT Id, Speaker_vod__c, Qualification_vod__c, Contract_Line_vod__c, Rate_vod__c, Rate_Type_vod__c, Start_Date_vod__c, End_Date_vod__c
                                                                    FROM EM_Speaker_Qualification_vod__c
                                                                    WHERE Contract_Line_vod__c IN : lineMap.keySet() AND Speaker_vod__c != null];
    Map<String, EM_Speaker_Qualification_vod__c> qualificationMap = new Map<String, EM_Speaker_Qualification_vod__c>();
    for (EM_Speaker_Qualification_vod__c qualification : existingQualifications) {
        String key = qualification.Contract_Line_vod__c + '_' + qualification.Speaker_vod__c;
        qualificationMap.put(key, qualification);
    }
    
    List<RecordType> rt = [SELECT Id FROM RecordType WHERE SObjectType = 'EM_Speaker_Qualification_vod__c' AND DeveloperName = 'Speaker_Service_vod'];
    Id rtId = (rt.size() == 1) ? rt.get(0).Id : null;
    boolean isMultiCurrency = Schema.getGlobalDescribe().get('EM_Speaker_Qualification_vod__c').getDescribe().fields.getMap().keySet().contains('CurrencyIsoCode');

    List<EM_Speaker_Qualification_vod__c> toUpdate = new List<EM_Speaker_Qualification_vod__c>();
    List<EM_Speaker_Qualification_vod__c> toInsert = new List<EM_Speaker_Qualification_vod__c>();
    for (Contract_Line_vod__c line : lineMap.values()) {
        Contract_vod__c contract = contractMap.get(line.Contract_vod__c);
        for (Contract_Partner_vod__c partner : contract.Contract_Partners_vod__r) {
            String key = line.Id + '_' + partner.EM_Speaker_vod__c;
            EM_Speaker_Qualification_vod__c qualification = qualificationMap.get(key);
            if (qualification != null) {
                qualification.Qualification_vod__c  = line.Service_vod__c;
                qualification.Rate_vod__c  = line.EM_Rate_vod__c;
                qualification.Rate_Type_vod__c  = line.EM_Rate_Type_vod__c;
                qualification.Start_Date_vod__c  = line.Start_Date_vod__c;
                qualification.End_Date_vod__c  = line.End_Date_vod__c;
                toUpdate.add(qualification);
            } else {
                if (contract.Status_vod__c == 'Activated_vod' &&
                    partner.Status_vod__c == 'Activated_vod') {
                    qualification = new EM_Speaker_Qualification_vod__c(
                        Contract_Line_vod__c = line.Id,
                        Qualification_vod__c  = line.Service_vod__c,
                        Rate_vod__c  = line.EM_Rate_vod__c,
                        Rate_Type_vod__c  = line.EM_Rate_Type_vod__c,
                        Start_Date_vod__c  = line.Start_Date_vod__c,
                        End_Date_vod__c  = line.End_Date_vod__c,
                        Speaker_vod__c = partner.EM_Speaker_vod__c,
                        Contract_Status_vod__c = 'Activated_vod',
                        Contract_Partner_Status_vod__c = 'Activated_vod',
                        RecordTypeId = rtId
                    );
                    if (isMultiCurrency) {
                        qualification.put('CurrencyIsoCode', line.get('CurrencyIsoCode'));
                    }
                    if(contract.EM_Catalog_vod__c != null) {
                        toInsert.add(qualification);
                    }
                }
            }
        }
    }

    if (toUpdate.size() > 0) {
        update toUpdate;
    }
    if (toInsert.size() > 0) {
        insert toInsert;
    }
}