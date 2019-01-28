trigger VEEVA_EMAIL_ACTIVITY_BEFORE_INSERT on Email_Activity_vod__c (before insert) {

    // the trigger is handling one record only
    // since email activity is being inserted one at a time
    Email_Activity_vod__c newEvent = trigger.new[0];

    if(newEvent.Event_type_vod__c == 'Clicked_vod') {

        // try to see if this email has an open activity
        List<Email_Activity_vod__c> allOpenAct = [SELECT id, Event_type_vod__c
                                                  FROM Email_Activity_vod__c
                                                  WHERE Sent_Email_vod__c =: newEvent.Sent_Email_vod__c AND Event_type_vod__c = 'Opened_vod'];

        if(allOpenAct == null || allOpenAct.isEmpty()) {

            // infer an opened event
            RecordType EmailActRecordType = [SELECT Id FROM RecordType WHERE SobjectType='Email_Activity_vod__c' AND DeveloperName = 'Email_Activity_vod'];
            Email_Activity_vod__c openEvent = new Email_Activity_vod__c (

                        // set record type to Email Activity and event type to Opened
                        RecordTypeId = EmailActRecordType.Id,
                        Event_type_vod__c = 'Opened_vod',

                        // use same values as the click event for following fields
                        Sent_Email_vod__c = newEvent.Sent_Email_vod__c,
                        Activity_DateTime_vod__c = newEvent.Activity_DateTime_vod__c,
                        City_vod__c = newEvent.City_vod__c,
                        User_Agent_vod__c = newEvent.User_Agent_vod__c,
                        Client_Name_vod__c = newEvent.Client_Name_vod__c,
                        Client_OS_vod__c = newEvent.Client_OS_vod__c,
                        Client_Type_vod__c = newEvent.Client_Type_vod__c,
                        Country_vod__c = newEvent.Country_vod__c,
                        Device_Type_vod__c = newEvent.Device_Type_vod__c,
                        IP_Address_vod__c = newEvent.IP_Address_vod__c,
                        Region_vod__c = newEvent.Region_vod__c
            );

            insert openEvent;
        }
    }
}