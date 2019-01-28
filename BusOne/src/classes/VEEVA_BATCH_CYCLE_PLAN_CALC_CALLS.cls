global class VEEVA_BATCH_CYCLE_PLAN_CALC_CALLS implements Database.Batchable<sObject> {
    private final String initialState;
    String query;
    global VEEVA_BATCH_CYCLE_PLAN_CALC_CALLS() {
    
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // This is the base query that dirves the chunking.
        // We are grabbing all the plans are currently active and
        // have a start or end date that is currently in need of calculation.
        
        query = 'SELECT Id,' +
                '       Cycle_Plan_vod__r.Start_Date_vod__c, ' +
                '       Cycle_Plan_vod__r.End_Date_vod__c,' +
                '       Cycle_Plan_vod__r.Territory_vod__c,' +
                '       Cycle_Plan_Account_vod__c ' + 
                ' FROM  Cycle_Plan_Target_vod__c ' +
                ' WHERE Cycle_Plan_vod__r.Start_Date_vod__c <= LAST_N_DAYS:1  '+
                ' AND   Cycle_Plan_vod__r.End_Date_vod__c >= LAST_N_DAYS:1  ' +  
                ' AND   Cycle_Plan_vod__r.Active_vod__c = true ' ;  
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
        // Loop through all the rows in the batch of Cycle Plan Details
        List <Cycle_Plan_Target_vod__c> planTargetsToUpdate = new List <Cycle_Plan_Target_vod__c> ();
        Set<String> setPlansInSet = new Set<String> ();	  
        for (sObject obj : batch) {
            Cycle_Plan_Target_vod__c cycle = (Cycle_Plan_Target_vod__c)obj;
            if (cycle.Cycle_Plan_Account_vod__c == null)
            	continue;
            // Move some of the values from the object into easier to easier to read variables. 
            String account =   cycle.Cycle_Plan_Account_vod__c;            
            String territory = cycle.Cycle_Plan_vod__r.Territory_vod__c;
            Date dateStart =   cycle.Cycle_Plan_vod__r.Start_Date_vod__c;
            Date dateEnd =     cycle.Cycle_Plan_vod__r.End_Date_vod__c;
            
            // Loop through the Call2_Detail_vod__c results for what we need here.
            
            System.debug ('VEEVADEBUG: Processing : "' + account + '" for territrory = "'
                           + territory +'" Date ="'+ dateStart +'" to "' + dateEnd + '"');            
            
            Set <Id> haveCalls = new Set<Id> ();
            Integer calls = 0; 
            Integer teamCalls = 0;
            
            Integer callsSched = 0;
            Integer teamCallsSched = 0;
            
            for (Call2_vod__c call : 
                   [Select Account_vod__c,
                           Territory_vod__c,
                           Call_Date_vod__c,
                           Status_vod__c
                    FROM Call2_vod__c 
                    WHERE Account_vod__c = :account
                    and Call_Date_vod__c >= :dateStart
                    and Call_Date_vod__c <= :dateEnd
                    ]) {
            
             System.debug (call);        
                	
             if (call.Status_vod__c == 'Planned_vod' || 
                   (call.Status_vod__c == 'Saved_vod' && call.Call_Date_vod__c > System.today())) {
                
                
                  	
             	if (territory == call.Territory_vod__c)
             		callsSched++;
             	
             	teamCallsSched++;
             	
             	System.debug (Call.Id + ' is scheduled. SCHED = ' + callsSched + ' TEAM SCHED = ' +teamCallsSched );
             	
             }   else {
         
             	
                if (territory == call.Territory_vod__c)
                   calls++;
                   
                teamCalls++;
                
                System.debug (Call.Id + ' is scheduled. Calls = ' + calls + ' TEAM Calls = ' +teamCalls );
            }
            
            System.debug ('2- ' + Call.Id + ' is scheduled. SCHED = ' + callsSched + ' TEAM SCHED = ' +teamCallsSched );
            System.debug ('2- ' +Call.Id + ' is scheduled. Calls = ' + calls + ' TEAM Calls = ' +teamCalls );
            
		    }
            Cycle_Plan_Target_vod__c PlanTarget = 
                   new Cycle_Plan_Target_vod__c(ID = cycle.Id, 
                                                Actual_Calls_vod__c = calls,
                                                Total_Actual_Calls_vod__c = teamCalls,
                                                Scheduled_Calls_vod__c = callsSched,
                                                Total_Scheduled_Calls_vod__c = teamCallsSched
                                                );
               if (setPlansInSet.contains(cycle.Id) == false) {
               	   System.debug('3 - ' + PlanTarget);                                 
                	planTargetsToUpdate.add (PlanTarget);
                	setPlansInSet.add(cycle.Id);
               }
                       
            
        }
        
        if (planTargetsToUpdate.size () > 0 ) {
        	System.debug (planTargetsToUpdate);
        	update planTargetsToUpdate;
        } 
    }
    global void finish(Database.BatchableContext BC) {
        // Access initialState here
    }
}