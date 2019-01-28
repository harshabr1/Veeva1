trigger Call_Objective_after_upsert_before_delete on Call_Objective_vod__c (after insert, after update, before delete) {

    if ((!VEEVA_CALL_OBJECTIVE_TRIG.invoked) || VEEVA_CALL_OBJECTIVE_TRIG.calculateCOProgressOnly) {

       // calculateCOProgressOnly flag is set in VOD_CALL_OBJECTIVE_BEFORE_UPDATE for only calculate the Call Objectives progress in Account Tactic
       
       // Start count percentage of Call Objectives progress

       Set<Id> delIds = new Set<Id>();
       Call_Objective_vod__c [] cRow = null;
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

       List<String> parentATids = new List <String> ();
       for (Integer i = 0; i < cRow.size (); i++ ) {
           parentATids.add (cRow[i].Account_Tactic_vod__c);          
       }
       
       System.debug('Call_Objective_after_upsert_before_delete parentATids: ' + parentATids);
       Map<Id, Account_tactic_vod__c> acctTactics = new Map<Id, Account_tactic_vod__c>(
           [select Id, Progress_Type_vod__c, Completed_Call_Objectives_vod__c, Total_Call_Objectives_vod__c
            ,Call_Objective_Progress_vod__c, Status_vod__c from Account_Tactic_vod__c where Id in :parentATids and (Progress_Type_vod__c = 'Call_Objective_vod' or Progress_Type_vod__c = null)]);
       Map<Id, List<Call_Objective_vod__c>> atCOMappings = new Map<Id, List<Call_Objective_vod__c>>();

       System.debug('Call_Objective_after_upsert_before_delete: acctTactics.size()=' + acctTactics.size());
       if(acctTactics.size() > 0)
       {
           try
           {
               System.debug('Call_Objective_after_upsert_before_delete: before cycle Select Call_Objective_vod__c');
               for (Call_Objective_vod__c cObj : [select Id, Account_Tactic_vod__c,Completed_Flag_vod__c
                                                         from Call_Objective_vod__c
                                                         where Account_Tactic_vod__c in :acctTactics.keySet()])
               {
                   System.debug('Call_Objective_after_upsert_before_delete: Call Objective for percent calculation in cycle: ' + cObj);
                   if(atCOMappings.containsKey(cObj.Account_Tactic_vod__c) == false)
                       atCOMappings.put(cObj.Account_Tactic_vod__c, new List<Call_objective_vod__c>());
                    
                   atCOMappings.get(cObj.Account_Tactic_vod__c).Add(cobj);
               }                                                
                
               for(Account_Tactic_vod__c at : acctTactics.values())
               {
                    if(atCOMappings.containsKey(at.Id))
                    {
                        Integer completedCO = 0;
                        Integer allCO = 0;
                        for(Call_Objective_vod__c co : atCOMappings.get(at.Id)) 
                        {
                            if (delIds.contains(co.Id))
                            {
                                continue;
                            }
                            if(co.Completed_Flag_vod__c == true)
                            {
                                completedCO++;
                            }
                            allCO++;
                        }  
                        at.Completed_Call_Objectives_vod__c = completedCO ;
                        at.Total_Call_Objectives_vod__c = allCO;
                        if(at.Total_Call_Objectives_vod__c > 0)
                        {
                            at.Call_Objective_Progress_vod__c = (at.Completed_Call_Objectives_vod__c / at.Total_Call_Objectives_vod__c) * 100;
                            if(at.Call_Objective_Progress_vod__c == 100)
                                at.Status_vod__c = 'Completed_vod';
                            else
                                at.Status_vod__c = 'Pending_vod';
                        }
                    }
                }
                System.debug('Call_Objective_after_upsert_before_delete: before update(acctTactics.values())');
                update(acctTactics.values());
             }
             catch( Exception e ) {
                 System.debug('Call_Objective_after_upsert_before_delete: exception');  
           }
        }
    }

    if (VEEVA_CALL_OBJECTIVE_TRIG.invoked)
    {
        //It is coming from Business_Event_Target trigger
        System.debug('Call_Objective_after_upsert_before_delete: VEEVA_CALL_OBJECTIVE_TRIG.invoked set, exit');
        return;
    }

    VEEVA_CALL_OBJECTIVE_TRIG.invoked = true;

    Set<Call_Objective_vod__c> callObjectiveToUpdate = new Set<Call_Objective_vod__c>();
    
    Map<Id, RecordType> recTypes = new Map<Id, RecordType>(
        [select Id, Name
         from RecordType
         where SobjectType in ('Business_Event_Target_vod__c', 'Call_Objective_vod__c')
         and Name in ('EPPV', 'PI')
         and IsActive=true]);
    
    List<Id> betIds = new List<Id>();
    Set<Id> deletedIds = new Set<Id>();
    boolean[] skip = new boolean[Trigger.size];

    // The case of prerequisite 
    if(!Trigger.isInsert) {
        List<Id> prereqIds = new List<Id>();
        for (Integer idx = 0; idx < Trigger.size; idx++) {
            prereqIds.add(Trigger.old[idx].Id);
        }
        
        List<Call_Objective_vod__c> children = new List<Call_Objective_vod__c>();
        if(prereqIds.size() > 0) {
            children = [SELECT Id, Prerequisite_vod__c FROM Call_Objective_vod__c WHERE Prerequisite_vod__c IN :prereqIds];
        }

        if(children != null && children.size() > 0 ) {
            for(Integer cildIdx = 0; cildIdx < children.size(); cildIdx++) {
                children[cildIdx].Non_Executable_vod__c = true;
            }
            System.debug('Call_Objective_after_upsert_before_delete: callObjectiveToUpdate.addAll(children)');
            callObjectiveToUpdate.addAll(children);
        }
    }

    for (Integer idx = 0; idx < Trigger.size; idx++)
    {
        skip[idx] = false;
        if (Trigger.isDelete)
        {
            if (!recTypes.containsKey(Trigger.old[idx].RecordTypeId))
            {
                skip[idx] = true;
                continue;
            } 
            deletedIds.add(Trigger.old[idx].Id);
        }
        else if (!recTypes.containsKey(Trigger.new[idx].RecordTypeId))
        {
            skip[idx] = true;
            continue;
        }
        else
        {
            if (Trigger.new[idx].Business_Event_Target_vod__c == null ||
                Trigger.new[idx].Business_Event_vod__c == null ||
                Trigger.new[idx].Account_vod__c == null ||
                Trigger.new[idx].Date_vod__c == null)
            {
                Trigger.new[idx].addError((Trigger.new[idx].Name + ' [Business_Event_vod__c, Business_Event_Target_vod__c, Account_vod__c and Date_vod__c] ' + VOD_GET_ERROR_MSG.getErrorMsg('REQUIRED', 'Common')), false);
                return;
            }
        }
        betIds.add(Trigger.isDelete ? Trigger.old[idx].Business_Event_Target_vod__c : Trigger.new[idx].Business_Event_Target_vod__c);
    }
    
    if(callObjectiveToUpdate.size() > 0) {
      System.debug('Call_Objective_after_upsert_before_delete: update(callObjectiveToUpdateList)');
      List<Call_Objective_vod__c> callObjectiveToUpdateList = new List<Call_Objective_vod__c>(callObjectiveToUpdate);
      update(callObjectiveToUpdateList);
    }

    Map<Id, Business_Event_Target_vod__c> bets = new Map<Id, Business_Event_Target_vod__c>(
        [select Id, RecordTypeId from Business_Event_Target_vod__c where Id in :betIds and RecordTypeId in :recTypes.keySet()]);
       
    for (Integer idx = 0; idx < Trigger.size; idx++)
    {
        if (skip[idx])
        {
            continue;
        }
        Id betId = Trigger.isDelete ? Trigger.old[idx].Business_Event_Target_vod__c : Trigger.new[idx].Business_Event_Target_vod__c;

        if (betId != null)
        {           
            Business_Event_Target_vod__c bet = bets.get(betId);
            if (!Trigger.isDelete && bet == null)
            {
                Trigger.new[idx].addError(('Call_Objective ' + Trigger.new[idx].Name + ' ' + VOD_GET_ERROR_MSG.getErrorMsg('Invalid', 'TABLET')  + ' Business_Event_Target_vod__c = ' + betId), false);
                return;
            }

            if (!Trigger.isDelete)
            {            
                RecordType coRecType = recTypes.get(Trigger.new[idx].RecordTypeId);
                RecordType betRecType = recTypes.get(bet.RecordTypeId);
                
                if (coRecType == null || betRecType == null)
                {
                    Trigger.new[idx].addError('RecordType must not be null', false);
                    return;
                }
                else if (!coRecType.Name.equals(betRecType.Name))
                {
                    Trigger.new[idx].addError('Call Objective must be the same RecordType as Business_Event_Target_vod__c', false);
                    return;
                }
            }
            
            bet.Next_Visit_Date_vod__c = null;
            bet.Remaining_Calls_vod__c = 0;                    
            
            boolean updBET = Trigger.isUpdate && Trigger.new[idx].Completed_Flag_vod__c && !Trigger.old[idx].Completed_Flag_vod__c;       
            
            if (Trigger.isDelete)
            {
                if (Trigger.old[idx].Pre_Explain_Flag_vod__c)
                {
                    System.Debug('Call_Objective_after_upsert_before_delete: trying to reset pre_explain bet ' + bet.Id);
                    bet.Pre_Explain_Date_vod__c = null;
                }
                bets.put(betId, bet);                
            }
            else if (Trigger.new[idx].Pre_Explain_Flag_vod__c)
            {
                // this is Pre_Explain Call Objective
                if (updBET  || (Trigger.isInsert && Trigger.new[idx].Completed_Flag_vod__c))
                {
                    // update BET if update status to completed from incompleted, Or insert a new completed            
                    bet.Pre_Explain_Date_vod__c = Trigger.new[idx].Date_vod__c.date();
                    bets.put(Trigger.new[idx].Business_Event_Target_vod__c, bet);
                }
            }
            else if (updBET || (Trigger.isInsert && !Trigger.new[idx].Completed_Flag_vod__c))
            {
                // update count if update status to completed from incompleted, Or insert a new incompleted            
                if (!bets.containsKey(Trigger.new[idx].Business_Event_Target_vod__c))
                {                
                    bets.put(Trigger.new[idx].Business_Event_Target_vod__c, bet);                 
                }
            }
        }
    }
    
    // Query Call_Objective_vod to set next visit date and number of remaining calls for the corresponding Business_Event_Target_vod
    for (List<Call_Objective_vod__c> cObjs : [select Id, Business_Event_Target_vod__c,Date_vod__c
                                              from Call_Objective_vod__c
                                              where Completed_Flag_vod__c = false and
                                                    RecordTypeId in :recTypes.keySet() and
                                                    Business_Event_Target_vod__c in :bets.keySet()])
     {         
         for (Call_Objective_vod__c cObj : cObjs)
         {         
             if (deletedIds.contains(cObj.Id) || cObj.Business_Event_Target_vod__c == null)
             {
                 continue;
             }
             Business_Event_Target_vod__c bet = bets.get(cObj.Business_Event_Target_vod__c);
             if (bet != null)
             {
                 if (bet.Next_Visit_Date_vod__c == null || bet.Next_Visit_Date_vod__c > cObj.Date_vod__c.date())
                 {
                     bet.Next_Visit_Date_vod__c = cObj.Date_vod__c.date();
                 }
                 bet.Remaining_Calls_vod__c++;
             }
         }
     }
     
     if (bets.size() > 0)
     {
         // update Business Event Target with the new remaining count and next visit date
         // and skip all triggers
         VEEVA_BUSINESS_EVENT_TARGET_TRIG.invoked = true;         
         update(bets.values());                                                    
     }
 }