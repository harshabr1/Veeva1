trigger VEEVA_MEDICAL_EVENT_CONCUR_EXPENSE on Medical_Event_vod__c (before insert, before update) {
    // If this is a Concur Update, then skip all trigger logic.
    if (VEEVA_CONCUR_UTILS.isConcurUpdate(Trigger.old, Trigger.new)) {
        return;
    }

    // Mark off medical events as either needing a Concur Sync or not
    for (Medical_Event_vod__c medicalEvent : Trigger.new) {
        if(VEEVA_CONCUR_UTILS.concurSyncPending(medicalEvent)) {
            medicalEvent.Expense_Post_Status_vod__c = 'Pending';
        }
    }
}