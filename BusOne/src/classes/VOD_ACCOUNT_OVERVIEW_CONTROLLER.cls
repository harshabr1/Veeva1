public with sharing class VOD_ACCOUNT_OVERVIEW_CONTROLLER {
    private final Account account;
    
    public VOD_ACCOUNT_OVERVIEW_CONTROLLER(ApexPages.StandardController controller) {
        List<String> fields = new List<String>();
        fields.add('Name');
        fields.add('Salutation');
        controller.addFields(fields);
        
        this.account = (Account) controller.getRecord();
    }

    public VOD_ACCOUNT_OVERVIEW_CONTROLLER() {
    }

    public static String getTitle() {
        return 'Veeva CRM Online';
    }

    public static String getVodUrl() {
        return VOD_Common.VOD_URL;
    }
    
    public String getExtraParams() {
        return '&id=' + account.Id;
    }
    
    public static String getAccountOverview() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('ACCOUNT_OVERVIEW', 'Common', 'Account Overview');
    }
    
    public static String getAccountLabel() {
        return Account.sObjectType.getDescribe().getLabel();
    }
    
    public String getAccountName() {
        return account.Name;
    }
    
    public String getSalutation() {
        return account.Salutation;
    }
}