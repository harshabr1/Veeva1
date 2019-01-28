trigger VOD_PLAN_TACTIC_AFTER_DELETE on Plan_Tactic_vod__c (after delete) {
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    if (vsc == null || vsc.Account_Plan_Sharing_vod__c == null || vsc.Account_Plan_Sharing_vod__c.intValue() != 1) {
        return;
    }

     Set<Id> accountPlanIds = new Set<Id> ();
     Map<Id, Plan_Tactic_vod__c> planTacticMap = new Map<Id, Plan_Tactic_vod__c> (); 
     Set<Id> ptIds = new Set<Id> ();
     for (Plan_Tactic_vod__c planTactic: Trigger.old) {
          accountPlanIds.add(planTactic.Account_Plan_vod__c); 
          planTacticMap.put(planTactic.Account_Plan_vod__c, planTactic);      
          ptIds.add(planTactic.Id);
     }
     
     // now query the account team memebr object
     List<Account_Team_Member_vod__c> accountTeamMembers = Database.query('Select Id, Name, Account_Plan_vod__c, Team_Member_vod__c, Role_vod__c, Access_vod__c from Account_Team_Member_vod__c ' +
                                       'where Account_Plan_vod__c in : accountPlanIds');
     // form the map and data that is needed to find the plan tactic share that need to be deleted
     Set<ID> accoutMemberIDs = new Set<ID> ();
     Set<ID> actPlanIds = new Set<ID> ();
     Map<Id, Account_Team_Member_vod__c> acctTeamMemberMap = new Map<Id, Account_Team_Member_vod__c> (); 
     for (Account_Team_Member_vod__c actTeamMember : accountTeamMembers) {
         system.debug('the value of team member value is ' + actTeamMember.Team_Member_vod__c);          
         accoutMemberIDs.add(actTeamMember.Team_Member_vod__c); 
         actPlanIds.add(actTeamMember.Account_Plan_vod__c); 
         acctTeamMemberMap.put(actTeamMember.Account_Plan_vod__c , actTeamMember);  
     }
                                       
     Set<Id> planTacticIDs = new Set<Id> ();
     List<SObject> toDelete = new List<SObject>();
     if (VOD_Utils.hasObject('Plan_Tactic_vod__Share')) {
        List<SObject> planTacticShares = Database.query('SELECT Id, ParentId, Parent.Account_Plan_vod__c, Parent.Share_With_vod__c, UserOrGroupId, RowCause FROM Plan_Tactic_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Plan_Tactic_vod__c WHERE Account_Plan_vod__c IN : actPlanIds)');
        for (SObject planTacticShare: planTacticShares) {
            Id memberId = (Id) planTacticShare.get('UserOrGroupId');
            Id accountPlanId = (Id) planTacticShare.getSObject('Parent').get('Account_Plan_vod__c');
            String shareWithValues = (String) planTacticShare.getSObject('Parent').get('Share_With_vod__c');     
            Account_Team_Member_vod__c teamMember = acctTeamMemberMap.get((Id) accountPlanId);    
            if (teamMember == null || shareWithValues == null || teamMember.Role_vod__c == null) {
                continue;
            }       
            if (teamMember.Team_Member_vod__c == planTacticShare.get('UserOrGroupId') && shareWithValues.contains(teamMember.Role_vod__c)) {
                Id planTacticId = (Id) planTacticShare.get('ParentId');
                planTacticIDs.add((Id) planTacticShare.get('ParentId'));
                system.debug(' the object that needs to be delete for Plan Tactic Share' + planTacticShare);
                if (ptIds.contains(planTacticId)) {
                    toDelete.add(planTacticShare);
                }
            }
        }                                              
                                                      
     }
     
     // now try and delete from account tactic
     // look for account tactic record to be deleted
     Set<Id> accountTacticIds = new Set<Id> (); 
     if (VOD_Utils.hasObject('Account_Tactic_vod__Share')) {
        List<SObject> accountTacticShares = Database.query('SELECT Id, ParentId, Parent.Plan_Tactic_vod__c, Parent.Account_Plan_vod__c, UserOrGroupId, RowCause FROM Account_Tactic_vod__Share ' +
                                                      'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Account_Tactic_vod__c WHERE Plan_Tactic_vod__c IN : planTacticIDs)');
        for (SObject accountTacticShare: accountTacticShares) {
            // since the query alaredy restricts the plan tactic shares that need to be deleted just delet all
            accountTacticIds.add((Id) accountTacticShare.get('ParentId'));
            system.debug(' the object that needs to be delete for account Tactic Share' + accountTacticShare);            
            toDelete.add(accountTacticShare);        
         }                          
                                                      
     }
    
    // call objective sharing
    if (VOD_Utils.hasObject('Call_Objective_vod__Share') && accoutMemberIDs.size() > 0 && accountTacticIds.size() > 0) {
        List<SObject> callObjectiveShares = Database.query('SELECT Id, ParentId, Parent.Account_Tactic_vod__c, Parent.Account_Plan_vod__c, UserOrGroupId, RowCause  FROM Call_Objective_vod__Share ' +
                                                      'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Call_Objective_vod__c WHERE Account_Tactic_vod__c IN : accountTacticIds)');
        for (SObject callObjectiveShare: callObjectiveShares) {           
            //Account_Team_Member_vod__c teamMember = acctTeamMemberMap.get((Id) accountPlanId);           
            system.debug(' the object that needs to be delete for call objective Share' + callObjectiveShare);            
            toDelete.add(callObjectiveShare);            
            
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