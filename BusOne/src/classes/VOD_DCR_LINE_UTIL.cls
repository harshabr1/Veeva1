public class VOD_DCR_LINE_UTIL {

	static final Map<String, String> LOCAL_BY_FIELD_NAME = new Map<String, String>{
        'Old_Value_vod__c' => 'Old_Localized_Value_vod__c',
        'New_Value_vod__c' => 'New_Localized_Value_vod__c',
        'Final_Value_vod__c' => 'Final_Localized_Value_vod__c'};
    static final String SEP = ';;';
	
    public static void addPossibleIdChanges(Data_Change_Request_Line_vod__c original,
                                           Data_Change_Request_Line_vod__c changed,
                                            List<String> possibleIdChanges) 
    {
        for (String field : LOCAL_BY_FIELD_NAME.keySet()) {
        	Object changedValue = changed.get(field);
            Object changedLocalized = changed.get(LOCAL_BY_FIELD_NAME.get(field));
            Object originalValue = null;
            Object originalLocalized = null;
            if (original != null) {
                originalValue = original.get(field);
                originalLocalized = original.get(LOCAL_BY_FIELD_NAME.get(field));
            }
            
            if (changedValue instanceof String) {
                String changedString = (String) changedValue;
                // add to possible list if lookup value is changed, but localized value not changed or is same as value, to allow setting externally
                // OR if change localized is null, so any change to line can refresh the localized value if it wasn't set already
                // AND do a simple length check to see if possible ID. Will check describe later to make sure. 
                if (((changedValue != originalValue && (changedLocalized == originalLocalized || changedLocalized == changedValue)) 
                     || changedLocalized == null) 
                    && (changedString.length() == 15 || changedString.length() == 18))  {
                    // potential updated ID - will check describes later to verify is lookup
                    List<String> details = new List<String>{changed.Id, changed.Field_API_Name_vod__c, field, changedString};
               		String detailStruct = String.join(details, SEP);
                    possibleIdChanges.add(detailStruct);
                }
            }
        }                                            
    }
    
    @future(callout=false)
    public static void processPossibleIdChanges(List<String> possibleIdChanges) {
        List<Data_Change_Request_Line_vod__c> toUpdate = collectUpdates(possibleIdChanges);
        if (toUpdate.size() > 0) {
            update toUpdate;
        }
    }
    
    static List<Data_Change_Request_Line_vod__c> collectUpdates(List<String> possibleIdChangeText) {
        
        Map<String, List<IdChange>> possibleIdChanges = parseText(possibleIdChangeText);
        updateObjectReferences(possibleIdChanges);
        Map<String, Set<Id>> idsToQueryByObjectName = collectQueries(possibleIdChanges);
        Map<String, String> nameById = executeNameQueries(idsToQueryByObjectName);
        List<Data_Change_Request_Line_vod__c> toUpdate = createUpdates(possibleIdChanges, nameById);
		return toUpdate;
    }
    
    static Map<String, List<IdChange>> parseText(List<String> possibleIdChangeText) {
        Map<String, List<IdChange>> possibleIdChanges = new Map<String, List<IdChange>>();
        for (String changeText : possibleIdChangeText) {
            String[] elements = changeText.split(SEP);
            if (elements.size() == 4) {
                IdChange change = new IdChange();
                change.dcrLineId = elements[0];
                change.referenceFieldName = elements[1];
                change.dcrLineFieldName = elements[2];
                change.referenceFieldValue = elements[3];
                List<IdChange> changes = possibleIdChanges.get(change.dcrLineId);
                if (changes == null) {
                    changes = new List<IdChange>();
                    possibleIdChanges.put(change.dcrLineId, changes);
                }
                changes.add(change);
            }
        }
        return possibleIdChanges;
    } 
    
    static void updateObjectReferences(Map<String, List<IdChange>> possibleIdChanges) {
    	Map<Id, RecordType> dcrRecordTypes = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Data_Change_Request_vod__c']);
        
        Map<String, RecordType> parentDcrTypeByLineId = new Map<String, RecordType>();
        for (Data_Change_Request_Line_vod__c line : [SELECT Id, Data_Change_Request_vod__r.RecordTypeId 
                                                     FROM Data_Change_Request_Line_vod__c 
                                                     WHERE Id IN :possibleIdChanges.keySet()]) 
        {
        	List<IdChange> changes = possibleIdChanges.get(line.Id);
            RecordType dcrRecordType = dcrRecordTypes.get(line.Data_Change_Request_vod__r.RecordTypeId);
            DescribeSObjectResult referenceDescribe = null;
            if (dcrRecordType.DeveloperName == 'Account_vod') {
            	referenceDescribe = Account.sObjectType.getDescribe();    
            } else if (dcrRecordType.DeveloperName == 'Address_vod') {
                referenceDescribe = Address_vod__c.sObjectType.getDescribe();
            } else if (dcrRecordType.DeveloperName == 'Child_Account_vod') {
                referenceDescribe = Child_Account_vod__c.sObjectType.getDescribe();
            }
            for (IdChange change : changes) {
                change.referenceObject = referenceDescribe;
            }
        }
    }
    
    static Map<String, Set<Id>> collectQueries(Map<String, List<IdChange>> possibleIdChanges) {
        Map<String, Set<Id>> idsToQueryByObjectName = new Map<String, Set<Id>>();
        
        for (List<IdChange> dcrLineChanges : possibleIdChanges.values()) {
            for (IdChange dcrLineChange : dcrLineChanges) {
	       		DescribeSObjectResult describe = dcrLineChange.referenceObject;
        		Map<String, SObjectField> fieldMap = describe.fields.getMap();
                String fieldName = dcrLineChange.referenceFieldName;
                SObjectField field = fieldMap.get(fieldName);
                if (field != null && field.getDescribe().getType() == DisplayType.Reference) {
                    List<sObjectType> referenceTo = field.getDescribe().getReferenceTo();
                    if (referenceTo.size() == 1) { // not supporting polymorphic lookups for this
                        DescribeSObjectResult referenceDescribe = referenceTo.get(0).getDescribe();
                        String fieldValue = dcrLineChange.referenceFieldValue;
                        if (referenceDescribe.fields.getMap().containsKey('Name') && isValidId(referenceDescribe, fieldValue)) {
                            addToQueries(idsToQueryByObjectName, referenceDescribe.getName(), (Id)fieldValue);
                        }
                    }
                }
            }
        }

        return idsToQueryByObjectName;
    }
    
    static Boolean isValidId(DescribeSObjectResult describe, String candidate) {
        return (candidate.length() == 15 || candidate.length() == 18) 
            && candidate.startsWith(describe.getKeyPrefix()) 
            && Pattern.matches('^[a-zA-Z0-9]*$', candidate);
    }
    
    static void addToQueries(Map<String, Set<Id>> idMap, String objectName, Id add) {
    	Set<Id> idSet = idMap.get(objectName);
        if (idSet == null) {
            idSet = new Set<Id>();
            idMap.put(objectName, idSet);
        }
        idSet.add(add);
    }
    
    static Map<String, String> executeNameQueries(Map<String, Set<Id>> idListByObjectName) {
        Map<String, String> aggregateResults = new Map<String, String>();
        
        for (String objectName : idListByObjectName.keySet()) {
            Set<Id> idSet = idListByObjectName.get(objectName);
            String inString = convertSetToInClause(idSet);
            if (inString.length() > 0) {
            	List<sObject> results = Database.query('SELECT Id, Name FROM ' 
                                                        + String.escapeSingleQuotes(objectName) 
                                                        + ' WHERE Id IN ('
                                                        + inString
                                                        + ')');
                for (sObject result : results) {
                    aggregateResults.put(String.valueOf(result.get('Id')), String.valueOf(result.get('Name')));
                }
            }
        }
        return aggregateResults;
    }
    
    public static List<Data_Change_Request_Line_vod__c> createUpdates(Map<String, List<IdChange>> possibleIdChanges, 
                                                               Map<String, String> nameById) {
    	List<Data_Change_Request_Line_vod__c> updatesById = new List<Data_Change_Request_Line_vod__c>();
        
        for (String dcrLineId : possibleIdChanges.keySet()) {
            boolean addIt = false;
            Data_Change_Request_Line_vod__c dcrLine = new Data_Change_Request_Line_vod__c(Id = dcrLineId);
            for (IdChange dcrLineChange : possibleIdChanges.get(dcrLineId)) {
                String referenceName = nameById.get(dcrLineChange.referenceFieldValue);
                if (referenceName != null) {
                    String localizedFieldName = LOCAL_BY_FIELD_NAME.get(dcrLineChange.dcrLineFieldName);
                    if (localizedFieldName != null) {
                        // 'Name' field is at longest 255 char, so no worry about truncating
                        dcrLine.put(localizedFieldName, referenceName);
                        addIt = true;
                    }                
                }
            }
            if (addIt) {
                updatesById.add(dcrLine);
            }
		}
        return updatesById;
    }
    
    static String convertSetToInClause(Set<Id> idList) {
        String clause = '';
        String comma = '';
        for (Id myId : idList) {
            // hate doing string concat in loop, but no StringBuilder available in core Apex. 
            // See https://code.google.com/p/apex-lang/
            clause = clause + comma + '\'' + myId + '\'';
            if (comma.length() == 0) {
                comma = ',';
            }
        }
        return clause;
    }
    
    static Data_Change_Request_Line_vod__c findOrCreateRecord(Map<String, Data_Change_Request_Line_vod__c> updatesById, String idStr) {
        Data_Change_Request_Line_vod__c toUpdate = updatesById.get(idStr);
        if (toUpdate == null) {
            toUpdate = new Data_Change_Request_Line_vod__c();
            updatesById.put(idStr, toUpdate);
        }
        return toUpdate;
    }
    
    private class IdChange {
        String dcrLineId;
        String referenceFieldName;
        String dcrLineFieldName;
        String referenceFieldValue;
        DescribeSObjectResult referenceObject;
    }
}