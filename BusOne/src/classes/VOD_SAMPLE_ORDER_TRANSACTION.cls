public class VOD_SAMPLE_ORDER_TRANSACTION {
  
    public static RecordType [] recType  = [ Select Id, Name from RecordType where SobjectType = 'Sample_Order_Transaction_vod__c'  and  (Name ='Receipt_vod' or Name = 'Transfer_vod')];
    private static boolean updateGroup = true;
            
    public static boolean getUpdateGroup () {
        return updateGroup;
    }
    public static void setUpdateGroup (boolean bVal) {
        updateGroup = bVal;
    }    
    
}