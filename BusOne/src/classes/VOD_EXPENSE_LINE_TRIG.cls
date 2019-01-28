public class VOD_EXPENSE_LINE_TRIG {
    public static void rollUpMeals(EM_Event_vod__c event, Decimal aggregateCost, boolean overrideLock) {
        Decimal totalCount = event.Attendees_With_Meals_vod__c;
        if(overrideLock) {
            event.Override_Lock_vod__c = true;
        }
        if(totalCount != null && totalCount != 0) {
            if(aggregateCost != null) {
        		event.Actual_Meal_Cost_Per_Person_vod__c = aggregateCost/ totalCount;
            } else {
            	event.Actual_Meal_Cost_Per_Person_vod__c = 0;
            }
        } else {
        	event.Actual_Meal_Cost_Per_Person_vod__c = 0;
        }
    }

    public static void calculateEventBudgets(Set<Id> eventBudgetIds) {
        if(System.isFuture() || System.isBatch()) {
        	calculateEventBudgetSync(eventBudgetIds);
        } else {
        	calculateFuture(eventBudgetIds);
        }
    }

    @future
    public static void calculateFuture(Set<Id> eventBudgetIds) {
        calculateEventBudgetSync(eventBudgetIds);
    }

    public static void calculateEventBudgetSync(Set<Id> eventBudgetIds) {
        boolean isMultiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

        List<Expense_Line_vod__c> expenseLines;
        List<EM_Expense_Estimate_vod__c> expenseEstimates;

        if(isMultiCurrency) {
        	expenseLines = Database.query('SELECT Id, Event_vod__c, Actual_vod__c, Committed_vod__c, Event_Budget_vod__c, Event_Budget_vod__r.Budget_vod__c, CurrencyIsoCode, Event_Budget_vod__r.CurrencyIsoCode FROM Expense_Line_vod__c WHERE Event_Budget_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(eventbudgetIds));
            expenseEstimates = Database.query('SELECT Id, Event_vod__c, Estimate_vod__c, Event_Budget_vod__c, Event_Budget_vod__r.Budget_vod__c, CurrencyIsoCode, Event_Budget_vod__r.CurrencyIsoCode FROM EM_Expense_Estimate_vod__c WHERE Event_Budget_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(eventbudgetIds));
        } else {
        	expenseLines = [SELECT Id, Event_vod__c, Actual_vod__c, Committed_vod__c, Event_Budget_vod__c, Event_Budget_vod__r.Budget_vod__c FROM Expense_Line_vod__c WHERE Event_Budget_vod__c IN :eventBudgetIds];
            expenseEstimates = [SELECT Id, Event_vod__c, Estimate_vod__c, Event_Budget_vod__c, Event_Budget_vod__r.Budget_vod__c FROM EM_Expense_Estimate_vod__c WHERE Event_Budget_vod__c IN :eventBudgetIds];
        }

        Set<Id> emBudgetIds = new Set<Id>();
        Map<Id, EM_Event_Budget_vod__c> eventBudgets = new Map<Id, EM_Event_Budget_vod__c>();

        for(Id budgetId: eventBudgetIds) {
            eventBudgets.put(budgetId, new EM_Event_Budget_vod__c(Id=budgetId, Override_Lock_vod__c = true, Actual_vod__c = 0, Committed_vod__c = 0, Estimate_vod__c = 0));
        }

        for(EM_Event_Budget_vod__c eventBudget: [SELECT Budget_vod__c from EM_Event_Budget_vod__c where Id IN :eventBudgetIds AND Budget_vod__c != null]) {
            if(eventBudget.Budget_vod__c != null) {
            	emBudgetIds.add(eventBudget.Budget_vod__c);
            }
        }

        for(Expense_Line_vod__c line: expenseLines) {
            EM_Event_Budget_vod__c eventBudget = eventBudgets.get(line.Event_Budget_vod__c);

            Decimal actual = line.Actual_vod__c == null ? 0 : line.Actual_vod__c;
            Decimal committed = line.Committed_vod__c == null ? 0 : line.Committed_vod__c;

            if(isMultiCurrency) {
                String fromIsoCode = (String)line.get('CurrencyIsoCode');
                String toIsoCode = (String)line.getSobject('Event_Budget_vod__r').get('CurrencyIsoCode');

                actual = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, actual);
                committed = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, committed);
            }

			eventBudget.Actual_vod__c += actual;
            eventBudget.Committed_vod__c += committed;

            eventBudgets.put(line.Event_Budget_vod__c, eventBudget);
        }

        for(EM_Expense_Estimate_vod__c estimate:  expenseEstimates) {
        	EM_Event_Budget_vod__c eventBudget = eventBudgets.get(estimate.Event_Budget_vod__c);

            Decimal estimatedCost = estimate.Estimate_vod__c == null ? 0 : estimate.Estimate_vod__c;

            if(isMultiCurrency) {
                String fromIsoCode = (String)estimate.get('CurrencyIsoCode');
                String toIsoCode = (String)estimate.getSobject('Event_Budget_vod__r').get('CurrencyIsoCode');

                estimatedCost = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, estimatedCost);
            }

			eventBudget.Estimate_vod__c += estimatedCost;

            eventBudgets.put(estimate.Event_Budget_vod__c, eventBudget);
        }

        update eventBudgets.values();
        if(emBudgetIds.size() > 0) {
            calculateEMBudgets(emBudgetIds);
        }
    }

    public static void calculateEMBudgets(Set<Id> budgetIds) {
        boolean isMultiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

		List<EM_Event_Budget_vod__c> eventBudgets;
        List<EM_Budget_vod__c> childBudgets;

        if(isMultiCurrency) {
        	eventBudgets = Database.query('SELECT Budget_vod__c, Actual_vod__c, Committed_vod__c, Estimate_vod__c, Budget_vod__r.Parent_Budget_vod__c, Budget_vod__r.CurrencyIsoCode, CurrencyIsoCode FROM EM_Event_Budget_vod__c WHERE Budget_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(budgetIds));

            childBudgets = Database.query('SELECT Actual_Expenses_vod__c, Committed_Expenses_vod__c, Estimated_Expenses_vod__c, Parent_Budget_vod__r.Parent_Budget_vod__c, CurrencyIsoCode, Parent_Budget_vod__r.CurrencyIsoCode FROM EM_Budget_vod__c WHERE Parent_Budget_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(budgetIds));
        } else {
        	eventBudgets = [SELECT Budget_vod__c, Actual_vod__c, Committed_vod__c, Estimate_vod__c, Budget_vod__r.Parent_Budget_vod__c
                                                     FROM EM_Event_Budget_vod__c
                                                     WHERE Budget_vod__c IN :budgetIds];

            childBudgets = [SELECT Actual_Expenses_vod__c, Committed_Expenses_vod__c, Estimated_Expenses_vod__c, Parent_Budget_vod__r.Parent_Budget_vod__c
                                                   FROM EM_Budget_vod__c
                                                   WHERE Parent_Budget_vod__c IN :budgetIds];
        }


        Map<Id, EM_Budget_vod__c> emBudgets = new Map<Id,EM_Budget_vod__c>();
        Set<Id> parentBudgetIds = new Set<Id>();

        for(String budgetId: budgetIds) {
        	emBudgets.put(budgetId, new EM_Budget_vod__c(Id=budgetId, Actual_Expenses_vod__c = 0, Committed_Expenses_vod__c = 0, Estimated_Expenses_vod__c = 0));
        }

        for(EM_Event_Budget_vod__c eventBudget: eventBudgets) {
			EM_Budget_vod__c budget = emBudgets.get(eventBudget.Budget_vod__c);

            Decimal actual = eventBudget.Actual_vod__c == null ? 0 : eventBudget.Actual_vod__c;
            Decimal committed = eventBudget.Committed_vod__c == null ? 0 : eventBudget.Committed_vod__c;
            Decimal estimated = eventBudget.Estimate_vod__c == null ? 0 : eventBudget.Estimate_vod__c;

            if(isMultiCurrency) {
            	String fromIsoCode = (String)eventBudget.get('CurrencyIsoCode');
                String toIsoCode = (String)eventBudget.getSobject('Budget_vod__r').get('CurrencyIsoCode');

                actual = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, actual);
                committed = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, committed);
                estimated = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, estimated);
            }

			budget.Actual_Expenses_vod__c += actual;
			budget.Committed_Expenses_vod__c += committed;
			budget.Estimated_Expenses_vod__c += estimated;

            emBudgets.put(eventBudget.Budget_vod__c, budget);

            if(eventBudget.Budget_vod__r.Parent_Budget_vod__c != null) {
                parentBudgetIds.add(eventBudget.Budget_vod__r.Parent_Budget_vod__c);
            }
        }

        for(EM_Budget_vod__c childBudget: childBudgets) {
        	EM_Budget_vod__c budget = emBudgets.get(childBudget.Parent_Budget_vod__c);

            Decimal actual = childBudget.Actual_Expenses_vod__c == null ? 0 : childBudget.Actual_Expenses_vod__c;
            Decimal committed = childBudget.Committed_Expenses_vod__c == null ? 0 : childBudget.Committed_Expenses_vod__c;
            Decimal estimated = childBudget.Estimated_Expenses_vod__c == null ? 0 : childBudget.Estimated_Expenses_vod__c;

            if(isMultiCurrency) {
            	String fromIsoCode = (String)childBudget.get('CurrencyIsoCode');
                String toIsoCode = (String)childBudget.getSobject('Parent_Budget_vod__r').get('CurrencyIsoCode');

                actual = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, actual);
                committed = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, committed);
                estimated = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, estimated);
            }

			budget.Actual_Expenses_vod__c += actual;
			budget.Committed_Expenses_vod__c += committed;
			budget.Estimated_Expenses_vod__c += estimated;

            emBudgets.put(childBudget.Parent_Budget_vod__c, budget);

            if(childBudget.Parent_Budget_vod__r.Parent_Budget_vod__c != null) {
                parentBudgetIds.add(childBudget.Parent_Budget_vod__r.Parent_Budget_vod__c);
            }
        }

        update emBudgets.values();

        if(parentBudgetIds.size() > 0) {
            calculateEMBudgets(parentBudgetIds);
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

    public static void rollUptoEventSync(Set<Id> eventIds) {
        boolean isMultiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

        List<Expense_Line_vod__c> expenseLines;

        if(isMultiCurrency) {
            expenseLines = Database.query('SELECT Id, Actual_vod__c, Committed_vod__c, Event_vod__c, CurrencyIsoCode, Event_vod__r.CurrencyIsoCode FROM Expense_Line_vod__c WHERE Event_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(eventIds));
        } else {
        	expenseLines = [SELECT Id, Actual_vod__c, Committed_vod__c, Event_vod__c FROM Expense_Line_vod__c WHERE Event_vod__c IN :eventIds];
        }

        Map<Id, EM_Event_vod__c> events = new Map<Id, EM_Event_vod__c>();

        for(String eventId: eventIds) {
            events.put(eventId, new EM_Event_vod__c(Id=eventId, Override_Lock_vod__c = true, Actual_Cost_vod__c = 0, Committed_Cost_vod__c = 0));
        }

        for(Expense_Line_vod__c line: expenseLines) {
            EM_Event_vod__c currentEvent = events.get(line.Event_vod__c);

            Decimal actual = line.Actual_vod__c ==null ? 0 : line.Actual_vod__c;
            Decimal committed = line.Committed_vod__c ==null ? 0 : line.Committed_vod__c;

            if(isMultiCurrency) {
                String fromIsoCode = (String)line.get('CurrencyIsoCode');
                String toIsoCode = (String)line.getSobject('Event_vod__r').get('CurrencyIsoCode');

                actual = MultiCurrencyUtil.convertCurrency(fromIsoCode,toIsoCode, actual);
                committed = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, committed);
            }

            currentEvent.Actual_Cost_vod__c += actual;
            currentEvent.Committed_Cost_vod__c += committed;

            events.put(line.Event_vod__c, currentEvent);
        }

        update events.values();
    }

    public static void rollUptoEvent(Decimal committed, Decimal actual, EM_Event_vod__c event, boolean overrideLock) {
        if(event != null) {
            if(overrideLock) {
                event.Override_Lock_vod__c = true;
            }
            if(committed != 0 || actual != 0) {
				if(event.Actual_Cost_vod__c != null) {
                    event.Actual_Cost_vod__c += actual;
                } else {
                    event.Actual_Cost_vod__c = actual;
                }
                if(event.Committed_Cost_vod__c == null){
                    event.Committed_Cost_vod__c = committed;
                } else {
                    event.Committed_Cost_vod__c += committed;
                }
            }
        }
    }

    public static void calculateRollUptoExpenseEstimate(Set<Id> estimateIds) {
         if(System.isFuture() || System.isBatch()) {
        	rollUptoExpenseEstimateSync(estimateIds);
        } else {
        	calculateRollUptoExpenseEstimateFuture(estimateIds);
        }
     }

    @future
    public static void calculateRollUptoExpenseEstimateFuture(Set<Id> estimateIds) {
    	rollUptoExpenseEstimateSync(estimateIds);
    }

    public static void rollUptoExpenseEstimateSync(Set<Id> estimateIds) {
        boolean isMultiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

        List<Expense_Line_vod__c> expenseLines;

        if(isMultiCurrency) {
            expenseLines = Database.query('SELECT Id, Actual_vod__c, Committed_vod__c, Expense_Estimate_vod__c, CurrencyIsoCode, Expense_Estimate_vod__r.CurrencyIsoCode FROM Expense_Line_vod__c WHERE Expense_Estimate_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(estimateIds));
        } else {
        	expenseLines = [SELECT Id, Actual_vod__c, Committed_vod__c, Expense_Estimate_vod__c FROM Expense_Line_vod__c WHERE Expense_Estimate_vod__c IN :estimateIds];
        }

        Map<Id, EM_Expense_Estimate_vod__c> estimates = new Map<Id, EM_Expense_Estimate_vod__c>();

        for(String estimateId: estimateIds) {
            estimates.put(estimateId, new EM_Expense_Estimate_vod__c(Id=estimateId, Override_Lock_vod__c = true, Actual_vod__c = 0, Committed_vod__c = 0));
        }

        for(Expense_Line_vod__c line: expenseLines) {
            EM_Expense_Estimate_vod__c currentEstimate = estimates.get(line.Expense_Estimate_vod__c);

            Decimal actual = line.Actual_vod__c ==null ? 0 : line.Actual_vod__c;
            Decimal committed = line.Committed_vod__c ==null ? 0 : line.Committed_vod__c;

            if(isMultiCurrency) {
                String fromIsoCode = (String)line.get('CurrencyIsoCode');
                String toIsoCode = (String)line.getSobject('Expense_Estimate_vod__r').get('CurrencyIsoCode');

                actual = MultiCurrencyUtil.convertCurrency(fromIsoCode,toIsoCode, actual);
                committed = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, committed);
            }

            currentEstimate.Actual_vod__c += actual;
            currentEstimate.Committed_vod__c += committed;

            estimates.put(line.Expense_Estimate_vod__c, currentEstimate);
        }

        update estimates.values();
    }

    public static void rollUpToExpenseEstimate(Decimal committed, Decimal actual, EM_Expense_Estimate_vod__c estimate, boolean overrideLock) {
        if(estimate != null) {
            if(overrideLock) {
                estimate.Override_Lock_vod__c = true;
            }
            if(committed != 0 || actual != 0) {
            	if(estimate.Actual_vod__c != null) {
                    estimate.Actual_vod__c += actual;
                } else {
                    estimate.Actual_vod__c = actual;
                }

                if(estimate.Committed_vod__c != null) {
                    estimate.Committed_vod__c += committed;
                } else {
                    estimate.Committed_vod__c = committed;
                }
            }
        }
    }


}