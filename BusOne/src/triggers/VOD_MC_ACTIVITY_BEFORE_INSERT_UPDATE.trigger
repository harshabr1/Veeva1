trigger VOD_MC_ACTIVITY_BEFORE_INSERT_UPDATE on Multichannel_Activity_vod__c (before insert, before update) 
{
    Map<String, Id> recordTypeIdByDevName = new Map<String, Id>();
    Map<Id, String> recordTypeNameById = new Map<Id, String>();
    Id defaultRecordTypeId;
    List<RecordType> recordTypes = [SELECT Id, DeveloperName from RecordType where SobjectType = 'Multichannel_Activity_vod__c'];
    for (RecordType recordType : recordTypes) {
        recordTypeIdByDevName.put(recordType.DeveloperName, recordType.Id);
        recordTypeNameById.put(recordType.Id, recordType.DeveloperName);
    }
    for (RecordTypeInfo rtInfo : Multichannel_Activity_vod__c.SObjectType.getDescribe().getRecordTypeInfos()) {
        if (rtInfo.isDefaultRecordTypeMapping()) {
            defaultRecordTypeId = rtInfo.getRecordTypeId();
            System.debug('Default record type ' + rtInfo);
        }
    }
    Map<String,Multichannel_Activity_vod__c> mcMap = new Map<String,Multichannel_Activity_vod__c>();
    List<String> mapIds = new List<String>();
    for (Integer i=0; i < Trigger.size; i++) {
        Multichannel_Activity_vod__c newRecord = Trigger.new[i];
        Multichannel_Activity_vod__c oldRecord = (Trigger.isInsert ? null : Trigger.old[i]);
        if (newRecord.Account_External_ID_Map_vod__c != null ) {
            mcMap.put(newRecord.Account_External_ID_Map_vod__c,newRecord);
            mapIds.add(newRecord.Account_External_ID_Map_vod__c);
        }
        
        if ((Trigger.isInsert && newRecord.Record_Type_Name_vod__c != null) ||
            (Trigger.isUpdate && newRecord.Record_Type_Name_vod__c != oldRecord.Record_Type_Name_vod__c)){
        
            Id recordTypeId = recordTypeIdByDevName.get(newRecord.Record_Type_Name_vod__c);
            if (recordTypeId != null) {
                newRecord.RecordTypeId = recordTypeId;
            } else {
                system.debug(newRecord.Record_Type_Name_vod__c + ' does not exist. Use the default recordtype.');
                String devName = recordTypeNameById.get(defaultRecordTypeId);
                newRecord.Record_Type_Name_vod__c = devName;
                newRecord.RecordTypeId = recordTypeIdByDevName.get(devName);
            }
        } else if ((Trigger.isInsert && newRecord.RecordTypeId != null) ||
                   (Trigger.isUpdate && newRecord.RecordTypeId != oldRecord.RecordTypeId)) {
            
            String devName = recordTypeNameById.get(newRecord.RecordTypeId);
            if (devName != null) {
                newRecord.Record_Type_Name_vod__c = devName;                           
            }
        }    
    }
    
    if (mapIds != null && mapIds.size()> 0 ) {
        List<Account_External_ID_Map_vod__c> extIdMapRecords= [SELECT Account_vod__c,Id from Account_External_ID_Map_vod__c where Account_vod__c != null and Id in :mapIds ];
        if  (extIdMapRecords != null && extIdMapRecords.size() > 0 ) {
            for(Account_External_ID_Map_vod__c aem: extIdMapRecords ) {
                Multichannel_Activity_vod__c entity = mcMap.get(aem.Id);
                if (entity != null) {
                    entity.Account_vod__c = aem.Account_vod__c;
                }
            }
        }   
    } 
}