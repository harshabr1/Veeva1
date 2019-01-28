public class VOD_SAMPLE_RECEIPTS {
    static Boolean isReceipt = false;
    static boolean checkedEnable = false;
    static boolean isENABLE_RECEIPT_ACTIVATION = false;
    
    public static  void setReceipt(Boolean p_isReceipt) {
        isReceipt = p_isReceipt;
    }
    
    public static Boolean getReceipt() {
        return isReceipt;
    }
    
    public static Boolean ENABLE_RECEIPT_ACTIVATION() {
        // only check for the value of the setting once
        if (checkedEnable == false) {
            checkedEnable = true;
            
            Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
            if (settings != null)
                isENABLE_RECEIPT_ACTIVATION = settings.ENABLE_RECEIPT_ACTIVATION_vod__c;
            else if ('true'.equalsIgnoreCase(VOD_GET_ERROR_MSG.getErrorMsg('ENABLE_RECEIPT_ACTIVATION', 'SAMPLES_MGMT')))
                isENABLE_RECEIPT_ACTIVATION = true;
        }
        return isENABLE_RECEIPT_ACTIVATION;
    }
}