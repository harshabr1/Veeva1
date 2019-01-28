public class VOD_GET_ERROR_MSG {

    public static String getErrorMsg(String pKey, String pCategory) {

        String userLang = UserInfo.getLanguage();
        Message_vod__c msg = null;
        try {
            msg = [Select Text_vod__c From Message_vod__c
                        WHERE NAME = :pKey
                        AND Language_vod__c = :userLang
                        AND Category_vod__c = :pCategory
                        AND Active_vod__c = true LIMIT 1];
        } catch (System.QueryException e) {
        }


        if (msg == null) {
        try {
            msg = [Select Text_vod__c From Message_vod__c
                        WHERE NAME = :pKey
                        AND Language_vod__c = 'en_US'
                        AND Category_vod__c = :pCategory
                        AND Active_vod__c = true LIMIT 1];
        }  catch (System.QueryException e) {
        }

        }
        String value ='';
        if (msg != null) {
            value = msg.Text_vod__c;
        }
        return value;

    }

    public static String getVeevaSettingsMsg(String settingName) {
        Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
        if (settings != null) {
            String settingsValue = (String) settings.get(settingName);
            if(settingsValue == null) {
                return '';
            }
            String[] messagePointer = settingsValue.split(';;');
            if (messagePointer.size() != 2) {
                return settingsValue;
            } else {
                return getErrorMsg(messagePointer[0], messagePointer[1]);
            }
        }

        return '';
    }

        
    public static String getErrorMsgWithDefault(String pKey, String pCategory, String defaultMessage) {
        String errorMessage = getErrorMsg(pKey, pCategory);
        
        // Return the default if we can't find the message.
        if (String.isEmpty(errorMessage)) {
            return defaultMessage;
        }
        
        return errorMessage;
    }
}