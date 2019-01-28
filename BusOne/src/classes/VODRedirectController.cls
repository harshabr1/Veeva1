public with sharing class VODRedirectController {

    public VODRedirectController(ApexPages.StandardSetController controller) {
    }

    private static List<String> urlWith2000px =
        new List<String>
          {
            'Call_Report_From_Calls_vod', 'Call_Reports_from_Calls_Edit_vod',
            'Medical_Inquiry_Clone', 'Medical_Inquiry_Edit_vod', 'Medical_Inquiry_New_vod', 'Medical_Inquiry_View_vod',
            'Sample_Transactions_Clone', 'Sample_Transactions_Edit', 'Sample_Transactions_New', 'Sample_Transaction_View',
            'Sample_Inventory_View', 'Sample_Inventory_Edit', 'Sample_Inventory_New',
            'Sample_Orders_Edit_vod', 'Sample_Orders_View_vod',
            'VMobile_Config_Clone_vod', 'VMobile_Config_Edit_vod', 'VMobile_Config_New_vod', 'VMobile_Config_View_vod',
            'Call_from_Account_Tactic_vod', 'Call_Report_From_Account_Default', 'Call_Report_From_Contact_vod', 'Call_Report_From_Medical_Event',
            'Call_Report_Meeting_Brief_vod', 'Gener_Non_Accnt_Lookup_Record_Call_Tmpl', 'MultiChannel_Calendar_vod', 'My_Samples',
            'New_Any_Account_vod', 'New_Business_Account_vod', 'New_Hospital_Account_vod', 'New_Person_Account_vod', 'New_Professional_Account_vod',
            'New_Professional_vod'
          };

    public VODRedirectController(ApexPages.StandardController controller) {
    }

    public VODRedirectController() {
    }

    public String redirectURL { get; set; }

    public static String getVodVersion() {
        return VOD_Common.VOD_VERSION;
    }
  
    public static String getVodUrl () {
        return VOD_Common.VOD_URL;
    }
    public static boolean getInMaintenance () {
        return VOD_Common.VOD_MAINT;
    }
    public static String getExcludedUsers () {
        return VOD_Common.VOD_EXCLUDED_USERS;
    }

    public static String getVodServerUrl() {
        return VOD_Common.VOD_SERVER_URL;
    }

    public static String getVodFtpUrl(){
        return VOD_Common.FTP_SERVER_URL;
    }
    public static String getVodContentUrl(){
        return VOD_Common.CONTENT_SERVER_URL;
    }
    
    //for MC Engine
    public static String getMcUrl(){
        return Veeva_Common_vod__c.getValues('Main').Multichannel_Server_vod__c + '/' + Veeva_Common_vod__c.getValues('Main').Multichannel_Context_Root_vod__c;
    }
    public static String getMcVersion(){
        return Veeva_Common_vod__c.getValues('Main').Multichannel_Context_Root_vod__c;
    }

    public String getPageSize() {

        String url = ApexPages.currentPage().getUrl();

        for(String checkUrl : urlWith2000px) {
            if(url.contains(checkUrl)) {
                return '2000px';
            }
        }

        if (url.contains('View_Cycle_Plan_vod')) {
            Integer targetCount = [select count() from Cycle_Plan_Target_vod__c where Cycle_Plan_vod__c = :ApexPages.currentPage().getParameters().get('id')];
            Integer height = 50*targetCount;
            if (height < 3000)
                height = 3000;
            return height+'px';
        } else if (url.contains('TSF_vod')) {
            return '600px';
        } else if (url.contains('Concur_Admin_vod')) {
            return '8000px';
        } else if (url.contains('Call_Edit_vod')) {
            return '2000px';
        }
        return '4000px';
    }

    public static String getScrolling() {
        String url = ApexPages.currentPage().getUrl();
        if (url.contains('View_Cycle_Plan_vod')) {
            return 'true';
        } else if (url.contains('TSF_vod')) {
            return 'true';
        } else if (url.contains('Call_Edit_vod')) {
            return 'true';
        }
        return 'false';
    }

    public PageReference doRedirect() {
        PageReference redirect = new PageReference(redirectURL);
        redirect.setRedirect(true);
        return redirect;
    }
}