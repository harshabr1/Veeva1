trigger VOD_ACCOUNT_TEAM_MEMBER_AFTER_DELETE on Account_Team_Member_vod__c (after delete) {
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    if (vsc == null || vsc.Account_Plan_Sharing_vod__c == null || vsc.Account_Plan_Sharing_vod__c.intValue() != 1) {
        return;
    }

    Set<ID> accoutMemberIDs = new Set<ID> ();
    Set<ID> accountPlanIds = new Set<ID> ();
    //Map<Id, Account_Team_Member_vod__c> acctTeamMemberMap = new Map<Id, Account_Team_Member_vod__c> (); 
    for (Account_Team_Member_vod__c teamMember : Trigger.old) {
        system.debug('the value of team member value is ' + teamMember.Team_Member_vod__c); 
        accoutMemberIDs.add((ID) teamMember.Team_Member_vod__c); 
        accountPlanIds.add((ID) teamMember.Account_Plan_vod__c); 
        //acctTeamMemberMap.put((ID) teamMember.Account_Plan_vod__c, teamMember);  
    }
    
    // look for account plan share records to be deleted
    List<SObject> toDelete = new List<SObject>();
    if (VOD_Utils.hasObject('Account_Plan_vod__Share')) {
        List<SObject> accountPlanShares = Database.query('SELECT Id, ParentId, UserOrGroupId, RowCause FROM Account_Plan_vod__Share WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN : accountPlanIds');
        for (SObject accountPlanShare: accountPlanShares) {
            system.debug(' the object that needs to be delete for Account plan Share ' + accountPlanShare);
            toDelete.add(accountPlanShare);            
        }
    }
    
    // look for plan tactic record that needs to be deleted
    Set<Id> planTacticIDs = new Set<Id> ();
    if (VOD_Utils.hasObject('Plan_Tactic_vod__Share')) {
        List<SObject> planTacticShares = Database.query('SELECT Id, ParentId, Parent.Account_Plan_vod__c, Parent.Share_With_vod__c, UserOrGroupId, RowCause FROM Plan_Tactic_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Plan_Tactic_vod__c WHERE Account_Plan_vod__c IN : accountPlanIds)');
        system.debug(' all the plan tactic shares that need to be deleted ' + planTacticShares) ;
        for (SObject planTacticShare: planTacticShares) {
            Id memberId = (Id) planTacticShare.get('UserOrGroupId');
            Id accountPlanId = (Id) planTacticShare.getSObject('Parent').get('Account_Plan_vod__c');
            String shareWithValues = (String) planTacticShare.getSObject('Parent').get('Share_With_vod__c'); 
            for (Account_Team_Member_vod__c teamMember : Trigger.old) {
                // for each plan tactic share find the ones that belongs to the account team member and then delete them
                if (teamMember.Team_Member_vod__c == memberId  && teamMember.Account_Plan_vod__c == accountPlanId && shareWithValues.contains(teamMember.Role_vod__c)) {
                    planTacticIDs.add((Id) planTacticShare.get('ParentId'));
                    system.debug(' the object that needs to be delete for Plan Tactic Share' + planTacticShare);
                    toDelete.add(planTacticShare);
                }            
            }  
            /*Account_Team_Member_vod__c teamMember = acctTeamMemberMap.get((Id) accountPlanId); 
            if (teamMember == null || shareWithValues == null || teamMember.Role_vod__c == null) {
                continue;
            }           
            if (teamMember.Team_Member_vod__c == planTacticShare.get('UserOrGroupId') && shareWithValues.contains(teamMember.Role_vod__c)) {
                planTacticIDs.add((Id) planTacticShare.get('ParentId'));
                system.debug(' the object that needs to be delete for Plan Tactic Share' + planTacticShare);
                toDelete.add(planTacticShare);
            } */
        }                                              
                                                      
    }
    
    // look for account tactic record to be deleted
    Set<Id> accountTacticIds = new Set<Id> (); 
    if (VOD_Utils.hasObject('Account_Tactic_vod__Share')) {
        List<SObject> accountTacticShares = Database.query('SELECT Id, ParentId, Parent.Plan_Tactic_vod__c, RowCause, Parent.Account_Plan_vod__c, UserOrGroupId FROM Account_Tactic_vod__Share ' +
                                                      'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Account_Tactic_vod__c WHERE Plan_Tactic_vod__c IN : planTacticIDs)');
        for (SObject accountTacticShare: accountTacticShares) {            
            accountTacticIds.add((Id) accountTacticShare.get('ParentId'));
            system.debug(' the object that needs to be delete for account Tactic Share' + accountTacticShare);
            toDelete.add(accountTacticShare);                     
        }                                              
                                                      
    }
    
    // call objective sharing
    if (VOD_Utils.hasObject('Call_Objective_vod__Share') && accoutMemberIDs.size() > 0 && accountTacticIds.size() > 0) {
        List<SObject> callObjectiveShares = Database.query('SELECT Id, ParentId, RowCause,Parent.Account_Tactic_vod__c, Parent.Account_Plan_vod__c, UserOrGroupId FROM Call_Objective_vod__Share ' +
                                                      'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Call_Objective_vod__c WHERE Account_Tactic_vod__c IN : accountTacticIds)');
         
        for (SObject callObjectiveShare: callObjectiveShares) {
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