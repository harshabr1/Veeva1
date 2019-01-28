global class VOD_Common {
    global static String VOD_SERVER_URL = Veeva_Common_vod__c.getValues('Main').Veeva_Server_vod__c;
    global static String VOD_VERSION = Veeva_Common_vod__c.getValues('Main').Veeva_Version_vod__c;
    global static String VOD_URL = VOD_SERVER_URL + '/' + VOD_VERSION;
    global static boolean VOD_MAINT = Veeva_Common_vod__c.getValues('Main').Maintenance_Mode_vod__c;
    global static String VOD_EXCLUDED_USERS = Veeva_Common_vod__c.getValues('Main').Maintenance_Override_Users_vod__c;
    global static String FTP_SERVER = Veeva_Common_vod__c.getValues('Main').FTP_Server_vod__c;
    global static String FTP_SERVER_URL = FTP_SERVER + '/' + VOD_VERSION;
    global static String CONTENT_SERVER_URL = Veeva_Common_vod__c.getValues('Main').Content_Server_vod__c;
}