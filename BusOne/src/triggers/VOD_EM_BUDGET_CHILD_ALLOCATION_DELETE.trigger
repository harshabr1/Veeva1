trigger VOD_EM_BUDGET_CHILD_ALLOCATION_DELETE on EM_Budget_vod__c (after delete) {
	List<EM_Budget_vod__c> parentBudgetList = new List<EM_Budget_vod__c>();

    boolean multiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

    Set<Id> parentBudgetIds = new Set<Id>();

    for(EM_Budget_vod__c budget: trigger.old) {
        if(budget.Parent_Budget_vod__c != null) {
        	parentBudgetIds.add(budget.Parent_Budget_vod__c);
        }
    }

    Map<Id, EM_Budget_vod__c> parentBudgetMap = new Map<Id, EM_Budget_vod__c>() ;

    if(!parentBudgetIds.isEmpty()) {
    	if(multiCurrency) {
            List<EM_Budget_vod__c> budgetList = Database.query('SELECT Child_Budget_Allocation_vod__c, Id, CurrencyIsoCode, Parent_Budget_vod__r.CurrencyIsoCode FROM EM_Budget_vod__c WHERE Id IN ' + MultiCurrencyUtil.toCommaSeperated(parentBudgetIds));
            parentBudgetMap = new Map<Id, EM_Budget_vod__c>(budgetList);
        } else {
            parentBudgetMap = new Map<Id, EM_Budget_vod__c>([SELECT Id, Child_Budget_Allocation_vod__c FROM EM_Budget_vod__c WHERE Id =: parentBudgetIds]);
        }
    }

    for(EM_Budget_vod__c budget: trigger.old) {
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

             if(parentBudget.Child_Budget_allocation_vod__c != null) {
                 parentBudget.Child_Budget_Allocation_vod__c -= totalBudget;
                 parentBudgetList.add(parentbudget);
             }
             
        }
    }
    
    if(parentBudgetList.size() > 0) {
        update parentBudgetList;
    }
}