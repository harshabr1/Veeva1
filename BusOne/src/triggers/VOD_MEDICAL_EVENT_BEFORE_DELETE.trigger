trigger VOD_MEDICAL_EVENT_BEFORE_DELETE on Medical_Event_vod__c (before delete) {
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
    Map <Id,Medical_Event_vod__c> medMap = new Map<Id,Medical_Event_vod__c> (
           [Select Id, EM_Event_vod__c, EM_Event_vod__r.Override_Lock_vod__c, EM_Event_vod__r.Lock_vod__c,
                   (Select Id From Call2_Discussion_vod__r LIMIT 1),
                   (Select Id From Call2_vod__r LIMIT 1),
                   (Select Id,Signature_Datetime_vod__c From Event_Attendee_vod__r WHERE Signature_Datetime_vod__c != null LIMIT 1)
            from Medical_Event_vod__c
            where Id in :Trigger.old]);

    for (Integer i = 0; i < Trigger.old.size(); i++) {
        Medical_Event_vod__c med = medMap.get(Trigger.old[i].Id);

        Integer k = 0;
        Integer j = 0;

        for (Call2_vod__c cal2 : med.Call2_vod__r) {
            k++;
        }

        for (Call2_Discussion_vod__c cal2 : med.Call2_Discussion_vod__r) {
            k++;
        }

        for (Event_Attendee_vod__c attendee : med.Event_Attendee_vod__r) {
            j++;
        }

        if (k > 0)
            Trigger.old[i].Id.addError(bundle.getErrorMsg('NO_DEL_MEDEVENT'), false);

        if (j > 0)
            Trigger.old[i].Id.addError(System.Label.NO_DEL_MEDEVENT_SIGNED, false);
    }
}