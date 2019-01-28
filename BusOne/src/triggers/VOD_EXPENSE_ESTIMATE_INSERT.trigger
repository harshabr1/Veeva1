trigger VOD_EXPENSE_ESTIMATE_INSERT on EM_Expense_Estimate_vod__c (before insert) {
    Set<Id> eventIds = new Set<Id>();
    Set<Id> typeIds = new Set<Id>();
    
    for (EM_Expense_Estimate_vod__c estimate: Trigger.new) {
        if (estimate.Event_vod__c != null) {
            eventIds.add(estimate.Event_vod__c);
        }
        if (estimate.Expense_Type_vod__c != null) {
            typeIds.add(estimate.Expense_Type_vod__c);
        }
    }

    Map<Id, EM_Event_vod__c> eventMap = new Map<Id, EM_Event_vod__c>([SELECT Id, Estimated_Cost_vod__c, Lock_vod__c
                                                                      FROM EM_Event_vod__c
                                                                      WHERE Id IN : eventIds]);
    Set<String> lockedEvents = new Set<String>();
    for (Id eventId : eventMap.keySet()) {
        EM_Event_vod__c event = eventMap.get(eventId);
        if(VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    Map<Id, Expense_Type_vod__c> typeMap = new Map<Id, Expense_Type_vod__c>([SELECT Id, Name, Expense_Code_vod__c, Parent_Expense_Type_vod__r.Name, Parent_Expense_Type_vod__r.Expense_Code_vod__c
                                                                             FROM Expense_Type_vod__c
                                                                             WHERE Id IN : typeIds]);
    
    for (EM_Expense_Estimate_vod__c estimate : Trigger.new) {
        if(estimate.Expense_Type_vod__c != null) {
            Expense_Type_vod__c expenseType = typeMap.get(estimate.Expense_Type_vod__c);
            estimate.Expense_Type_Name_vod__c = expenseType.Name;
            estimate.Expense_Type_Code_vod__c = expenseType.Expense_Code_vod__c; 
        }            
    }
    

    for(EM_Expense_Estimate_vod__c estimate: Trigger.new) {
        if(estimate.Override_Lock_vod__c == true) {
            estimate.Override_Lock_vod__c = false;
        } else if (estimate.Event_vod__c != null && lockedEvents.contains(estimate.Event_vod__c)) {
            estimate.addError('Event is locked');
        }
    }
}