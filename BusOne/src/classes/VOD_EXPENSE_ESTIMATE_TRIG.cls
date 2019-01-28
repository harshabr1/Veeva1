public class VOD_EXPENSE_ESTIMATE_TRIG {

    public static void calculateEventBudgets(Set<Id> eventBudgetIds) {
        if(System.isFuture() || System.isBatch()) {
            calculateEventBudgetsSync(eventBudgetIds);
        } else {
            calculateEventBudgetsFuture(eventBudgetIds);
        }
    }

    @future
    public static void calculateEventBudgetsFuture(Set<Id> eventBudgetIds) {
    	calculateEventBudgetsSync(eventBudgetIds);
    }

    public static void calculateEventBudgetsSync(Set<Id> eventBudgetIds) {
        boolean isMultiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

        List<EM_Expense_Estimate_vod__c> expenseEstimates;

        if(isMultiCurrency) {
            expenseEstimates = (List<EM_Expense_Estimate_vod__c>) Database.query('SELECT Id, Estimate_vod__c, Event_Budget_vod__c, Event_Budget_vod__r.Budget_vod__c, CurrencyIsoCode, Event_Budget_vod__r.CurrencyIsoCode FROM EM_Expense_Estimate_vod__c WHERE Event_Budget_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(eventBudgetIds));
        } else {
        	expenseEstimates = [SELECT Id, Estimate_vod__c, Event_Budget_vod__c, Event_Budget_vod__r.Budget_vod__c FROM EM_Expense_Estimate_vod__c WHERE Event_Budget_vod__c IN :eventBudgetIds];
        }

        Set<Id> emBudgetIds = new Set<Id>();
        Map<Id, EM_Event_Budget_vod__c> eventBudgets = new Map<Id, EM_Event_Budget_vod__c>();

        for(Id budgetId: eventBudgetIds) {
            eventBudgets.put(budgetId, new EM_Event_Budget_vod__c(Id=budgetId, Override_Lock_vod__c = true, Estimate_vod__c = 0));
        }

        for(EM_Event_Budget_vod__c eventBudget: [SELECT Budget_vod__c from EM_Event_Budget_vod__c where Id IN :eventBudgetIds AND Budget_vod__c != null]) {
            if(eventBudget.Budget_vod__c != null) {
            	emBudgetIds.add(eventBudget.Budget_vod__c);
            }
        }

        for(EM_Expense_Estimate_vod__c estimate: expenseEstimates) {
            EM_Event_Budget_vod__c eventBudget = eventBudgets.get(estimate.Event_Budget_vod__c);

            Decimal estimated = estimate.Estimate_vod__c ==null ? 0 : estimate.Estimate_vod__c;

            if(isMultiCurrency) {
                String fromIsoCode = (String)estimate.get('CurrencyIsoCode');
                String toIsoCode = (String)estimate.getSobject('Event_Budget_vod__r').get('CurrencyIsoCode');

                estimated = MultiCurrencyUtil.convertCurrency(fromIsoCode,toIsoCode, estimated);
            }

            eventbudget.Estimate_vod__c += estimated;

            eventBudgets.put(estimate.Event_Budget_vod__c, eventBudget);

        }

        update eventBudgets.values();
        if(emBudgetIds.size() > 0) {
            VOD_EXPENSE_LINE_TRIG.calculateEMBudgets(emBudgetIds);
        }
    }



    public static void calculateRollUptoEvent(Set<Id> eventIds) {
         if(System.isFuture() || System.isBatch()) {
        	rollUptoEventSync(eventIds);
        } else {
        	calculateRollUptoEventFuture(eventIds);
        }
     }

    @future
    public static void calculateRollUptoEventFuture(Set<Id> eventIds) {
    	rollUptoEventSync(eventIds);
    }

    public static void rollUptoEventSync(Set<Id> eventIds){
        boolean isMultiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

        List<EM_Expense_Estimate_vod__c> expenseEstimates;

        if(isMultiCurrency) {
            expenseEstimates = Database.query('SELECT Id, Estimate_vod__c, Event_vod__c, CurrencyIsoCode, Event_vod__r.CurrencyIsoCode FROM EM_Expense_Estimate_vod__c WHERE Event_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(eventIds));
        } else {
        	expenseEstimates = [SELECT Id, Estimate_vod__c, Event_vod__c FROM EM_Expense_Estimate_vod__c WHERE Event_vod__c IN :eventIds];
        }


        Map<Id, EM_Event_vod__c> events = new Map<Id, EM_Event_vod__c>();

        for(String eventId: eventIds) {
            events.put(eventId, new EM_Event_vod__c(Id=eventId, Override_Lock_vod__c = true, Estimated_Cost_vod__c = 0));
        }

        for(EM_Expense_Estimate_vod__c estimate: expenseEstimates) {
            EM_Event_vod__c currentEvent = events.get(estimate.Event_vod__c);
            Decimal estimated = estimate.Estimate_vod__c ==null ? 0 : estimate.Estimate_vod__c;

            if(isMultiCurrency) {
                String fromIsoCode = (String)estimate.get('CurrencyIsoCode');
                String toIsoCode = (String)estimate.getSobject('Event_vod__r').get('CurrencyIsoCode');

                estimated = MultiCurrencyUtil.convertCurrency(fromIsoCode,toIsoCode, estimated);
            }

            currentEvent.Estimated_Cost_vod__c += estimated;

            events.put(estimate.Event_vod__c, currentEvent);
        }

        update events.values();
    }


    public static void rollUptoEvent(Decimal difference, EM_Event_vod__c event, boolean overrideLock){
        if(event != null) {
            if(overrideLock) {
                event.Override_Lock_vod__c = true;
            }
            if(difference != 0) {
            	if(event.Estimated_Cost_vod__c != null) {
                    event.Estimated_Cost_vod__c += difference;
                } else {
                    event.Estimated_Cost_vod__c = difference;
                }
            }
        }
    }
}