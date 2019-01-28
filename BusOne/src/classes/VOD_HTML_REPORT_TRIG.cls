public class VOD_HTML_REPORT_TRIG{
    public static String getCombinedId(HTML_Report_vod__c report) {
        return report.RecordTypeId + report.Profile_vod__c + report.Sharing_Group_vod__c + report.Object_RecordType_Id_vod__c;
    }
    
    public static Set<Id> getDuplicateCheckRecordTypes() {
        return new Map<Id, RecordType>(
                   [SELECT Id 
                    FROM RecordType 
                    WHERE SObjectType = 'HTML_Report_vod__c' 
                    AND DeveloperName IN ('Account_Profile_Override_vod','Account_Plan_vod','KOL_Profile_vod')]
               ).keySet();
    }
}