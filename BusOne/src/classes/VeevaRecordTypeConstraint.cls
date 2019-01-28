/**
 * Controller Extension used in enforcing the constraint between a Master-Detail relationship that the RecordType.DeveloperName matches
 * between the parent and child objects.
 */
public with sharing class VeevaRecordTypeConstraint {
    public VeevaRecordTypeConstraint(ApexPages.StandardController stdController) {
        record = stdController.getRecord();
        type = record.getSObjectType();
        describe = type.getDescribe();

        Set<String> lookupPrefixes = new Set<String>();
        Map<String, String> currentParameters = ApexPages.currentPage().getParameters();
        for(String paramName : currentParameters.keySet()) {
            String paramValue = currentParameters.get(paramName);
            Matcher match = LKID_PATTERN.matcher(paramName);
            if(match.matches()) {
                lookupPrefixes.add(paramValue.subString(0, 3));
            }
        }

        for(Schema.SObjectField field : describe.fields.getMap().values()) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if(fieldDescribe.getType() == Schema.DisplayType.Reference) {
                DescribeSObjectResult lookupDescribe = fieldDescribe.getReferenceTo().get(0).getDescribe();
                if(lookupPrefixes.contains(lookupDescribe.getKeyPrefix())) {
                    parentDescribe = lookupDescribe;
                }
            }
        }
    }

    public PageReference getRedirect() {
        PageReference pageRef = new PageReference('/' + getObjectPrefix() + '/e');
        Map<String, String> newParameters = pageRef.getParameters();
        newParameters.putAll(ApexPages.currentPage().getParameters());
        newParameters.remove('save_new');
        newParameters.put('nooverride', '1');
        setRetURL(newParameters);
        setRecordTypeParameter(newParameters);
        return pageRef.setRedirect(true);
    }

    public String getObjectPrefix() {
        return describe.getKeyPrefix();
    }

    public String getParentPrefix() {
        if(parentDescribe != null) {
            return parentDescribe.getKeyPrefix();
        } else {
            return null;
        }
    }

    public void setRecordTypeParameter(Map<String, String> parameters) {
        String parentFieldId = getParentFieldId(parameters);
        String recordTypeId = getRecordTypeIdToUse(parameters.get('CF' + parentFieldId + '_lkid'));
        if(recordTypeId != null) {
            parameters.put('RecordType', recordTypeId );
        }
    }

    public void setRetURL(Map<String, String> parameters) {
        String referrer = ApexPages.currentPage().getHeaders().get('Referer');
        if(!parameters.containsKey('retURL') && referrer != null) {
            parameters.put('retURL', referrer);
        }
    }

    public String getParentFieldId(Map<String, String> parameters) {
        String parentPrefix = getParentPrefix();

        if(parentPrefix != null) {
            for(String paramName : parameters.keySet()) {
                String paramValue = parameters.get(paramName);
                Matcher match = LKID_PATTERN.matcher(paramName);
                if(match.matches() && paramValue.startsWith(parentPrefix)) {
                    return match.group(1);
                }
            }
        }
        return null;
    }

    public String getRecordTypeIdToUse(String parentRecordId) {
        if(parentDescribe == null) {
            return null;
        }

        SObject parent = Database.query('SELECT RecordType.DeveloperName ' +
            'FROM ' + parentDescribe.getName() + ' ' +
            'WHERE Id = \'' + String.escapeSingleQuotes(parentRecordId) + '\'');
        String recordTypeName = (String) parent.getSObject('RecordType').get('DeveloperName');

        List<SObject> result = Database.query('SELECT Id ' +
            'FROM RecordType ' +
            'WHERE SObjectType = \'' + describe.getName() + '\' AND ' +
            'DeveloperName = \'' + recordTypeName + '\'');

        if(result.size() == 1) {
            SObject recordTypeToUse = result.get(0);
            return (String) recordTypeToUse.get('Id');
        }
        return null;
    }

    private final SObject record;
    private final SObjectType type;
    private final String lookupFieldId;
    private final DescribeSObjectResult describe;
    private final DescribeSObjectResult parentDescribe;

    private static final Pattern LKID_PATTERN = Pattern.compile('CF(\\w{15})_lkid');
}