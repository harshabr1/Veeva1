public class Medical_Event_Extension_vod {
    private final Medical_Event_vod__c medEvent;
    private Account account;
    private boolean searchedAccount = false;
    private List<Event_Attendee_vod__c> attendees;
    
    public Medical_Event_Extension_vod(ApexPages.StandardController stdCtrl) {
        List<String> fields = new List<String>();
        fields.add('Account_vod__c');
        stdCtrl.addFields(fields);
        medEvent = (Medical_Event_vod__c)stdCtrl.getRecord();
    }
    
    public boolean getSkipAcctSelector() {
        return (getAccount() != null && getAccount().isPersonAccount) || !getHasAccountAttendees();
    }
    
    public boolean getHasAccountAttendees() {
        return getAttendees().size() > 0;
    }
       
    private Account getAccount() {
        if (!searchedAccount) {
            if (Schema.sObjectType.Medical_Event_vod__c.fields.Account_vod__c.isAccessible() && medEvent.Account_vod__c != null) {
                account = [SELECT Id, isPersonAccount FROM Account WHERE Id = :medEvent.Account_vod__c];
            }
            searchedAccount = true;
        }
        return account;
    } 
    
    private List<Event_Attendee_vod__c> getAttendees() {
        if (attendees == null) {
            attendees = [SELECT Id, Account_vod__c 
                         FROM Event_Attendee_vod__c
                         WHERE Medical_Event_vod__c =: medEvent.Id
                         AND Account_vod__c != null];
        }
        return attendees;
    }
}