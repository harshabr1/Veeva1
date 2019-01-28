trigger VOD_EVENT_UPDATE on EM_Event_vod__c (before update) {
    boolean eventClosed = false;
    for (EM_Event_vod__c newEvent : Trigger.new) {
        EM_Event_vod__c oldEvent = Trigger.oldMap.get(newEvent.Id);
        if((newEvent.Status_vod__c == 'Closed_vod' || newEvent.Status_vod__c == 'Canceled_vod') && (oldEvent.Status_vod__c != 'Closed_vod' || oldEvent.Status_vod__c != 'Canceled_vod')) {
        	eventClosed = true;
            break;
        }
    }

    if(eventClosed) {
    	List<EM_Event_Budget_vod__c> eventBudgets = [Select Id, Event_vod__c, Actual_vod__c, Committed_vod__c, Estimate_vod__c, Budget_vod__c
        											 FROM EM_Event_Budget_vod__c WHERE Event_vod__c IN : Trigger.newMap.keySet()];
        List<EM_Event_Budget_vod__c> eventBudgetsToUpdate = new List<EM_Event_Budget_vod__c>();

        Map<Id, List<EM_Event_Budget_vod__c>> eventToEventBudgets = new Map<Id, List<EM_Event_Budget_vod__c>>();
        for (EM_Event_Budget_vod__c eventBudget : eventBudgets) {
            if (eventToEventBudgets.get(eventBudget.Event_vod__c) == null) {
                eventToEventBudgets.put(eventBudget.Event_vod__c, new List<EM_Event_Budget_vod__c>());
            }
            eventToEventBudgets.get(eventBudget.Event_vod__c).add(eventBudget);
        }

        List<EM_Event_Speaker_vod__c> eventSpeakers = [SELECT Id, Event_vod__c, Speaker_vod__c
                                                       FROM EM_Event_Speaker_vod__c WHERE Event_vod__c IN :Trigger.newMap.keySet()];
        Set<Id> speakersToUpdate = new Set<Id>();
        Map<Id, Set<Id>> eventToSpeakers = new Map<Id, Set<Id>>();
        for (EM_Event_Speaker_vod__c eventSpeaker : eventSpeakers) {
            if (eventToSpeakers.get(eventSpeaker.Event_vod__c) == null) {
                eventToSpeakers.put(eventSpeaker.Event_vod__c, new Set<Id>());
            }
            eventToSpeakers.get(eventSpeaker.Event_vod__c).add(eventSpeaker.Speaker_vod__c);
        }

        Map<Id, List<EM_Event_History_vod__c>> eventToEventHistories = new Map<Id, List<EM_Event_History_vod__c>>();

        for (EM_Event_vod__c newEvent : Trigger.new) {
            EM_Event_vod__c oldEvent = Trigger.oldMap.get(newEvent.Id);
            if((newEvent.Status_vod__c == 'Closed_vod' || newEvent.Status_vod__c == 'Canceled_vod') && (oldEvent.Status_vod__c != 'Closed_vod' || oldEvent.Status_vod__c != 'Canceled_vod')) {

                if(eventToSpeakers.get(newEvent.Id) != null) {
                    speakersToUpdate.addAll(eventToSpeakers.get(newEvent.Id));
                }

                List<EM_Event_Budget_vod__c> budgets = eventToEventBudgets.get(newEvent.Id);
                if (budgets != null) {
                    for(EM_Event_Budget_vod__c eventBudget : budgets) {
                        Decimal actual = eventBudget.Actual_vod__c == null ? 0 : eventBudget.Actual_vod__c;
                        Decimal committed = eventBudget.Committed_vod__c == null ? 0 : eventBudget.Committed_vod__c;
                        Decimal estimated = eventBudget.Estimate_vod__c == null ? 0 : eventBudget.Estimate_vod__c;
                        Decimal committedDifference = actual - committed;
                        Decimal estimatedDifference = actual - estimated;
                        eventBudget.Committed_vod__c = actual;
                        eventBudget.Estimate_vod__c = actual;
                        eventBudget.Override_Lock_vod__c = true;
                        eventBudgetsToUpdate.add(eventBudget);

                        System.debug('Actual: ' + actual +
                                ' Committed: ' + committed +
                                ' Estimated: ' + estimated +
                                ' Budget: ' + eventBudget.Budget_vod__c);

                        if(eventBudget.Budget_vod__c != null) {
                            VOD_EVENT_TRIG.rollUpToBudget(committedDifference, estimatedDifference, eventBudget.Budget_vod__c);
                        }
                    }
                }
            }
        }

        if(!speakersToUpdate.isEmpty()) {
            SpeakerYTDCalculator.calculate(speakersToUpdate);
        }

        if (!eventBudgetsToUpdate.isEmpty()) {
            update eventBudgetsToUpdate;
        }
    }

}