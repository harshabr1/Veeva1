trigger Account_Tactic_After_Upsert_Before_Delete on Account_Tactic_vod__c (after insert, after update, before delete) {
    Account_Tactic_vod__c [] cRow = null;	
    Set<Id> delIds = new Set<Id>();
    if (Trigger.isDelete) 
    {
        cRow = Trigger.old;
        for (Integer idx = 0; idx < Trigger.size; idx++)
        {
           delIds.Add(Trigger.old[idx].Id);
        }
    }
    else
        cRow = Trigger.new;
		
    List <String> parentPTids = new List <String> ();
    for (Integer i = 0; i < cRow.size (); i++ ) {
        parentPTids.add (cRow[i].Plan_Tactic_vod__c);          
    }

    Map<Id, Plan_tactic_vod__c> planTactics = new Map<Id, Plan_tactic_vod__c>(
        [select Id, Completed_Account_Tactics_vod__c, Total_Account_Tactics_vod__c
         ,Account_Tactic_Progress_vod__c, Status_vod__c from Plan_tactic_vod__c where Id in :parentPTids]);
    Map<Id, List<Account_Tactic_vod__c>> ptATMappings = new Map<Id, List<Account_Tactic_vod__c>>();
 
    if(planTactics.size() > 0)
    {
        try
        {
            for (Account_Tactic_vod__c cObj : [select Id, Plan_Tactic_vod__c,Status_vod__c 
                                                      from Account_Tactic_vod__c
                                                      where Plan_Tactic_vod__c in :planTactics.keySet()])
            {
                 if(ptATMappings .containsKey(cObj.Plan_Tactic_vod__c) == false)
                     ptATMappings .put(cObj.Plan_Tactic_vod__c, new List<Account_Tactic_vod__c>());
                 
                 ptATMappings.get(cObj.Plan_Tactic_vod__c).Add(cobj);
             }                                                
             
             for(Plan_Tactic_vod__c pt : planTactics.values())
             {
                 if(ptATMappings.containsKey(pt.Id))
                 {
                     Integer completedAT = 0;
                     Integer allAT = 0;
                     for(Account_Tactic_vod__c at: ptATMappings.get(pt.Id)) 
                     {
						 if (delIds.contains(at.Id))
                         {
                             continue;
                         }
                         if(at.Status_vod__c == 'Completed_vod')
                         {
                             completedAT++;
                         }
                         allAT++;
                     }  
                     pt.Completed_Account_Tactics_vod__c = completedAT;
                     pt.Total_Account_Tactics_vod__c = allAT;
                     if(pt.Total_Account_Tactics_vod__c > 0)
                     {
                         pt.Account_Tactic_Progress_vod__c = (pt.Completed_Account_Tactics_vod__c / pt.Total_Account_Tactics_vod__c) * 100;
                         if(pt.Account_Tactic_Progress_vod__c == 100)
                             pt.Status_vod__c = 'Completed_vod';
                         else
                             pt.Status_vod__c = 'Pending_vod';
                     }
                 }
             }
             update(planTactics.values());
          }
          catch( Exception e ) {
              System.debug('exception');  
        }
     }
 
}