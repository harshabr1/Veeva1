public class VOD_Utils {

    public static String toString(Set<String> data, String seperator) {
        String result = '';
        boolean first = true;
        for (String str : data) {
            if (first)
               first = false;
            else
               result += seperator;
            result += str;
        }
        return result;
    }

    private static boolean updateChildAccount = false;
    private static boolean updateAccount = false;
    private static boolean triggerEventAttendee = false;
    private static boolean triggerEmAttendee = false;
    private static boolean triggerEmSpeaker = false;
    private static boolean triggerMedicalEvent = false;
    private static boolean triggerEMEvent = false;
    private static boolean isMergeAccountProcess = false;
    private static Set<String> sObjectNames = new Set<String>();

    public static boolean getUpdateChildAccount () {
        return updateChildAccount;
    }
    public static void setUpdateChildAccount (boolean bVal) {
        updateChildAccount = bVal;
    }
    public static boolean getUpdateAccount () {
        return updateAccount;
    }
    public static void setUpdateAccount (boolean bVal) {
        updateAccount = bVal;
    }
    public static boolean isTriggerEventAttendee () {
        return triggerEventAttendee;
    }
    public static void setTriggerEventAttendee (boolean bVal) {
        triggerEventAttendee = bVal;
    }
    public static boolean isTriggerEmAttendee () {
        return triggerEmAttendee;
    }
    public static void setTriggerEmAttendee (boolean bVal) {
        triggerEmAttendee = bVal;
    }
    public static boolean isTriggerEmSpeaker () {
        return triggerEmSpeaker;
    }
    public static void setTriggerEmSpeaker (boolean bVal) {
        triggerEmSpeaker = bVal;
    }
    public static boolean isTriggerMedicalEvent() {
        return triggerMedicalEvent;
    }
    public static void setTriggerMedicalEvent(boolean bVal) {
        triggerMedicalEvent = bVal;
    }
    public static boolean isTriggerEMEvent() {
        return triggerEMEvent;
    }
    public static void setTriggerEMEvent(boolean bVal) {
        triggerEMEvent = bVal;
    }
    

    //property to see of account merge is in progress
    public static boolean getisMergeAccountProcess () {
        return isMergeAccountProcess;
    }
    public static void setisMergeAccountProcess (boolean bVal) {
        isMergeAccountProcess = bVal;
    }

    public static boolean canModifyAllData () {
        String ProfileId = UserInfo.getProfileId();
        Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
        if (pr != null && pr.PermissionsModifyAllData)
            return true;
        return false;
    }

    private static Set<Id> addresses = new Set<Id> ();
    public static Set<Id> getaddresses() {
        return addresses;
    }

    public static String getAccessibleFieldsSoql(String obj, String whereClause) {
        String sql = '';
        String fieldString = '';
        list<String> fieldList = new list<String>();
        // Get a map of field names for this object type.
        Map<String, Schema.SObjectField> fieldMap =
           Schema.getGlobalDescribe().get(obj.toLowerCase()).getDescribe().fields.getMap();
        if (fieldMap != null)
        {
           // Loop through all fields.
           for (Schema.SObjectField f : fieldMap.values())
           {
              // Describe each field.
              Schema.DescribeFieldResult fd = f.getDescribe();
              // Is this field is queryable? If so, we can query it.
                 // This is the API name.
                 fieldList.add(fd.getName());
           }
        }
        // Sort and assemble field list.
        if (!fieldList.isEmpty())
        {
           fieldList.sort();
           for (string s : fieldList)
           {
              fieldString += s + ',';
           }
        }
        // Strip terminal comma.
        if (fieldString.endsWith(','))
           fieldString = fieldString.substring(0, fieldString.lastIndexOf(','));
        // Assemble SQL statement.
        sql = 'SELECT ' + fieldString + ' FROM ' + obj;
        // Append WHERE clause if present; if ORDER BY or LIMIT are needed,
        // append them to WHERE clause when calling this method.
        if (whereClause != null && whereClause != '')
           sql += ' WHERE ' + whereClause;
        return sql;
   }

   public static boolean isNetworkEnabled() {
       Network_Settings_vod__c settings = Network_Settings_vod__c.getInstance();
       return settings != null 
           && settings.NETWORK_CUSTOMER_MASTER_MODE_vod__c == 1.0;
   }
    
    // This method gets the value of the Network Setting CRM_MANAGED_ACCOUNT_TYPES_vod__c
    public static String getNetworkCrmManagedSettingValue() {
        Network_Settings_vod__c settings = Network_Settings_vod__c.getInstance();
        if (settings == null) {
            return null;
        }

        String settingValue = settings.CRM_MANAGED_ACCOUNT_TYPES_vod__c;
        return getNetworkSettingMessageValue(settingValue);
    }
    
    // This method gets the value of the Network Setting THIRD_PARTY_MANAGED_ACCOUNT_TYPES_vod__c
    public static String getNetworkThirdPartyManagedSettingValue() {
        Network_Settings_vod__c settings = Network_Settings_vod__c.getInstance();
        if (settings == null) {
            return null;
        }

        String settingValue = settings.THIRD_PARTY_MANAGED_ACCOUNT_TYPES_vod__c;
        return getNetworkSettingMessageValue(settingValue);        
    }
    
    // This method checks if network is enabled and if a particular record type is crm managed for a specific country
    public static boolean isNetworkCrmManaged(boolean networkEnabled, String thirdPartyManagedSetting, String crmManagedSetting, String developerRecordTypeName, String countryCode) {
        if (!networkEnabled) {
            return false;
        }
        
        // It's CRM managed when Network enabled if it's not in third party but is in crm managed setting
        if (!settingIncludesRecordTypeAndCountry(thirdPartyManagedSetting, developerRecordTypeName, countryCode) && 
            settingIncludesRecordTypeAndCountry(crmManagedSetting, developerRecordTypeName, countryCode)) {
            return true;
        }       
        
        return false;
    }
    
    // This is a helper method to parse a Network Setting value into record type and country components and returns whether specific
    // record type and country can be found.
    private static boolean settingIncludesRecordTypeAndCountry(String setting, String developerRecordTypeName, String countryCode) {
        if (setting == null || setting.length() == 0 || developerRecordTypeName == null || developerRecordTypeName.length() == 0 || 
            countryCode == null || countryCode.length() != 2) {
            return false;
        }
        
        List<String> recordTypeSettings = setting.split(';;');
        for (String recordTypeSetting : recordTypeSettings) {
            List<String> settingParts = recordTypeSetting.split(':');
            String currentRecordType = settingParts[0];
            if (developerRecordTypeName.equals(currentRecordType)) {
                // Found the record type, see if we can find a country match
                
                String countries = settingParts[1];
                
                if ('ALL'.equals(countries)){
                    // We matched the special ALL keyword that automatically includes all country code values
                    return true;
                }
                
                // Loop through individual countries to see if we find matching country             
                List<String> countryList = countries.split(',');
                for (String country : countryList) {
                    if (countryCode.equals(country)) {
                        return true; // Found so return
                    }
                }
            }
        }
        
        return false; // Didn't find the values
    }
    
    // This is a helper method that takes the value of a settings value and checks if it references a Veeva Message with the 
    // <stringname>;;<category> syntax.  If a Veeva Message is found, that value is returned instead of the original settings value.
    private static String getNetworkSettingMessageValue(String settingValue) {
        if (settingValue == null || settingValue.length() == 0) {
            return null;
        }

        // At this point we may have a direct value (unlikely) or a reference to
        // a Veeva Message that contains the real value.  Run a query to find the
        // Veeva Message if we find expected reference parts and Veeva Message.
         
        List<String> strParts = settingValue.split(';;');
        if (strParts.size() != 2) {
            return settingValue;
        }
        
        String key = strParts[0];
        String category = strParts[1];
        
        try {
            List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c Where Category_vod__c=:category And Name=:key And Active_vod__c=true And Language_vod__c=:UserInfo.getLanguage() LIMIT 1];
            if (!messages.isEmpty()) {
                return messages.get(0).Text_vod__c;
            }
            if (UserInfo.getLanguage() != 'en_US') {
                // Try default English since localized message wasn't found
                messages = [Select Text_vod__c From Message_vod__c Where Category_vod__c=:category And Name=:key And Active_vod__c=true And Language_vod__c='en_US' LIMIT 1];
                if (!messages.isEmpty()) {
	                return messages.get(0).Text_vod__c;
                }
            }
        } catch (System.QueryException e) {
            return settingValue; // Just return settingValue as it's the best we can do
        }
        return settingValue; // Just return settingValue as it's the best we can do
    }
    
    public static String getUserCountry() {
        String country = null;
        
        String userId = UserInfo.getUserId();
        List<User> usersList = [SELECT Id, Name, Country From User Where Id=:userId];
        if (usersList.size() == 1) {
            country = usersList[0].Country;
        }
        
        return country;
    }

    public static String quotedOrNull(String value) {
        if (value == null) {
            return 'null';
        }
        return '\'' + value + '\'';
   }

   public static boolean isEventLocked(EM_Event_vod__c event) {
       return event.Lock_vod__c;
   }

    public static boolean isValueSame(Map<String, Object> strMap, String key1, String key2) {
        if (strMap.get(key1) == null && strMap.get(key2) == null) {
            return true;
        } else if (strMap.get(key1) != null) {
            return strMap.get(key1).equals(strMap.get(key2));
        } else {
            return strMap.get(key2).equals(strMap.get(key1));
        }
    }

    public static Map<Id, String> recordTypeToName(String objectType) {
        Map<Id, String> idToName = new Map<Id, String>();
        for (RecordType recordType : [SELECT Id, Name
                                      FROM RecordType
                                      WHERE sObjectType =: objectType]) {
            idToName.put(recordType.Id, recordType.Name);
        }
        return idToName;
    }

    public static List<Id> findConfigs(EM_Event_vod__c event, List<EM_Event_Configuration_vod__c> configs) {
        List<Id> matches = new List<Id>();
        Date start = Date.newInstance(event.Start_Time_vod__c.year(), event.Start_Time_vod__c.month(), event.Start_Time_vod__c.day());
        Map<Id, String> recordTypeToName = VOD_Utils.recordTypeToName('EM_Event_vod__c');
        for (EM_Event_Configuration_vod__c config : configs) {
            if (recordTypeToName.get(event.RecordTypeId) == config.Event_Type_vod__c && start >= config.Start_Date_vod__c && start <= config.End_Date_vod__c) {
                if (event.Country_vod__c == null) {
                    matches.add(config.Id);
                } else {
                    for (EM_Event_Configuration_Country_vod__c country : config.Event_Configuration_Country_vod__r) {
                        if (event.Country_vod__c == country.Country_vod__c) {
                            matches.add(config.Id);
                            break;
                        }
                    }
                }
            }
        }
        return matches;
    }

    public static boolean hasObject(String objectName) {
        if (sObjectNames.size() == 0) {
            List<Schema.SObjectType> objectTypes = Schema.getGlobalDescribe().values();
            for (Schema.SObjectType objectType : objectTypes) {
                sObjectNames.add(objectType.getDescribe().getName());
            }
        }
        return sObjectNames.contains(objectName);
    }
    
    public static Set<String> getAttendeeStatuses() {   	
        List<String> attendeeSetting = new List<String>();
        Set<String> attendeeStatuses = new Set<String>();
        Events_Management_Settings_vod__c emSetting = Events_Management_Settings_vod__c.getInstance();
        if(emSetting != null && emSetting.ATTENDEE_ROLLUP_STATUS_FILTER_vod__c != null) {
        	attendeeSetting = emSetting.ATTENDEE_ROLLUP_STATUS_FILTER_vod__c.split(';;');
            String name = attendeeSetting.get(0);
            String category = attendeeSetting.get(1);
            if(attendeeSetting.size() == 2) {
                List<Message_vod__c> attendeeStatusesMessage = [SELECT Text_vod__c
                                                               FROM Message_vod__c
                                                               WHERE Active_vod__c = true
                                                               AND NAME = :name
                                                               AND Category_vod__c = :category
                                                               AND Language_vod__c = 'en_US'];
                if(attendeeStatusesMessage.size() > 0 && attendeeStatusesMessage.get(0).Text_vod__c != null) {
                    attendeeStatuses = new Set<String>(attendeeStatusesMessage.get(0).Text_vod__c.split(','));
                }
            }
        }

        if(attendeeStatuses.isEmpty()) {
            attendeeStatuses.add('Attended_vod');
            attendeeStatuses.add('Signed_vod');
        }
        return attendeeStatuses;
    }
}