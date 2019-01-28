trigger VOD_PLAN_TACTIC_AFTER_INSERT_UPDATE on Plan_Tactic_vod__c (after insert, after update) {
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    if (vsc == null || vsc.Account_Plan_Sharing_vod__c == null || vsc.Account_Plan_Sharing_vod__c.intValue() != 1) {
        return;
    }

    Set<Id> accountPlanIds = new Set<Id> ();

    for(Plan_Tactic_vod__c planTactic : Trigger.newMap.values()) {
        accountPlanIds.add(planTactic.Account_Plan_vod__c);
    }

    //delete all share records associated with these plan tactics
    List<SObject> toDelete = new List<SObject>();
    Set<Id> triggerPlanTacticIds = Trigger.newMap.keySet();
    if (VOD_Utils.hasObject('Plan_Tactic_vod__Share')) {
        System.debug('deleting all plan tactic share records for: ' + triggerPlanTacticIds);
        List<SObject> planTacticShares = Database.query('SELECT Id FROM Plan_Tactic_vod__Share WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND ParentId IN :triggerPlanTacticIds');
        toDelete.addAll(planTacticShares);
    }

    // now all the plan tactics' account tactic share records
    Set<Id> delAccountTacticIds = new Set<Id> ();
    if (VOD_Utils.hasObject('Account_Tactic_vod__Share')) {
        List<SObject> accountTacticShares = Database.query('SELECT Id, ParentId FROM Account_Tactic_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND ParentId IN (SELECT Id FROM Account_Tactic_vod__c WHERE Plan_Tactic_vod__c IN :triggerPlanTacticIds)');
        System.debug('deleting the following account tactic share records: ' + accountTacticShares);
        for (SObject accountTacticShare: accountTacticShares) {
            String accountTacticId = (String) accountTacticShare.get('ParentId');
            delAccountTacticIds.add(accountTacticId);
            toDelete.add(accountTacticShare);
        }
    }

    // now delete the account tactics' call objectives
    if (VOD_Utils.hasObject('Call_Objective_vod__Share')) {
        system.debug(' the account tactic ids to be used for deletion is ' +  delAccountTacticIds) ;
        List<SObject> callObjectiveShares = Database.query('SELECT Id FROM Call_Objective_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND ParentId IN (SELECT Id FROM Call_Objective_vod__c WHERE Account_Tactic_vod__c IN :delAccountTacticIds)');
        system.debug(' after querying the call objective share (these are the shares we will delete)' + callObjectiveShares);
        for (SObject callObjectiveshare: callObjectiveShares) {
            system.debug(' inside the call objective delete is  ' + callObjectiveshare);
            toDelete.add(callObjectiveshare);
        }
    }


    List<Database.DeleteResult> deleteResults = Database.delete(toDelete, false);
    // before calling the delete
    system.debug(' the objects needs to be deleted ' + toDelete);
    for (Database.DeleteResult result : deleteResults) {
        if (!result.isSuccess()) {
            system.debug('delete error: ' + result.getErrors()[0]);
        }
    }

    // now query the account team member object
    Map<Id, Account_Team_Member_vod__c> accountTeamMembers = new Map<Id, Account_Team_Member_vod__c>();
    system.debug(' the values of account plan is ' + accountPlanIds);
    Set<Id> usersId = new Set<Id> ();
    for (Account_Team_Member_vod__c member : [Select Id, Name, Account_Plan_vod__c, Team_Member_vod__c, Role_vod__c, Access_vod__c from Account_Team_Member_vod__c where Role_vod__c != null AND Access_vod__c  != null AND Team_Member_vod__c != null AND Account_Plan_vod__c in :accountPlanIds]) {
        accountTeamMembers.put(member.Id, member);
        usersId.add(member.Team_Member_vod__c);
        system.debug(' inside the account team member loop' + accountTeamMembers);
    }


    Map<ID,User> userObjectsMap = new Map<Id, User>([Select Id, IsActive from User where IsActive = false and Id in : usersId]);
    // now lets get the users who are only active
    system.debug(' the values in the user map is ' + userObjectsMap);
    Set<Id> inActiveUsersId = userObjectsMap.keySet();

    Map<Id, Set<Id>> teamMembersToTacticIds = new Map<Id, Set<Id>>();
    for (Plan_Tactic_vod__c planTactic : Trigger.new) {
        String tacticAcctPlan = planTactic.Account_Plan_vod__c;
        String shareWithValues = planTactic.Share_With_vod__c;
        if (shareWithValues == null) {
            continue;
        }
        for (Account_Team_Member_vod__c teamMember : accountTeamMembers.values()) {
            if (tacticAcctPlan == teamMember.Account_Plan_vod__c && shareWithValues.contains(teamMember.Role_vod__c) && !inActiveUsersId.contains(teamMember.Team_Member_vod__c)) {
                Set<Id> planTacticList = teamMembersToTacticIds.get(teamMember.Id);
                if (planTacticList == null) {
                    planTacticList = new Set<Id>();
                    teamMembersToTacticIds.put(teamMember.Id, planTacticList);
                }
                planTacticList.add(planTactic.Id);
            }
        }
    }



    SobjectType planTacticShareDescribe = Schema.getGlobalDescribe().get('Plan_Tactic_vod__Share');
    List<SObject> planTacticShareObjects = new List<SObject> ();
    Set<Id> planTacticIds = new Set<Id> ();
    for(Id teamMemberId: teamMembersToTacticIds.keySet()) {
        Account_Team_Member_vod__c teamMember = accountTeamMembers.get(teamMemberId);
        String userId = teamMember.Team_Member_vod__c;
        String access = teamMember.Access_vod__c;
        Set<Id> tacticIds = teamMembersToTacticIds.get(teamMemberId);
        for (Id planTacticId : tacticIds) {
            // add the plan tactic ids
            planTacticIds.add(planTacticId);
            if (planTacticShareDescribe != null) {
                // need to update the plan tactic share
                SObject planTacticShareObj  = planTacticShareDescribe.newSObject();
                planTacticShareObj.put('UserOrGroupId', userId) ;
                planTacticShareObj.put('ParentId' , planTacticId);
                planTacticShareObj.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
                if (access.equals('Read_vod')) {
                    planTacticShareObj.put('AccessLevel' ,'Read');
                } else if (access.equals('Edit_vod')) {
                    planTacticShareObj.put('AccessLevel' ,'Edit' );
                }
                planTacticShareObjects.add(planTacticShareObj);
            }
        }
    }

    // now do account tactic sharing
    // now checking if anything need to be added to account tactic
    List<SObject> accountTacticShareObjects = new List<SObject> ();
    // map for the account tactic and team member
    List<Account_Tactic_vod__c> accountTactics = Database.query('Select Id, Account_Plan_vod__c, Plan_Tactic_vod__c from Account_Tactic_vod__c where Plan_Tactic_vod__c in : planTacticIds AND ' +
                                               ' Account_Plan_vod__c in : accountPlanIds ');

    SobjectType acctTacticShareDescribe = Schema.getGlobalDescribe().get('Account_Tactic_vod__Share');
    Set<Id> accountTacticIds = new Set<Id>();
    for (Id teamMemberId : teamMembersToTacticIds.keySet()) {
        Account_Team_Member_vod__c teamMember = accountTeamMembers.get(teamMemberId);
        String userId = teamMember.Team_Member_vod__c;
        String access = teamMember.Access_vod__c;
        String memberAcctPlan = teamMember.Account_Plan_vod__c;
        Set<Id> planTacticIds = teamMembersToTacticIds.get(teamMemberId);
        for (Account_Tactic_vod__c acctTactic : accountTactics) {
            if (acctTactic.Account_Plan_vod__c == memberAcctPlan && planTacticIds.contains(acctTactic.Plan_Tactic_vod__c)) {
                accountTacticIds.add(acctTactic.Id);
                if (acctTacticShareDescribe != null) {
                    // create share object for the account tactic
                    SObject accountTacticShareObj  = acctTacticShareDescribe.newSObject();
                    accountTacticShareObj.put('UserOrGroupId', userId) ;
                    accountTacticShareObj.put('ParentId' , acctTactic.Id );
                    accountTacticShareObj.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
                    if (access.equals('Read_vod')) {
                        accountTacticShareObj.put('AccessLevel' ,'Read');
                    } else if (access.equals('Edit_vod')) {
                        accountTacticShareObj.put('AccessLevel' ,'Edit' );
                    }
                    accountTacticShareObjects.add(accountTacticShareObj);
                }
            }
        }
    }

    // and call objective sharing
    List<SObject> callObjectiveShareObjects = new List<SObject> ();
    List<Call_Objective_vod__c> callObjectives = Database.query('Select Id, Account_Plan_vod__c, Account_Tactic_vod__r.Plan_Tactic_vod__c from Call_Objective_vod__c where Account_Tactic_vod__c in :accountTacticIds ' +
                                                  ' AND Account_Plan_vod__c in :accountPlanIds ');

    SobjectType objectiveShareDescribe = Schema.getGlobalDescribe().get('Call_Objective_vod__Share');
    if (objectiveShareDescribe != null) {
        for (Id teamMemberId : teamMembersToTacticIds.keySet()) {
            Account_Team_Member_vod__c teamMember = accountTeamMembers.get(teamMemberId);
            String userId = teamMember.Team_Member_vod__c;
            String access = teamMember.Access_vod__c;
            String memberAcctPlan = teamMember.Account_Plan_vod__c;
            Set<Id> planTacticIds = teamMembersToTacticIds.get(teamMemberId);
            for (Call_Objective_vod__c objective : callObjectives) {
                if ((objective.Account_Plan_vod__c == null || objective.Account_Plan_vod__c == memberAcctPlan) && objective.Account_Tactic_vod__r != null &&
                          planTacticIds.contains(objective.Account_Tactic_vod__r.Plan_Tactic_vod__c)) {
                    // create share object for the call objective
                    SObject callObjectiveShareObj = objectiveShareDescribe.newSObject();
                    callObjectiveShareObj.put('UserOrGroupId', userId) ;
                    callObjectiveShareObj.put('ParentId' , objective.Id);
                    callObjectiveShareObj.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
                    if (access.equals('Read_vod')) {
                        callObjectiveShareObj.put('AccessLevel' ,'Read');
                    } else if (access.equals('Edit_vod')) {
                        callObjectiveShareObj.put('AccessLevel' ,'Edit' );
                    }
                    callObjectiveShareObjects.add(callObjectiveShareObj);
                }
            }
        }
    }

    List<SObject> toUpsert = new List<SObject>();

    toUpsert.addAll(planTacticShareObjects);
    toUpsert.addAll(accountTacticShareObjects);
    toUpsert.addAll(callObjectiveShareObjects);

    if (!toUpsert.isEmpty())  {
        insert toUpsert;
    }
}