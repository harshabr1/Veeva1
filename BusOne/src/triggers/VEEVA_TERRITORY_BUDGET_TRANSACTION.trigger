trigger VEEVA_TERRITORY_BUDGET_TRANSACTION on Territory_Budget_Transaction_vod__c (after delete, after insert, after undelete, after update) {
    Set<String> territoryBudgetIds = new Set<String>();
    if (Trigger.new != null) {
        for (Territory_Budget_Transaction_vod__c tbt : Trigger.new) {
            territoryBudgetIds.add(tbt.Territory_Budget_vod__c);
        }
    }
    if (Trigger.old != null) {
        for (Territory_Budget_Transaction_vod__c tbt : Trigger.old) {
            territoryBudgetIds.add(tbt.Territory_Budget_vod__c);
        }
    }
    if (territoryBudgetIds.size() > 0) {
        Map<Id, Territory_Budget_vod__c> territoryBudgets = new Map<Id, Territory_Budget_vod__c>([SELECT Id, Start_Value_vod__c, Start_Quantity_vod__c FROM Territory_Budget_vod__c WHERE Id IN :territoryBudgetIds]);
        List<sObject> budgetCalculations = [SELECT Territory_Budget_vod__c, MAX(Transaction_Date_vod__c)maxTransactionDate, SUM(Value_vod__c)sumValue, SUM(Quantity_vod__c)sumQuantity FROM Territory_Budget_Transaction_vod__c WHERE Territory_Budget_vod__c IN :territoryBudgetIds GROUP BY Territory_Budget_vod__c];
        if (budgetCalculations.size() > 0) {
            for (sObject budgetCalculation : budgetCalculations) {
                Id budgetId = (Id)budgetCalculation.get('Territory_Budget_vod__c');
                Territory_Budget_vod__c territoryBudget = territoryBudgets.get(budgetId);
                territoryBudget.Last_Transaction_vod__c = (Date)budgetCalculation.get('maxTransactionDate');
                
                territoryBudget.Current_Value_vod__c = (Double)budgetCalculation.get('sumValue');
                if (territoryBudget.Start_Value_vod__c != null)
                    territoryBudget.Current_Value_vod__c += territoryBudget.Start_Value_vod__c;
                
                territoryBudget.Current_Quantity_vod__c = (Double)budgetCalculation.get('sumQuantity');
                if (territoryBudget.Start_Quantity_vod__c != null)
                    territoryBudget.Current_Quantity_vod__c += territoryBudget.Start_Quantity_vod__c;
            }
        } else {
            for (Territory_Budget_vod__c territoryBudget : territoryBudgets.values()) {
                territoryBudget.Last_Transaction_vod__c = null;
                territoryBudget.Current_Value_vod__c = null;
                territoryBudget.Current_Quantity_vod__c = null;
            }
        }
        update territoryBudgets.values();
    }
}