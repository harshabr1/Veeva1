trigger VOD_EXPENSE_LINE_ROLLUP on Expense_Line_vod__c (after insert, after update, after delete) {
    Map<Id, Expense_Line_vod__c > afterExpenses = Trigger.newMap;
    Set<Id> eventIds = new Set<Id>();
    Set<Id> typeIds = new Set<Id>();
    Set<Id> estimateIds = new Set<Id>();
    Set<Id> eventBudgetIds = new Set<Id>();
    Set<Id> headerIds = new Set<Id>();
    
    Set<Id> eventExpensesToRollup = new Set<Id>();
    Set<Id> eventCountsToRollup = new Set<Id>();
    Set<Id> eventBudgetsToRollup = new Set<Id>();
    Set<Id> estimatesToRollup = new Set<Id>();
    Set<Id> speakersToRollup = new Set<Id>();

    Map<Id, EM_Event_Budget_vod__c> eventBudgetMap = new Map<Id, EM_Event_Budget_vod__c>();
    Map<Id, EM_Expense_Estimate_vod__c> estimateMap = new Map<Id, EM_Expense_Estimate_vod__c>();
    Map<Id, Expense_Header_vod__c> headerMap = new Map<Id, Expense_Header_vod__c>();

    //Initialize related Ids
    if(Trigger.isInsert) {
		for (Expense_Line_vod__c line : Trigger.new) {
            if (line.Event_vod__c != null) {
                eventIds.add(line.Event_vod__c);
            }
            if (line.Expense_Type_vod__c != null) {
                typeIds.add(line.Expense_Type_vod__c);
            }
            if (line.Expense_Estimate_vod__c != null) {
                estimateIds.add(line.Expense_Estimate_vod__c);
            }
            if (line.Event_Budget_vod__c != null) {
                eventBudgetIds.add(line.Event_Budget_vod__c);
            }
            if (line.Expense_Header_vod__c != null) {
                headerIds.add(line.Expense_Header_vod__c);
            }
        }

    } else if(Trigger.isUpdate) {
		for (Id expenseId : afterExpenses.keySet()) {
            Expense_Line_vod__c afterExpense = afterExpenses.get(expenseId);
            if (afterExpense.Event_vod__c != null) {
                eventIds.add(afterExpense.Event_vod__c);
            }
            if (afterExpense.Expense_Type_vod__c != null) {
                typeIds.add(afterExpense.Expense_Type_vod__c);
            }
            if (Trigger.oldMap.get(afterExpense.Id).Expense_Type_vod__c != null) {
                typeIds.add(Trigger.oldMap.get(afterExpense.Id).Expense_Type_vod__c);
            }
            if (afterExpense.Event_Budget_vod__c != null) {
                eventBudgetIds.add(afterExpense.Event_Budget_vod__c);
            }
            if (Trigger.oldMap.get(afterExpense.Id).Event_Budget_vod__c != null) {
                eventBudgetIds.add(Trigger.oldMap.get(afterExpense.Id).Event_Budget_vod__c);
            }
            if (afterExpense.Expense_Estimate_vod__c != null) {
                estimateIds.add(afterExpense.Expense_Estimate_vod__c);
            }
            if (Trigger.oldMap.get(afterExpense.Id).Expense_Estimate_vod__c != null) {
                estimateIds.add(Trigger.oldMap.get(afterExpense.Id).Expense_Estimate_vod__c);
            }
            if (afterExpense.Expense_Header_vod__c != null) {
                headerIds.add(afterExpense.Expense_Header_vod__c);
            }
        }
    } else if(Trigger.isDelete) {
		for (Expense_Line_vod__c line : Trigger.old) {
            if (line.Event_vod__c != null) {
                eventIds.add(line.Event_vod__c);
            }
            if (line.Expense_Type_vod__c != null) {
                typeIds.add(line.Expense_Type_vod__c);
            }
            if (line.Expense_Estimate_vod__c != null) {
                estimateIds.add(line.Expense_Estimate_vod__c);
            }
            if (line.Event_Budget_vod__c != null) {
                eventBudgetIds.add(line.Event_Budget_vod__c);
            }
            if (line.Expense_Header_vod__c != null) {
                headerIds.add(line.Expense_Header_vod__c);
            }
        }
    }


    Map<Id, Expense_Type_vod__c> typeMap = new Map<Id, Expense_Type_vod__c>([SELECT Id, Name, Expense_Code_vod__c, Parent_Expense_Type_vod__r.Name, Parent_Expense_Type_vod__r.Expense_Code_vod__c,
                                                                                 Meal_Expense_vod__c, Included_In_Speaker_Cap_vod__c
                                                                                 FROM Expense_Type_vod__c
                                                                                 WHERE Id IN : typeIds]);
    Map<Id, EM_Event_vod__c> eventMap = new Map<Id, EM_Event_vod__c>([SELECT Id, Actual_Cost_vod__c, Committed_Cost_vod__c, Attendees_With_Meals_vod__c, Actual_Meal_Cost_Per_Person_vod__c, Lock_vod__c, Override_Lock_vod__c,
                                                                      (SELECT Id, Actual_vod__c, Committed_vod__c, Budget_vod__c FROM Event_vod__r WHERE Id IN : eventBudgetIds),
                                                                      (Select Id, Actual_vod__c, Committed_vod__c FROM Expense_Estimate_vod__r WHERE Id IN : estimateIds),
                                                                      (Select Id, Incurred_Expense_Account_vod__c, Incurred_Expense_Attendee_vod__r.Account_vod__c, Incurred_Expense_Speaker_vod__r.Speaker_vod__c FROM Expense_Header_vod__r WHERE Id IN : headerIds)
                                                                      FROM EM_Event_vod__c
                                                                      WHERE Id IN : eventIds]);

    if(Trigger.isInsert) {
        for (Id eventId : eventMap.keySet()) {
            EM_Event_vod__c event = eventMap.get(eventId);
            if (event.Event_vod__r != null) {
                for (EM_Event_Budget_vod__c eventBudget : event.Event_vod__r) {
                    eventBudgetMap.put(eventBudget.Id, eventBudget);
                }
            }
            if (event.Expense_Estimate_vod__r != null) {
                for (EM_Expense_Estimate_vod__c estimate : event.Expense_Estimate_vod__r) {
                    estimateMap.put(estimate.Id, estimate);
                }
            }
            if (event.Expense_Header_vod__r != null) {
                for (Expense_Header_vod__c header : event.Expense_Header_vod__r) {
                    headerMap.put(header.Id, header);
                }
            }
        }

        Set<Id> speakerIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for (Id headerId : headerMap.keySet()) {
            Expense_Header_vod__c header = headerMap.get(headerId);
            if (header.Incurred_Expense_Speaker_vod__r.Speaker_vod__c != null) {
                speakerIds.add(header.Incurred_Expense_Speaker_vod__r.Speaker_vod__c);
            } else {
                Id accountId = header.Incurred_Expense_Account_vod__c != null ? header.Incurred_Expense_Account_vod__c : header.Incurred_Expense_Attendee_vod__r.Account_vod__c;
                if(accountId != null) {
                    accountIds.add(accountId);
                }
            }
        }
        Map<Id, EM_Speaker_vod__c> speakerMap = new Map<Id, EM_Speaker_vod__c>([SELECT Id, Year_to_Date_Spend_vod__c, Account_vod__c FROM EM_Speaker_vod__c WHERE Id IN : speakerIds OR Account_vod__c IN : accountIds]);
        for (Id speakerId : speakerMap.keySet()) {
            speakersToRollup.add(speakerId);
        }

        for (Expense_Line_vod__c expense: Trigger.new) {
            Decimal actual = expense.Actual_vod__c == null ? 0: expense.Actual_vod__c;
            Expense_Type_vod__c expenseType = null;
            if(expense.Expense_Type_vod__c != null) {
                expenseType = typeMap.get(expense.Expense_Type_vod__c);
            }
            Decimal committed = expense.Committed_vod__c == null ? 0: expense.Committed_vod__c;
            if(expense.Event_vod__c != null) {
                eventExpensesToRollup.add(expense.Event_vod__c);
            }
            if(expense.Expense_Estimate_vod__c != null) {
                estimatesToRollup.add(expense.Expense_Estimate_vod__c);
            }
            if(expense.Event_Budget_vod__c != null) {
                eventBudgetsToRollup.add(expense.Event_Budget_vod__c);
            }
        }

        for (Expense_Line_vod__c expense: Trigger.new) {
            Expense_Type_vod__c expenseType = null;
            if (expense.Expense_Type_vod__c != null) {
                expenseType = typeMap.get(expense.Expense_Type_vod__c);
            }
            if (expenseType != null && expenseType.Meal_Expense_vod__c && expense.Event_vod__c != null) {
                eventCountsToRollup.add(expense.Event_vod__c);
            }
        }

    } else if (Trigger.isUpdate) {
        Map<Id, Expense_Attribution_vod__c> attrMap = new Map<Id, Expense_Attribution_vod__c>([SELECT Incurred_Expense_Speaker_vod__c, Incurred_Expense_Speaker_vod__r.Speaker_vod__c,
                                                                                               		  Incurred_Expense_Account_vod__c, Incurred_Expense_Attendee_vod__r.Account_vod__c
                                                                                               FROM Expense_Attribution_vod__c
                                                                                               WHERE Expense_Line_vod__r.Expense_Header_vod__r.Event_vod__c IN :eventIds
                                                                                               AND Expense_Line_vod__r.Expense_Type_vod__r.Included_In_Speaker_Cap_vod__c = true
                                                                                               AND (Incurred_Expense_Speaker_vod__c != null OR Incurred_Expense_Account_vod__c != null OR Incurred_Expense_Attendee_vod__r.Account_vod__c != null)]);

        for (Id eventId : eventMap.keySet()) {
            EM_Event_vod__c event = eventMap.get(eventId);
            if (event.Event_vod__r != null) {
                for (EM_Event_Budget_vod__c eventBudget : event.Event_vod__r) {
                    eventBudgetMap.put(eventBudget.Id, eventBudget);
                }
            }
            if (event.Expense_Estimate_vod__r != null) {
                for (EM_Expense_Estimate_vod__c estimate : event.Expense_Estimate_vod__r) {
                    estimateMap.put(estimate.Id, estimate);
                }
            }
            if (event.Expense_Header_vod__r != null) {
                for (Expense_Header_vod__c header : event.Expense_Header_vod__r) {
                    headerMap.put(header.Id, header);
                }
            }
        }

        Set<Id> speakerIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for (Id headerId : headerMap.keySet()) {
            Expense_Header_vod__c header = headerMap.get(headerId);
            if (header.Incurred_Expense_Speaker_vod__r.Speaker_vod__c != null) {
                speakerIds.add(header.Incurred_Expense_Speaker_vod__r.Speaker_vod__c);
            } else {
                Id accountId = header.Incurred_Expense_Account_vod__c != null ? header.Incurred_Expense_Account_vod__c : header.Incurred_Expense_Attendee_vod__r.Account_vod__c;
                if(accountId != null) {
                    accountIds.add(accountId);
                }
            }
        }

        for(Id attrId: attrMap.keySet()) {
            Expense_Attribution_vod__c attr = attrMap.get(attrId);
            if(attr.Incurred_Expense_Speaker_vod__c != null) {
                speakerIds.add(attr.Incurred_Expense_Speaker_vod__r.Speaker_vod__c);
            } else if(attr.Incurred_Expense_Account_vod__c != null) {
            	accountIds.add(attr.Incurred_Expense_Account_vod__c);
            } else if (attr.Incurred_Expense_Attendee_vod__r.Account_vod__c != null) {
                accountIds.add(attr.Incurred_Expense_Attendee_vod__r.Account_vod__c);
            }
        }

        Map<Id, EM_Speaker_vod__c> speakerMap = new Map<Id, EM_Speaker_vod__c>([SELECT Id, Year_to_Date_Spend_vod__c, Account_vod__c
                                                                                FROM EM_Speaker_vod__c
                                                                                WHERE Id IN : speakerIds OR Account_vod__c IN : accountIds]);
        for (Id speakerId : speakerMap.keySet()) {
            speakersToRollup.add(speakerId);
        }

        boolean multiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

        for(Expense_Line_vod__c  beforeExpense: Trigger.old) {
            Expense_Line_vod__c  afterExpense = afterExpenses.get(beforeExpense.id);

            Decimal beforeCommitted = beforeExpense.Committed_vod__c == null ? 0: beforeExpense.Committed_vod__c;
            Decimal beforeActual = beforeExpense.Actual_vod__c == null ? 0: beforeExpense.Actual_vod__c;
            Decimal afterCommitted = afterExpense.Committed_vod__c == null ? 0: afterExpense.Committed_vod__c;
            Decimal afterActual = afterExpense.Actual_vod__c == null ? 0: afterExpense.Actual_vod__c;

            //Event
            if(beforeExpense.Event_vod__c == afterExpense.Event_vod__c && afterExpense.Event_vod__c != null) {
                eventExpensesToRollup.add(afterExpense.Event_vod__c);
            } else {
                if (beforeExpense.Event_vod__c != null) {
                    eventExpensesToRollup.add(beforeExpense.Event_vod__c);
                }
                if(afterExpense.Event_vod__c != null) {
                    eventExpensesToRollup.add(afterExpense.Event_vod__c);
                }
            }

            //Event Budget
            if((beforeExpense.Event_Budget_vod__c == afterExpense.Event_Budget_vod__c && afterExpense.Event_Budget_vod__c != null) &&
               (afterCommitted - beforeCommitted != 0 || afterActual - beforeActual != 0 || (multiCurrency && beforeExpense.get('CurrencyIsoCode') != afterExpense.get('CurrencyIsoCode')))) {
                eventBudgetsToRollup.add(afterExpense.Event_Budget_vod__c);
            } else {
                if(beforeExpense.Event_Budget_vod__c != null && (beforeCommitted != 0 || beforeActual != 0 || (multiCurrency && beforeExpense.get('CurrencyIsoCode') != afterExpense.get('CurrencyIsoCode')))) {
                    eventBudgetsToRollup.add(beforeExpense.Event_Budget_vod__c);
                }
                if(afterExpense.Event_Budget_vod__c != null && (afterCommitted != 0 || afterActual != 0|| (multiCurrency && beforeExpense.get('CurrencyIsoCode') != afterExpense.get('CurrencyIsoCode')))) {
                    eventBudgetsToRollup.add(afterExpense.Event_Budget_vod__c);
                }
            }

            //Expense Estimate
            if(beforeExpense.Expense_Estimate_vod__c == afterExpense.Expense_Estimate_vod__c && afterExpense.Expense_Estimate_vod__c != null) {
                estimatesToRollup.add(afterExpense.Expense_Estimate_vod__c);
            } else {
                if(beforeExpense.Expense_Estimate_vod__c != null) {
                    estimatesToRollup.add(beforeExpense.Expense_Estimate_vod__c);
                }
                if(afterExpense.Expense_Estimate_vod__c != null) {
                    estimatesToRollup.add(afterExpense.Expense_Estimate_vod__c);
                }
            }

            boolean mealBefore = false;
            boolean mealAfter = false;

            Expense_Type_vod__c afterExpenseType;
            Expense_Type_vod__c beforeExpenseType;

            if(afterExpense.Expense_Type_vod__c != null) {
                afterExpenseType = typeMap.get(afterExpense.Expense_Type_vod__c);
                if(afterExpenseType != null) {
                    mealAfter = afterExpenseType.Meal_Expense_vod__c;
                }
            }

            if(beforeExpense.Expense_Type_vod__c != null) {
                beforeExpenseType = typeMap.get(beforeExpense.Expense_Type_vod__c);
                if(beforeExpenseType != null) {
                    mealBefore = beforeExpenseType.Meal_Expense_vod__c;
                }
            }

            if((mealBefore || mealAfter || (multiCurrency && beforeExpense.get('CurrencyIsoCode') != afterExpense.get('CurrencyIsoCode'))) && afterExpense.Event_vod__c != null) {
                eventCountsToRollup.add(afterExpense.Event_vod__c);
            }
        }


    } else if (Trigger.isDelete) {
        Map<Id, Expense_Attribution_vod__c> attrMap = new Map<Id, Expense_Attribution_vod__c>([SELECT Incurred_Expense_Speaker_vod__c, Incurred_Expense_Speaker_vod__r.Speaker_vod__c,
                                                                                               		  Incurred_Expense_Account_vod__c, Incurred_Expense_Attendee_vod__r.Account_vod__c
                                                                                               FROM Expense_Attribution_vod__c
                                                                                               WHERE Expense_Line_vod__r.Expense_Header_vod__r.Event_vod__c IN :eventIds
                                                                                               AND Expense_Line_vod__r.Expense_Type_vod__r.Included_In_Speaker_Cap_vod__c = true
                                                                                               AND (Incurred_Expense_Speaker_vod__c != null OR Incurred_Expense_Account_vod__c != null OR Incurred_Expense_Attendee_vod__r.Account_vod__c != null)]);
        for (Id eventId : eventMap.keySet()) {
            EM_Event_vod__c event = eventMap.get(eventId);
            if (event.Event_vod__r != null) {
                for (EM_Event_Budget_vod__c eventBudget : event.Event_vod__r) {
                    eventBudgetMap.put(eventBudget.Id, eventBudget);
                }
            }
            if (event.Expense_Estimate_vod__r != null) {
                for (EM_Expense_Estimate_vod__c estimate : event.Expense_Estimate_vod__r) {
                    estimateMap.put(estimate.Id, estimate);
                }
            }
            if (event.Expense_Header_vod__r != null) {
                for (Expense_Header_vod__c header : event.Expense_Header_vod__r) {
                    headerMap.put(header.Id, header);
                }
            }
        }

        Set<Id> speakerIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for (Id headerId : headerMap.keySet()) {
            Expense_Header_vod__c header = headerMap.get(headerId);
            if (header.Incurred_Expense_Speaker_vod__r.Speaker_vod__c != null) {
                speakerIds.add(header.Incurred_Expense_Speaker_vod__r.Speaker_vod__c);
            } else {
                Id accountId = header.Incurred_Expense_Account_vod__c != null ? header.Incurred_Expense_Account_vod__c : header.Incurred_Expense_Attendee_vod__r.Account_vod__c;
                if(accountId != null) {
                    accountIds.add(accountId);
                }
            }
        }

        for(Id attrId: attrMap.keySet()) {
            Expense_Attribution_vod__c attr = attrMap.get(attrId);
            if(attr.Incurred_Expense_Speaker_vod__c != null) {
                speakerIds.add(attr.Incurred_Expense_Speaker_vod__r.Speaker_vod__c);
            } else if(attr.Incurred_Expense_Account_vod__c != null) {
            	accountIds.add(attr.Incurred_Expense_Account_vod__c);
            } else if (attr.Incurred_Expense_Attendee_vod__r.Account_vod__c != null) {
                accountIds.add(attr.Incurred_Expense_Attendee_vod__r.Account_vod__c);
            }
        }

        Map<Id, EM_Speaker_vod__c> speakerMap = new Map<Id, EM_Speaker_vod__c>([SELECT Id, Year_to_Date_Spend_vod__c, Account_vod__c FROM EM_Speaker_vod__c WHERE Id IN : speakerIds OR Account_vod__c IN : accountIds]);
        for (Id speakerId : speakerMap.keySet()) {
            speakersToRollup.add(speakerId);
        }

        Map<Id, Decimal> eventToAggregateCost = VOD_EVENT_UTILS.getAggregateCosts(eventIds);

        for(Expense_Line_vod__c expense: Trigger.old) {
            Decimal committed = expense.Committed_vod__c == null ? 0: expense.Committed_vod__c;
            Decimal actual = expense.Actual_vod__c == null ? 0: expense.Actual_vod__c;

            if(expense.Event_vod__c != null) {
                eventExpensesToRollup.add(expense.Event_vod__c);
                eventCountsToRollup.add(expense.Event_vod__c);
            }
            if(expense.Event_Budget_vod__c != null) {
                eventBudgetsToRollup.add(expense.Event_Budget_vod__c);
            }
            if(expense.Expense_Estimate_vod__c != null) {
                estimatesToRollup.add(expense.Expense_Estimate_vod__c);
            }
        }
    }



    if (!estimatesToRollup.isEmpty()) {
        VOD_EXPENSE_LINE_TRIG.calculateRollUptoExpenseEstimate(estimatesToRollup);
    }

    if (!eventBudgetsToRollup.isEmpty()) {
        VOD_EXPENSE_LINE_TRIG.calculateEventBudgets(eventBudgetsToRollup);
    }

    if(!eventExpensesToRollup.isEmpty()) {
    	VOD_EXPENSE_LINE_TRIG.calculateRollUptoEvent(eventExpensesToRollup);
    }

    if(!eventCountsToRollup.isEmpty()) {
        List<EM_Event_vod__c> eventsToUpdate = new List<EM_Event_vod__c>();
        eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);
        update eventsToUpdate;
    }
    
    if (!speakersToRollup.isEmpty()) {
        SpeakerYTDCalculator.calculate(speakersToRollup);
    }    
}