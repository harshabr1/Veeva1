trigger VOD_CALL_OBJECTIVE_AFTER_DELETE on Call_Objective_vod__c (after delete) {
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    if (vsc == null || vsc.Account_Plan_Sharing_vod__c == null || vsc.Account_Plan_Sharing_vod__c.intValue() != 1) {
        return;
    }

     Set<Id> accountTacticIds = new Set<Id> ();
     Set<Id> callObjectiveIds = new Set<Id> ();    
     Map<Id, Call_Objective_vod__c> callObjectiveMap = new Map<Id, Call_Objective_vod__c> (); 
     for (Call_Objective_vod__c callObjective: Trigger.old) {
          accountTacticIds.add(callObjective.Account_Tactic_vod__c);         
          callObjectiveMap.put(callObjective.Account_Tactic_vod__c, callObjective);   
          callObjectiveIds.add(callObjective.Id);   
     }
     
     // get all the account tactic for the call objective
     List<Account_Tactic_vod__c> accountTactics = Database.query('Select Id, Name, Account_Plan_vod__c, Plan_Tactic_vod__c from Account_Tactic_vod__c ' +
                                       'where Id IN : accountTacticIds');
     Set<Id> planTacticIds = new Set<Id> ();
     Map<Id, Account_Tactic_vod__c> accountTacticMap = new Map<Id, Account_Tactic_vod__c> (); 
     Set<Id> accountPlanIds = new Set<Id> ();
     for (Account_Tactic_vod__c accountTactic : accountTactics) {
         planTacticIds.add(accountTactic.Plan_Tactic_vod__c);
         accountPlanIds.add(accountTactic.Account_Plan_vod__c);
         accountTacticMap.put(accountTactic.Plan_Tactic_vod__c, accountTactic);     
     } 
     
     // now query the account team memebr object
     List<Account_Team_Member_vod__c> accountTeamMembers = Database.query('Select Id, Name, Account_Plan_vod__c, Team_Member_vod__c, Role_vod__c, Access_vod__c from Account_Team_Member_vod__c ' +
                                       'where Account_Plan_vod__c in : accountPlanIds');
     // form the map and data that is needed to find the plan tactic share that need to be deleted
     Set<ID> accoutMemberIDs = new Set<ID> ();     
     Map<Id, Account_Team_Member_vod__c> acctTeamMemberMap = new Map<Id, Account_Team_Member_vod__c> (); 
     for (Account_Team_Member_vod__c actTeamMember : accountTeamMembers) {
         system.debug('the value of team member value is ' + actTeamMember.Team_Member_vod__c);          
         accoutMemberIDs.add(actTeamMember.Team_Member_vod__c);         
         acctTeamMemberMap.put(actTeamMember.Account_Plan_vod__c , actTeamMember);  
     }
     
     Set<Id> delplanTacticIDs = new Set<Id> ();
     
     if (VOD_Utils.hasObject('Plan_Tactic_vod__Share')) {
        List<SObject> planTacticShares = Database.query('SELECT Id, ParentId, Parent.Account_Plan_vod__c, Parent.Share_With_vod__c, UserOrGroupId, RowCause FROM Plan_Tactic_vod__Share ' +
                                                     'WHERE  RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Plan_Tactic_vod__c WHERE Id IN : planTacticIds)');
        for (SObject planTacticShare: planTacticShares) {
            Id memberId = (Id) planTacticShare.get('UserOrGroupId');
            Id accountPlanId = (Id) planTacticShare.getSObject('Parent').get('Account_Plan_vod__c');
            String shareWithValues = (String) planTacticShare.getSObject('Parent').get('Share_With_vod__c');     
            Account_Team_Member_vod__c teamMember = acctTeamMemberMap.get((Id) accountPlanId); 
            if (teamMember == null || shareWithValues == null || teamMember.Role_vod__c == null) {
                continue;
            }          
            if (teamMember.Team_Member_vod__c == planTacticShare.get('UserOrGroupId') && shareWithValues.contains(teamMember.Role_vod__c)) {
                delplanTacticIDs.add((Id) planTacticShare.get('ParentId'));
                system.debug(' the object that needs to be delete for Plan Tactic Share' + planTacticShare);                
            }
        }                                              
                                                      
     }
     
     // now query the account tactic share to get the account tactics that need to be
     Set<Id> delAccountTacticIds = new Set<Id> ();
     List<SObject> toDelete = new List<SObject>();
     if (VOD_Utils.hasObject('Account_Tactic_vod__Share')) {
        List<SObject> accountTacticShares = Database.query('SELECT Id, ParentId, Parent.Account_Plan_vod__c, UserOrGroupId, RowCause FROM Account_Tactic_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Account_Tactic_vod__c WHERE Plan_Tactic_vod__c IN : delplanTacticIDs)');
        for (SObject accountTacticShare: accountTacticShares) {
            delAccountTacticIds.add((Id) accountTacticShare.get('ParentId'));           
            system.debug(' the object that needs to be delete for Plan Tactic Share' + accountTacticShare);       
        } 
                                                     
      }
      
      // call objective sharing
      if (VOD_Utils.hasObject('Call_Objective_vod__Share') && accoutMemberIDs.size() > 0) {
          List<SObject> callObjectiveShares = Database.query('SELECT Id, ParentId, Parent.Account_Tactic_vod__c, Parent.Account_Plan_vod__c, UserOrGroupId, RowCause FROM Call_Objective_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Call_Objective_vod__c WHERE Account_Tactic_vod__c IN : delAccountTacticIds)');
          for (SObject callObjectiveShare: callObjectiveShares) {
            system.debug(' the object that needs to be delete for call objective Share' + callObjectiveShare);
            ID callObjId = (ID) callObjectiveShare.get('ParentId');
            if (callObjectiveIds.contains(callObjId)) {
                toDelete.add(callObjectiveShare);  
            }                      
          }                                             
                                                      
     }
     
     // now finally delete
     List<Database.DeleteResult> deleteResults = Database.delete(toDelete, false);
     // before calling the delete
     system.debug(' the objects needs to be deleted ' + toDelete);
     for (Database.DeleteResult result : deleteResults) {
         if (!result.isSuccess()) {
             system.debug('delete error: ' + result.getErrors()[0]);
         }
     }
}