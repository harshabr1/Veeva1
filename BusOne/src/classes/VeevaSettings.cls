public class VeevaSettings {
    public static Veeva_Settings_vod__c getVeevaSettings () {
        return Veeva_Settings_vod__c.getInstance(UserInfo.getUserId());
    }
    
    public static boolean isEnableSamplesOnSave() {
        Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
        if (vsc != null &&  vsc.Enable_Samples_On_Save_vod__c == true)
            return true;
        return false;
    }
    
    public static boolean isSimpleHierarchy() {
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
        if (vsc == null)
            return false;
        return vsc.Enable_Simple_Hierarchy_vod__c;
    }
    
    public static boolean autocreateAffliation() {
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
        if (vsc == null)
            return true;
        return !vsc.Disable_Affiliation_Autocreate_vod__c;
    }
    
    public static Datetime getAddressDatetime() {
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
        if (vsc != null  &&  vsc.Last_Address_Run_vod__c != null)
            return vsc.Last_Address_Run_vod__c;
        return Datetime.newInstanceGmt(1900,01,01);
    }
    
    public static void setAddressDatetime(Datetime dt) {
        if (dt == null)
            return;
            
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
        vsc.Last_Address_Run_vod__c = dt;
        update vsc;
    }
    
        
    public static boolean isEnableSamplesOnSaveSign() {
        Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
        if (vsc != null && vsc.ENABLE_SAMPLES_ON_SIGN_SAVE_vod__c == true)
            return true;
        return false;
    }
    
    public static boolean isEnableParentAccountAddressCopy() {
        Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
        if (vsc != null && vsc.ENABLE_PARENT_ACCOUNT_ADDRESS_COPY_vod__c == true)
            return true;
        return false;
    }   
    
    public static boolean isEnableChildAccountsInWizards() {
        Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
        if (vsc != null && vsc.ENABLE_CHILD_ACCOUNT_IN_WIZARDS_vod__c == true) {
            return true;
        }
        return false;
    }  
   
}