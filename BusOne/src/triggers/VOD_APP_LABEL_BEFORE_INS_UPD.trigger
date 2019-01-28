trigger VOD_APP_LABEL_BEFORE_INS_UPD on Application_Label_vod__c (before insert, before update) {

    Map<String, Id> recordTypeIdByDevName = new Map<String, Id>();
    Map<Id, String> recordTypeNameById = new Map<Id, String>();
    List<RecordType> recordTypes = [SELECT Id, DeveloperName from RecordType where SobjectType = 'Application_Label_vod__c'];
    for (RecordType recordType : recordTypes) {
        recordTypeIdByDevName.put(recordType.DeveloperName, recordType.Id);
        recordTypeNameById.put(recordType.Id, recordType.DeveloperName);
    }
    Map<String, Map<String, Application_Label_vod__c>> recordTypeLabelByObjectAndDevName = 
        new Map<String, Map<String, Application_Label_vod__c>>();
    
    for (Integer i=0; i < Trigger.size; i++) {
        Application_Label_vod__c newRecord = Trigger.new[i];
        Application_Label_vod__c oldRecord = (Trigger.isInsert ? null : Trigger.old[i]);
        
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
        if ('RecordType'.equals(newRecord.Record_Type_Name_vod__c) && newRecord.Object_API_Name_vod__c != null
           && newRecord.Component_Name_vod__c != null) {
               String objectType = newRecord.Object_API_Name_vod__c;
               if ('PersonAccount'.equals(objectType)) {
                   objectType = 'Account';
               }
        	   Map<String, Application_Label_vod__c> objectMap = recordTypeLabelByObjectAndDevName.get(objectType);
               if (objectMap == null) {
                   objectMap = new Map<String, Application_Label_vod__c>();
                   recordTypeLabelByObjectAndDevName.put(objectType, objectMap);
               }
               objectMap.put(newRecord.Component_Name_vod__c, newRecord);
        }
    }

    if (recordTypeLabelByObjectAndDevName.size() > 0) {
        for (RecordType recordType : 
             [SELECT Id, SobjectType, DeveloperName FROM RecordType where SobjectType IN :recordTypeLabelByObjectAndDevName.keySet()]) {
            Map<String, Application_Label_vod__c> objectMap = recordTypeLabelByObjectAndDevName.get(recordType.SobjectType);
            if (objectMap != null) {
                Application_Label_vod__c appLabel = objectMap.get(recordType.DeveloperName);
                if (appLabel != null) {
                    appLabel.Target_Record_Type_ID_vod__c = recordType.Id;
                }
            }
        }
    }    
}