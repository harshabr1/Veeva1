public class  VOD_MobileDeviceUtils {
    public static void modifyMobileDeviceRecords(List<Id> userIds) {
         if(System.isFuture() || System.isBatch()) {
             system.debug('modifyMobileDeviceRecordsSync runs');
             modifyMobileDeviceRecordsSync(userIds);
         } else {
             system.debug('modifyMobileDeviceRecordsFuture runs');
             modifyMobileDeviceRecordsFuture(userIds);
         }
        
    }
    
    public static void modifyMobileDeviceRecordsSync(List<Id> userIds) {
        List<Mobile_Device_vod__c> updateRecords = null;
        for (Id userId: userIds) {
            List<Mobile_Device_vod__c> mobileDeviceList = [Select Id, Active_vod__c, User_vod__c from Mobile_Device_vod__c WHERE User_vod__c =: userId];
            if (mobileDeviceList != null && mobileDeviceList.size() > 0) {
                updateRecords = new List<Mobile_Device_vod__c>();
                for (Mobile_Device_vod__c record:  mobileDeviceList) {
                     record.Active_vod__c = false;
                     updateRecords.add(record);
                }
            }
        }
        
        if (updateRecords  != null && updateRecords.size() > 0) {
            update updateRecords;
        }
    }
    
    @future
    public static void modifyMobileDeviceRecordsFuture(List<Id> userIds) {
        modifyMobileDeviceRecordsSync(userIds);
    }
}