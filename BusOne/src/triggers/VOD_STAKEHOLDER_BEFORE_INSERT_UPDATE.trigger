trigger VOD_STAKEHOLDER_BEFORE_INSERT_UPDATE on Stakeholder_Preference_vod__c (before insert, before update) 
{
    Map<String, Id> recordTypeIdByDevName = new Map<String, Id>();
    Map<Id, String> recordTypeNameById = new Map<Id, String>();
    List<RecordType> recordTypes = [SELECT Id, DeveloperName from RecordType where SobjectType = 'Stakeholder_Preference_vod__c'];
    for (RecordType recordType : recordTypes) {
        recordTypeIdByDevName.put(recordType.DeveloperName, recordType.Id);
        recordTypeNameById.put(recordType.Id, recordType.DeveloperName);
    }
    for (Integer i=0; i < Trigger.size; i++) {
        Stakeholder_Preference_vod__c newRecord = Trigger.new[i];
        Stakeholder_Preference_vod__c oldRecord = (Trigger.isInsert ? null : Trigger.old[i]);
        
        if ((Trigger.isInsert && newRecord.Record_Type_Name_vod__c != null) ||
            (Trigger.isUpdate && newRecord.Record_Type_Name_vod__c != oldRecord.Record_Type_Name_vod__c)){
        
            Id recordTypeId = recordTypeIdByDevName.get(newRecord.Record_Type_Name_vod__c);
            if (recordTypeId != null) {
                newRecord.RecordTypeId = recordTypeId;
            }
        } else if ((Trigger.isInsert && newRecord.RecordTypeId != null) ||
                   (Trigger.isUpdate && newRecord.RecordTypeId != oldRecord.RecordTypeId)) {
            
            String devName = recordTypeNameById.get(newRecord.RecordTypeId);
            if (devName != null) {
                newRecord.Record_Type_Name_vod__c = devName;                           
            }
        }    
    }  
}