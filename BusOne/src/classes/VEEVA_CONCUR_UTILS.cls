public with sharing class VEEVA_CONCUR_UTILS {
	
	// Check if it is a concur update for a call
    public static boolean isConcurUpdate(List<Call2_vod__c> oldCalls, List<Call2_vod__c> newCalls) {
        if (oldCalls == null || oldCalls.size() == 0 || newCalls == null || newCalls.size() == 0) {
            return false;
        }

        Call2_vod__c firstOldCall = oldCalls[0];
        Call2_vod__c firstNewCall = newCalls[0];
        
        // Concur modifies Expense Post Status, Override Lock, and Expense System External Id for Calls
        // If the calls originally didn't have Expense_Post_Status_vod populated but now do, assume this trigger
        // was called from the Concur Sync batch job.
        Boolean concurUpdate = firstOldCall != null && firstNewCall != null
                 				&& firstOldCall.Expense_Post_Status_vod__c == 'Pending'
                 				&& isUpdateComplete(firstNewCall.Expense_Post_Status_vod__c);
        
        System.debug(LoggingLevel.INFO, 'Call Concur Update: ' + concurUpdate);
        return concurUpdate;
    }

    // Check if it is a concur update for a medical event
    public static boolean isConcurUpdate(List<Medical_Event_vod__c> oldMedicalEvents, List<Medical_Event_vod__c> newMedicalEvents) {
        if (oldMedicalEvents == null || oldMedicalEvents.size() == 0 || newMedicalEvents == null || newMedicalEvents.size() == 0) {
            return false;
        }

        Medical_Event_vod__c firstOldMedicalEvent = oldMedicalEvents[0];
        Medical_Event_vod__c firstNewMedicalEvent = newMedicalEvents[0];

        // Concur modifies Expense Post Status, and Expense System External Id for Medical Events
        // If the medical events originally didn't have Expense_Post_Status_vod populated but now do, assume this trigger
        // was called from the Concur Sync batch job.
        Boolean concurUpdate = firstOldMedicalEvent != null && firstNewMedicalEvent != null
                                && firstOldMedicalEvent.Expense_Post_Status_vod__c != null
                                && isUpdateComplete(firstNewMedicalEvent.Expense_Post_Status_vod__c);
       	
        System.debug(LoggingLevel.INFO, 'Medical Event Concur Update: ' + concurUpdate);
        return concurUpdate;
    }
    
    // Check if the new value is either SUCCESS or FAILED (which indicates an update)
    public static boolean isUpdateComplete(String value) {
        return (value == 'SUCCESS' || value == 'FAILED');
    }

    // Check if concur sync is pending for a Call
    public static boolean concurSyncPending(Call2_vod__c call) {
        return call.Expense_Post_Status_vod__c == null
            && call.Expense_Amount_vod__c > 0
            && call.Is_Parent_Call_vod__c == 1.0
            && call.Status_vod__c == 'Submitted_vod';
    }

    // Check if concur sync is pending for a medical event
    public static boolean concurSyncPending(Medical_Event_vod__c medicalEvent) {
        return medicalEvent.Expense_Post_Status_vod__c == null
            && medicalEvent.Expense_Amount_vod__c > 0
            && medicalEvent.Submit_Expense_vod__c == true;
    }
}