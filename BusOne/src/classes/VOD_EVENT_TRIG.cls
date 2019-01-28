public class VOD_EVENT_TRIG {
    public static void rollUptoBudget(Decimal committed, Decimal estimated, Id budgetId) {
        if(budgetId != null && (committed != 0 || estimated != 0)) {
            EM_Budget_vod__c budget = [Select Actual_Expenses_vod__c,
                                              Committed_Expenses_vod__c,
                                              Estimated_Expenses_vod__c,
                                              Parent_Budget_vod__c
                                              FROM EM_Budget_vod__c
                                              WHERE Id = :budgetId]; 
            if(budget != null) {
                if(budget.Committed_Expenses_vod__c == null) {
                    budget.Committed_Expenses_vod__c = committed;
                } else {
                	budget.Committed_Expenses_vod__c += committed;    
                }
                
                if(budget.Estimated_Expenses_vod__c == null) {
                    budget.Estimated_Expenses_vod__c = estimated;
                } else {
                	budget.Estimated_Expenses_vod__c += estimated;    
                }
				update budget;
                if(budget.Parent_Budget_vod__c != null) {
                	rolluptoBudget(committed, estimated, budget.Parent_Budget_vod__c);    
                }                                                
            }          
        }
    }
}