trigger VEEVA_EMAIL_ACTIVITY_AFTER_INSERT on Email_Activity_vod__c (after insert) {
    RecordType[] recordTypes = [Select Id, Name from RecordType where SobjectType = 'Multichannel_Consent_vod__c' and Name='Approved_Email_vod'];
    if(recordTypes.size() == 0){
        return;
    }
    String AERecordTypeID = recordTypes[0].Id;
    Set<String> sentEmailIds = new Set<String>();
    for(Email_Activity_vod__c activity: Trigger.new){
        sentEmailIds.add(activity.Sent_Email_vod__c);
    }
    Map<String,Sent_Email_vod__c> sentEmailMap = new Map<String,Sent_Email_vod__c>([SELECT Id, Account_email_vod__c, Account_vod__c, Last_Activity_Date_vod__c, Status_vod__c, Detail_Group_vod__c, Product_vod__c, Content_Type_vod__c, Content_Type_vod__r.Name, Content_Type_vod__r.External_Id_vod__c FROM Sent_Email_vod__c WHERE Id In :sentEmailIds ]);
    List<Multichannel_Consent_vod__c> newConsents = new List<Multichannel_Consent_vod__c>();
    for(Email_Activity_vod__c activity: Trigger.new){
        Sent_Email_vod__c email = sentEmailMap.get(activity.Sent_Email_vod__c);
        // only update last activity date in SE if this EA's activity datetime is later than the email's last activity date
        if(email.Last_Activity_Date_vod__c == null || activity.Activity_DateTime_vod__c > email.Last_Activity_Date_vod__c) {
            email.Last_Activity_Date_vod__c = activity.Activity_DateTime_vod__c;
        }
        String status = activity.Event_type_vod__c;
        // determine the consent level (if available)
        String consentLevel = '';
        String actDetail = activity.Event_Msg_vod__c;
        if(actDetail != null) {
            String[] actDetailVal = actDetail.split('::');
            if(actDetailVal.size() == 2 && actDetailVal[0] == 'Consent_Level') {
                consentLevel = actDetailVal[1];
            }
        }
        if(status != 'Clicked_vod' && status != 'Opened_vod' && status != 'Viewed_vod' && status != 'Downloaded_vod' && status != 'Preferences_Modified_vod'){
            if(status == 'Unsubscribed_All_vod'){
                email.Status_vod__c = 'Unsubscribed_vod';
            }
            else{
                email.Status_vod__c = status ;
            }
        }
        if(status == 'Preferences_Modified_vod'){
            String modPrefs = activity.Preference_Modification_vod__c;
            if(consentLevel == 'Content_Type_vod') {
                // content type level consent
                String emailCtName = email.Content_Type_vod__r.Name;
                String emailCtExtId = email.Content_Type_vod__r.External_Id_vod__c;
                if(modPrefs != null) {
                    String[] optChanges = modPrefs.split(';;');
                    for(String optChange : optChanges) {
                        String[] vals = optChange.split('::');
                        if(vals.size() == 3) {
                            String name = vals[0];
                            String extId = vals[1];
                            String optType = vals[2];
                            if(name == emailCtName && extId == emailCtExtId && optType == 'OptOut') {
                                email.Status_vod__c = 'Unsubscribed_vod';
                            }
                        }
                    }
                }
            }
            else{
                // null or product level consent, execute existing behavior
                String emailGroupId = email.Detail_Group_vod__c;
                String emailProductId = email.Product_vod__c ;
                String emailCompoundKey = emailGroupId  == null ? emailProductId : emailProductId  +'|'+ emailGroupId ;
                if(modPrefs != null){
                    String[] optChanges = modPrefs.split(';;');
                    for(String optChange : optChanges){
                        String[] vals = optChange.split('::');
                        if(vals.size() == 3){
                            String compoundKey = vals[1];
                            String optType = vals[2];
                            if(compoundKey == emailCompoundKey && optType == 'OptOut'){
                                email.Status_vod__c = 'Unsubscribed_vod';
                            }
                        }
                    }
                }
            }
        }
        
        if(status == 'Unsubscribed_vod' || status == 'Marked_Spam_vod' || status == 'Bounced_vod' || status == 'Unsubscribed_All_vod'){
            Multichannel_Consent_vod__c newConsent = new Multichannel_Consent_vod__c();
            newConsent.Account_vod__c = email.Account_vod__c;
            newConsent.Capture_Datetime_vod__c = activity.Activity_DateTime_vod__c;
            newConsent.Channel_Value_vod__c = email.Account_email_vod__c;
            if(status == 'Unsubscribed_All_vod'){
                newConsent.Optout_Event_Type_vod__c= 'Unsubscribed_vod';
            }
            else{
                newConsent.Optout_Event_Type_vod__c= status;
            }
            newConsent.Opt_Type_vod__c= 'Opt_Out_vod';
            if(status == 'Unsubscribed_vod'){
                if(consentLevel == 'Content_Type_vod') {
                    newConsent.Content_Type_vod__c = email.Content_Type_vod__c;
                }
                else {
                    newConsent.Product_vod__c= email.Product_vod__c;
                    newConsent.Detail_Group_vod__c= email.Detail_Group_vod__c;
                }
            }
            newConsent.RecordTypeId = AERecordTypeID;    
            newConsents.add(newConsent);
        }
    }
    update sentEmailMap.values();
    insert newConsents;

}