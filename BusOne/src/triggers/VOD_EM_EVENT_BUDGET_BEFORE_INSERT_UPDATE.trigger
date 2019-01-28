trigger VOD_EM_EVENT_BUDGET_BEFORE_INSERT_UPDATE on EM_Event_Budget_vod__c (before insert, before update) {
    Set<Id> eventIds = new Set<Id>();
    for (EM_Event_Budget_vod__c budget : Trigger.new) {
        eventIds.add(budget.Event_vod__c);
    }
    List<EM_Event_vod__c> events = [SELECT Id, Override_Lock_vod__c, Lock_vod__c FROM EM_Event_vod__c WHERE Id IN : eventIds];
    Set<Id> lockedEvents = new Set<Id>();
    for (EM_Event_vod__c event : events) {
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }
    for (EM_Event_Budget_vod__c budget : Trigger.new) {
        if(budget.Override_Lock_vod__c == true) {
            budget.Override_Lock_vod__c = false;
        } else if (budget.Event_vod__c != null && lockedEvents.contains(budget.Event_vod__c)) {
            budget.addError('Event is locked');
        }
    }

    String duplicateText = 'This budget is already associated with this event';
    Message_vod__c duplicateMessage;
    try {
        duplicateMessage = [Select Text_vod__c
        From Message_vod__c
        Where Name='DUPLICATE_EVENT_BUDGET_ERROR' AND
        Category_vod__c='EVENT_MANAGEMENT' AND
        Active_vod__c=true AND
        Language_vod__c=:UserInfo.getLanguage()];
    } catch(Exception e) {
        duplicateMessage = null;
    }

    if(duplicateMessage != null){
        duplicateText = duplicateMessage.Text_vod__c;
    }

    List<EM_Event_Budget_vod__c> eventBudgets = [SELECT Budget_vod__c, Event_vod__c
    FROM EM_Event_Budget_vod__c
    WHERE Event_vod__c IN :eventIds];
    Map<Id, Set<Id>> eventToBudgets = new Map<Id, Set<Id>>();

    for(EM_Event_Budget_vod__c eventBudget: eventBudgets) {
        if(eventBudget.Event_vod__c != null) {
            Set<Id> currentBudgets = eventToBudgets.get(eventBudget.Event_vod__c);
            if(currentBudgets == null) {
                currentBudgets = new Set<Id>();
            }
            if(eventBudget.Budget_vod__c != null) {
                currentBudgets.add(eventBudget.Budget_vod__c);
                eventToBudgets.put(eventBudget.Event_vod__c, currentBudgets);
            }
        }
    }

    for(EM_Event_Budget_vod__c eventBudget: Trigger.new) {
        if (eventBudget.Budget_vod__c != null && eventBudget.Event_vod__c != null &&
        (Trigger.isInsert || Trigger.oldMap.get(eventBudget.Id).Budget_vod__c != eventBudget.Budget_vod__c)) {
            Set<Id> usedBudgets = eventToBudgets.get(eventBudget.Event_vod__c);
            if(usedBudgets != null && usedBudgets.contains(eventBudget.Budget_vod__c)) {
                eventBudget.addError(duplicateText);
            } else {
                if (usedBudgets == null) {
                    usedBudgets = new Set<Id>();
                }
                usedBudgets.add(eventBudget.Budget_vod__c);
                eventToBudgets.put(eventBudget.Event_vod__c, usedBudgets);
            }
        }
    }
}