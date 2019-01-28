public class RecordTypeIdByName {
    
    private static final Map<String, Boolean> ALLOWED_OBJECTS = new Map<String, Boolean>();

    static{
        ALLOWED_OBJECTS.put('company_collaboration_vod__c', True);
        ALLOWED_OBJECTS.put('focus_area_vod__c', True);
        ALLOWED_OBJECTS.put('index_vod__c', True);
        ALLOWED_OBJECTS.put('position_vod__c', True);
    }

    public static void setRecordIdsByRecordNames(SObject[] sObjs) {
        if(sObjs.size() < 1) {
            return;
        }
        String objectType = sObjs[0].getSObjectType().getDescribe().getName()+'';
        Boolean allowed = ALLOWED_OBJECTS.get(objectType.toLowerCase());
        
        if(allowed != True) {
            return;
        }

        List <RecordType> recordTypes = [SELECT Id, DeveloperName from RecordType where SobjectType = :objectType];
        
        for(SObject sObj : sObjs) {
            setRecordTypeIdInInstance(sObj, recordTypes);
        }
    }
    
    private static void setRecordTypeIdInInstance(sObject sObj, List <RecordType> recordTypes) {
        if(sObj.get('RecordTypeId') != null) {
            return;
        }

        for(RecordType recordType : recordTypes) {
            if(recordType.DeveloperName == sObj.get('Record_Type_Name_vod__c')) {
                sObj.put('RecordTypeId', recordType.Id);
            }
        }
    }
}