trigger VOD_EXPENSE_ESTIMATE_UPDATE on EM_Expense_Estimate_vod__c (before update) {
    Set<Id> eventIds = new Set<Id>();
    Set<Id> typeIds = new Set<Id>();
    for (EM_Expense_Estimate_vod__c after : Trigger.new) {
        if (after.Event_vod__c != null) {
            eventIds.add(after.Event_vod__c);
        }
        if (Trigger.oldMap.get(after.Id).Event_vod__c != null) {
            eventIds.add(Trigger.oldMap.get(after.Id).Event_vod__c);
        }
        if (after.Expense_Type_vod__c != null) {
            typeIds.add(after.Expense_Type_vod__c);
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
    
    List<EM_Expense_Estimate_vod__c> estimates = new List<EM_Expense_Estimate_vod__c>();       
                     
    for(EM_Expense_Estimate_vod__c beforeEstimate: Trigger.old) {
        EM_Expense_Estimate_vod__c afterEstimate = Trigger.newMap.get(beforeEstimate.id);
        
        if(afterEstimate.Override_Lock_vod__c == true) {
            	afterEstimate.Override_Lock_vod__c = false;   
        } else if (afterEstimate.Event_vod__c != null && lockedEvents.contains(afterEstimate.Event_vod__c)) {
            afterEstimate.addError('Event is locked');
        }                    
    }        
}