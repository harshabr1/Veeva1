trigger VOD_EXPENSE_ESTIMATE_ROLLUP on EM_Expense_Estimate_vod__c (after insert, after update, after delete) {
    Set<Id> eventIds = new Set<Id>();
    Set<Id> eventsToRollup = new Set<Id>();
    Set<Id> eventBudgetIds = new Set<Id>();
    Set<Id> eventBudgetsToRollup = new Set<Id>();
    Set<Id> typeIds = new Set<Id>();
    
    if(Trigger.isInsert) {
    	for (EM_Expense_Estimate_vod__c estimate: Trigger.new) {
            if (estimate.Event_vod__c != null) {
                eventIds.add(estimate.Event_vod__c);
            }
            if (estimate.Event_Budget_vod__c != null) {
                eventBudgetIds.add(estimate.Event_Budget_vod__c);
            }
            if (estimate.Expense_Type_vod__c != null) {
                typeIds.add(estimate.Expense_Type_vod__c);
            }
        } 
    } else if (Trigger.isUpdate) {
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
            if (after.Event_Budget_vod__c != null) {
                eventBudgetIds.add(after.Event_Budget_vod__c);
            }
            if (Trigger.oldMap.get(after.Id).Event_Budget_vod__c != null) {
                eventBudgetIds.add(Trigger.oldMap.get(after.Id).Event_Budget_vod__c);
            }
        }        
    } else if (Trigger.isDelete) {
	    for (EM_Expense_Estimate_vod__c estimate: Trigger.old) {
            if (estimate.Event_vod__c != null) {
                eventIds.add(estimate.Event_vod__c);
            }
            if (estimate.Event_Budget_vod__c != null) {
                eventBudgetIds.add(estimate.Event_Budget_vod__c);
            }
        }        
    }
    
    Map<Id, EM_Event_Budget_vod__c> eventBudgetMap = new Map<Id, EM_Event_Budget_vod__c>();
    Map<Id, EM_Event_vod__c> eventMap = new Map<Id, EM_Event_vod__c>([SELECT Id, Estimated_Cost_vod__c, Lock_vod__c,
                                                                      (SELECT Id, Estimate_vod__c, Budget_vod__c FROM Event_vod__r WHERE Id IN : eventBudgetIds)
                                                                      FROM EM_Event_vod__c
                                                                      WHERE Id IN : eventIds]);
    
    for (Id eventId : eventMap.keySet()) {
        EM_Event_vod__c event = eventMap.get(eventId);
        if (event.Event_vod__r != null) {
            for (EM_Event_Budget_vod__c budget : event.Event_vod__r) {
                eventBudgetMap.put(budget.Id, budget);
            }
        }
    }

    if(Trigger.isInsert) {
		for(EM_Expense_Estimate_vod__c estimate: Trigger.new) {
            Decimal estimateValue = estimate.Estimate_vod__c == null ? 0 : estimate.Estimate_vod__c;
            if(estimate.Event_vod__c != null && estimateValue != 0) {
                eventsToRollup.add(estimate.Event_vod__c);

            }
            if(estimate.Event_Budget_vod__c != null && estimateValue != 0) {
                eventBudgetsToRollup.add(estimate.Event_Budget_vod__c);
            }
        }
    } else if (Trigger.isUpdate) {
        boolean multiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();
		for(EM_Expense_Estimate_vod__c beforeEstimate: Trigger.old) {
            EM_Expense_Estimate_vod__c afterEstimate = Trigger.newMap.get(beforeEstimate.id);
            Decimal beforeEstimateValue = beforeEstimate.Estimate_vod__c == null ? 0 : beforeEstimate.Estimate_vod__c;
            Decimal afterEstimateValue = afterEstimate.Estimate_vod__c == null ? 0 : afterEstimate.Estimate_vod__c;

            //Event
            if(afterEstimate.Event_vod__c == beforeEstimate.Event_vod__c && afterEstimate.Event_vod__c != null) {
                eventsToRollup.add(afterEstimate.Event_vod__c);
            } else {
                if(beforeEstimate.Event_vod__c != null) {
                    eventsToRollup.add(beforeEstimate.Event_vod__c);
                }
                if(afterEstimate.Event_vod__c != null) {
                    eventsToRollup.add(afterEstimate.Event_vod__c);
                }
            }

            //Event Budget
            if(afterEstimate.Event_Budget_vod__c == beforeEstimate.Event_Budget_vod__c && afterEstimate.Event_Budget_vod__c != null && afterEstimateValue - beforeEstimateValue != 0){
                eventBudgetsToRollup.add(afterEstimate.Event_Budget_vod__c);
            } else {
                if(beforeEstimate.Event_Budget_vod__c != null && (beforeEstimateValue != 0 || (multiCurrency && beforeEstimate.get('CurrencyIsoCode') != afterEstimate.get('CurrencyIsoCode')))) {
                    eventBudgetsToRollup.add(beforeEstimate.Event_Budget_vod__c);
                }
                if(afterEstimate.Event_Budget_vod__c != null && (afterEstimateValue != 0 || (multiCurrency && beforeEstimate.get('CurrencyIsoCode') != afterEstimate.get('CurrencyIsoCode')))) {
                    eventBudgetsToRollup.add(afterEstimate.Event_Budget_vod__c);
                }
            }
        }
    } else if (Trigger.isDelete) {
    	for(EM_Expense_Estimate_vod__c estimate: Trigger.old) {
            Decimal estimateValue = estimate.Estimate_vod__c == null ? 0 : estimate.Estimate_vod__c;

            if(estimate.Event_vod__c != null && estimateValue != 0) {
                eventsToRollup.add(estimate.Event_vod__c);
            }
            if(estimate.Event_Budget_vod__c != null && estimateValue != 0) {
                eventBudgetsToRollup.add(estimate.Event_Budget_vod__c);
            }
        }
    }

    if (!eventsToRollup.isEmpty()) {
        VOD_EXPENSE_ESTIMATE_TRIG.calculateRollUptoEvent(eventsToRollup);
    }

    if (!eventBudgetsToRollup.isEmpty()) {
        VOD_EXPENSE_ESTIMATE_TRIG.calculateEventBudgets(eventBudgetsToRollup);
    }
}