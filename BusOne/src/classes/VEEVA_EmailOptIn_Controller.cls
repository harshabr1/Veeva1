public with sharing class VEEVA_EmailOptIn_Controller {

private final Account acct;
 // The extension constructor initializes the private member
    // variable acct by using the getRecord method from the standard
    // controller.
    public VEEVA_EmailOptIn_Controller(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
    }
    public String getVodVersion() {
        return VOD_Common.VOD_VERSION;
    }
    public String getRefUrl()
      {
        return ApexPages.currentPage().getHeaders().get('referer');
      }
    public String getVodUrl () {
        return VOD_Common.VOD_URL;
    }
    public boolean getInMaintenance () {
        return VOD_Common.VOD_MAINT;
    }
    public String getExcludedUsers () {
        return VOD_Common.VOD_EXCLUDED_USERS;
    }
//for ipad    
    public String getVodServerUrl() {
        return VOD_Common.VOD_SERVER_URL;
    }
//for content server    
    public String getVodFtpUrl(){
        return VOD_Common.FTP_SERVER_URL;
    }
    public String getVodContentUrl(){
        return VOD_Common.CONTENT_SERVER_URL;
    }
}