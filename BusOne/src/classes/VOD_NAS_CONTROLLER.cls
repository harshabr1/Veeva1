public with sharing class VOD_NAS_CONTROLLER {
    
    public VOD_NAS_CONTROLLER(ApexPages.StandardController controller) {
    }

    public VOD_NAS_CONTROLLER() {
    }
    
    public static String getSearchAccounts() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('SEARCH_ACCOUNTS', 'iPad', 'Search Accounts');
    }
    
    public static String getBeforeCreate() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('BEFORE_CREATE', 'NETWORK', 
                'Before creating a new account, you must search for possible existing accounts.');
    }
    
    public String getExtraParams() {
        return '';
    }
    
    public static String getTitle() {
        return 'Veeva CRM Online';
    }
    
    public static String getVodUrl () {
        return VOD_Common.VOD_URL;
    }
}