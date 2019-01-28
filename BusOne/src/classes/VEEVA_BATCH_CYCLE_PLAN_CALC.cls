global class VEEVA_BATCH_CYCLE_PLAN_CALC implements Database.Batchable<sObject> { 
	private final String initialState;
	String query;
	global VEEVA_BATCH_CYCLE_PLAN_CALC() {
	
	}
	global Database.QueryLocator start(Database.BatchableContext BC) {
		// This is the base query that dirves the chunking.
		// We are grabbing all the plans are currently active and
		// have a start or end date that is currently in need of calculation.
		query = 'SELECT Id,' +
		        '       Cycle_Plan_Target_vod__r.Id,' +
		        '       Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Start_Date_vod__c, ' +
		        '       Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.End_Date_vod__c,' +
		        '       Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Territory_vod__c,' +
		        '       Cycle_Plan_Target_vod__r.Cycle_Plan_Account_vod__c,' + 
		        '       Product_vod__c' + 
		        ' FROM Cycle_Plan_Detail_vod__c ' +
		        ' WHERE Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Start_Date_vod__c <= LAST_N_DAYS:1  '+
		        ' AND  Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.End_Date_vod__c >= LAST_N_DAYS:1  ' +  
		        ' AND  Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Active_vod__c = true ' ;  
		
		return Database.getQueryLocator(query);
	}
	global void execute(Database.BatchableContext BC, List<sObject> batch) {
		// Loop through all the rows in the batch of Cycle Plan Details
		List <Cycle_Plan_Detail_vod__c> planDetailsToUpdate = new List <Cycle_Plan_Detail_vod__c> ();
		Set<String> setPlansInSet = new Set<String> ();	
		for (sObject obj : batch) {
			Cycle_Plan_Detail_vod__c cycle = (Cycle_Plan_Detail_vod__c)obj;
			
			// Move some of the values from the object into easier to easier to read variables. 
			String account = cycle.Cycle_Plan_Target_vod__r.Cycle_Plan_Account_vod__c;
			String product = cycle.Product_vod__c;
			String territory = cycle.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Territory_vod__c;
			Date dateStart = cycle.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Start_Date_vod__c;
			Date dateEnd = cycle.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.End_Date_vod__c;
			
			// Loop through the Call2_Detail_vod__c results for what we need here.
			
			System.debug (account + '<->' + product + '<->' + territory + '<->'+dateStart +'<->' +dateEnd );
			Set <Id> haveCalls = new Set<Id> ();
			
			Integer countMyTerr = 0;
			Integer countAll = 0;
			
			Integer counterAllSched = 0;
			Integer counterMyTerrSched = 0;
			
			for (Call2_Detail_vod__c call_det : 
			       [Select Call2_vod__r.Account_vod__c,
			               Call2_vod__r.Status_vod__c,
			               Call2_vod__r.Call_Date_vod__c,
			               Call2_vod__r.Territory_vod__c, 
			               Product_vod__c, 
			               Call2_vod__c
			        FROM Call2_Detail_vod__c 
			        WHERE Call2_vod__r.Account_vod__c = :account
					AND Product_vod__c  = :product
					and Call2_vod__r.Call_Date_vod__c >= :dateStart
					and Call2_vod__r.Call_Date_vod__c <= :dateEnd]) {
					
					// if the lookup is null,  no work to do here.  
				    // Probably shouldnt happen but better safe 
				if (call_det.Call2_vod__r == null)
					continue;	
						
				if(call_det.Call2_vod__r.Territory_vod__c == territory) {
					if (call_det.Call2_vod__r.Status_vod__c == 'Planned_vod' || 
					    (call_det.Call2_vod__r.Status_vod__c == 'Saved_vod' && 
					     call_det.Call2_vod__r.Call_Date_vod__c > System.now ())) {
						counterMyTerrSched++;
					} else {
						countMyTerr++;
					}
				} 
				
				if (call_det.Call2_vod__r.Status_vod__c == 'Planned_vod' || 
					    (call_det.Call2_vod__r.Status_vod__c == 'Saved_vod' && 
					     call_det.Call2_vod__r.Call_Date_vod__c > System.now ())) {
					counterAllSched++;		
				} else {
					countAll++;
				}
			}
			
			Cycle_Plan_Detail_vod__c PlanDetail = 
		 		   new Cycle_Plan_Detail_vod__c(ID = cycle.Id, 
		 		                                Actual_Details_vod__c = countMyTerr,
		 		                                Scheduled_Details_vod__c = counterMyTerrSched,
		 		                                Total_Scheduled_Details_vod__c = counterAllSched, 
		 		                                Total_Actual_Details_vod__c =  countAll);
		 		                                
			if (setPlansInSet.contains(cycle.Id) == false) {		 		                                
		 			planDetailsToUpdate.add (PlanDetail);
		 			setPlansInSet.add(cycle.Id);
			}
		}
		
		System.debug (planDetailsToUpdate);
		if (planDetailsToUpdate.size () > 0)
			update planDetailsToUpdate; 
	}
	global void finish(Database.BatchableContext BC) {
		// Access initialState here
	}
}