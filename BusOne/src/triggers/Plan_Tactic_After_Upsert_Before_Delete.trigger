trigger Plan_Tactic_After_Upsert_Before_Delete on Plan_Tactic_vod__c (after insert, after update, before delete) {
    Plan_Tactic_vod__c [] cRow = null;
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
    List <String> parentAPids = new List <String> ();
    for (Integer i = 0; i < cRow.size (); i++ ) {
        parentAPids.add (cRow[i].Account_Plan_vod__c);          
    }

    Map<Id, Account_Plan_vod__c> accountPlans = new Map<Id, Account_Plan_vod__c>(
        [select Id,Completed_Plan_Tactics_vod__c, Total_Plan_Tactics_vod__c
         ,Plan_Tactic_Progress_vod__c from Account_Plan_vod__c where Id in :parentAPids]);
    Map<Id, List<Plan_Tactic_vod__c>> apPTMappings = new Map<Id, List<Plan_Tactic_vod__c>>();
 
    if(accountPlans.size() > 0)
    {
        try
        {
            for (Plan_Tactic_vod__c cObj : [select Id, Account_Plan_vod__c,Status_vod__c 
                                                      from Plan_Tactic_vod__c
                                                      where Account_Plan_vod__c in :accountPlans.keySet()])
            {
                 if(apPTMappings.containsKey(cObj.Account_Plan_vod__c) == false)
                     apPTMappings.put(cObj.Account_Plan_vod__c, new List<Plan_Tactic_vod__c>());
                 
                 apPTMappings.get(cObj.Account_Plan_vod__c).Add(cobj);
            }                                                
             
             for(Account_Plan_vod__c ap : accountPlans.values())
             {
                 if(apPTMappings.containsKey(ap.Id))
                 {
                     Integer completedPT = 0;
                     Integer allPT = 0;
                     for(Plan_Tactic_vod__c pt: apPTMappings.get(ap.Id)) 
                     {
                         if (delIds.contains(pt.Id))
                         {
                             continue;
                         }
                         if(pt.Status_vod__c == 'Completed_vod')
                         {
                             completedPT ++;
                         }
                         allPT ++;
                     }  
                     ap.Completed_Plan_Tactics_vod__c = completedPT;
                     ap.Total_Plan_Tactics_vod__c = allPT;
                     if(ap.Total_Plan_Tactics_vod__c > 0)
                     {
                         ap.Plan_Tactic_Progress_vod__c = (ap.Completed_Plan_Tactics_vod__c / ap.Total_Plan_Tactics_vod__c) * 100;
                     }
                 }
             }
             update(accountPlans.values());
          }
          catch( Exception e ) {
              System.debug('exception');  
        }
     } 
}