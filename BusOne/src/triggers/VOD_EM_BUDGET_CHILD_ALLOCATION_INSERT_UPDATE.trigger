trigger VOD_EM_BUDGET_CHILD_ALLOCATION_INSERT_UPDATE on EM_Budget_vod__c (after insert, after update) {
	Map<Id, EM_Budget_vod__c> oldBudgets = new Map<Id, EM_Budget_vod__c>();
    if(trigger.old != null) {
        oldBudgets = trigger.oldMap;
    }

    Map<Id, EM_Budget_vod__c> updateableParentBudgetMap = new Map<Id, EM_Budget_vod__c>();

    Set<Id> parentBudgetIds = new Set<Id>();

    for(EM_Budget_vod__c budget: trigger.new) {
        if(budget.Parent_Budget_vod__c != null) {
            parentBudgetIds.add(budget.Parent_Budget_vod__c);
        }
    }

    boolean multiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

    Map<Id, EM_Budget_vod__c> parentBudgetMap = new Map<Id, EM_Budget_vod__c>();

    if(parentBudgetIds.size() > 0) {
        if(multiCurrency) {
            List<EM_Budget_vod__c> budgetList = Database.query('SELECT Child_Budget_Allocation_vod__c, Id, CurrencyIsoCode, Parent_Budget_vod__r.CurrencyIsoCode FROM EM_Budget_vod__c WHERE Id IN ' + MultiCurrencyUtil.toCommaSeperated(parentBudgetIds));
            parentBudgetMap = new Map<Id, EM_Budget_vod__c>(budgetList);
        } else {
            parentBudgetMap = new Map<Id, EM_Budget_vod__c>([SELECT Id, Child_Budget_Allocation_vod__c FROM EM_Budget_vod__c WHERE Id =: parentBudgetIds]);
        }
    }

    for(EM_Budget_vod__c budget: trigger.new) {
        Em_Budget_vod__c oldBudget = oldBudgets.get(budget.id);
        if(oldBudget == null) {
            EM_Budget_vod__c parentBudget = parentBudgetMap.get(budget.Parent_Budget_vod__c);

            if(parentBudget != null && budget.Total_Budget_vod__c != null) {
                Decimal totalBudget;
                if(multiCurrency) {
                    String fromIsoCode = (String)budget.get('CurrencyIsoCode');
                    String toIsoCode = (String)parentBudget.get('CurrencyIsoCode');
                    totalBudget = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, budget.Total_Budget_vod__c);
                } else {
                    totalBudget = budget.Total_Budget_vod__c;
                }

                if(parentBudget.Child_Budget_allocation_vod__c == null) {
                    parentBudget.Child_Budget_Allocation_vod__c = totalBudget;
                } else {
                    parentBudget.Child_Budget_Allocation_vod__c += totalBudget;
                }
                updateableParentBudgetMap.put(parentBudget.Id, parentBudget);
                //parentBudgetList.add(parentBudget);
            }
        } else if (oldBudget.Total_Budget_vod__c != budget.Total_Budget_vod__c) {
            Decimal oldBudgetValue;
            Decimal budgetValue;
            EM_Budget_vod__c parentBudget = parentBudgetMap.get(budget.Parent_Budget_vod__c);
			if(parentBudget != null) {
                if (oldBudget.Total_Budget_vod__c == null) {
                    oldBudgetValue = 0;
                } else if (multiCurrency) {
                    String fromIsoCode = (String)oldBudget.get('CurrencyIsoCode');
                    String toIsoCode = (String)parentBudget.get('CurrencyIsoCode');
                    oldBudgetValue = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, oldBudget.Total_Budget_vod__c);
                } else {
                    oldBudgetValue = oldBudget.Total_Budget_vod__c;
                }

                if (budget.Total_Budget_vod__c == null) {
                    budgetValue = 0;
                } else if (multiCurrency) {
                    String fromIsoCode = (String)budget.get('CurrencyIsoCode');
                    String toIsoCode = (String)parentBudget.get('CurrencyIsoCode');
                    budgetValue = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, budget.Total_Budget_vod__c);
                } else {
                    budgetValue = budget.Total_Budget_vod__c;
                }
                Decimal difference = budgetValue - oldBudgetValue;

                if(parentBudget.Child_Budget_allocation_vod__c == null) {
                    parentBudget.Child_Budget_Allocation_vod__c = difference;
                } else {
                    parentBudget.Child_Budget_Allocation_vod__c += difference;
                }
                updateableParentBudgetMap.put(parentBudget.Id, parentBudget);
            }
        }
    }

    if(!updateableParentBudgetMap.isEmpty()) {
        update updateableParentBudgetMap.values();
    }
}