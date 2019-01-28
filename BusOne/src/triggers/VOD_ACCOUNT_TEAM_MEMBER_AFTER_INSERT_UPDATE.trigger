trigger VOD_ACCOUNT_TEAM_MEMBER_AFTER_INSERT_UPDATE on Account_Team_Member_vod__c (after insert, after update) {
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    if(vsc == null || vsc.Account_Plan_Sharing_vod__c == null || vsc.Account_Plan_Sharing_vod__c.intValue() != 1) {
        return;
    }

    // get active users to exclude the inactive ones
    Set<ID> userIDs = new Set<ID> ();
    for (Account_Team_Member_vod__c  actTeamMember : Trigger.new) {
        if (actTeamMember.Team_Member_vod__c != null) {
            userIDs.add(actTeamMember.Team_Member_vod__c);
        }
    }

    Map<ID,User> userObjectsMap = new Map<Id, User>([Select Id, IsActive from User where IsActive = false and Id in : userIDs]);
    // now lets get the users who are only active
    Set<Id> inActiveUsersId = userObjectsMap.keySet();


    // go through the loop and get all the account plan associated with the account team member
    Map<Id, List<Account_Team_Member_vod__c>> accountPlanIdTeamMemberMap = new Map<Id, List<Account_Team_Member_vod__c>> ();
    List<Account_Team_Member_vod__c> membersWithAccess = new List<Account_Team_Member_vod__c>();
    Set<ID> accountPlanIds = new Set<ID> ();

    for (Account_Team_Member_vod__c  actTeamMember : Trigger.new) {
        system.debug(' the value of account team member is ' + actTeamMember);

        if (actTeamMember.Access_vod__c == null || actTeamMember.Account_Plan_vod__c == null || actTeamMember.Team_Member_vod__c == null || inActiveUsersId.contains(actTeamMember.Team_Member_vod__c)) {
            system.debug('Skipping current team member: Access_vod__c, Account_Plan_vod__c, or Team_Member_vod__c is null');
            system.debug('For id: ' + actTeamMember.id + ', Access_vod__c is ' + actTeamMember.Access_vod__c + '; Account_Plan_vod__c is ' + actTeamMember.Account_Plan_vod__c + '; Team_Member_vod__c is ' + actTeamMember.Team_Member_vod__c);
            continue;
        }

        membersWithAccess.add(actTeamMember);

        List<Account_Team_Member_vod__c> planMembers = accountPlanIdTeamMemberMap.get(actTeamMember.Account_Plan_vod__c);
        if (planMembers == null) {
            planMembers = new List<Account_Team_Member_vod__c>();
            accountPlanIdTeamMemberMap.put(actTeamMember.Account_Plan_vod__c, planMembers);
        }
        planMembers.add(actTeamMember);

        system.debug(' the account plan id is ' + actTeamMember.Account_Plan_vod__c);
        accountPlanIds.add(actTeamMember.Account_Plan_vod__c);
    }

    // now add entry into account plan share and plan tactic share
    List<SObject> accountPlanShareObjects = new List<SObject> ();
    List<SObject> planTacticShareObjects = new List<SObject> ();
    List<SObject> planTactics = Database.query('Select Id, Account_Plan_vod__c,Share_With_vod__c from Plan_Tactic_vod__c where Account_Plan_vod__c in : accountPlanIds');
    Set<Id> planTacticIds = new Set<Id> ();
    Set<Id> delPlanTacticIds = new Set<Id> ();
    Set<ID> accoutMemberIDs = new Set<ID> ();


    for (Account_Team_Member_vod__c  actTeamMember : membersWithAccess) {
        // for all entries of account team member add share entries for account plan
        if (Schema.getGlobalDescribe().get('Account_Plan_vod__Share') != null ) {
            SObject accountPlanShare = Schema.getGlobalDescribe().get('Account_Plan_vod__Share').newSObject();
             accountPlanShare.put('UserOrGroupId', actTeamMember.Team_Member_vod__c) ;
             accountPlanShare.put('ParentId' , actTeamMember.Account_Plan_vod__c);
             accountPlanShare.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
             if (actTeamMember.Access_vod__c.equals('Read_vod')) {
                accountPlanShare.put('AccessLevel' ,'Read');
             } else if (actTeamMember.Access_vod__c.equals('Edit_vod')) {
                accountPlanShare.put('AccessLevel' ,'Edit' );
             }
             accountPlanShareObjects.add(accountPlanShare);
             system.debug(' add the following in account plan share ' +  accountPlanShare);
        }

        // plan tactic sharing
        for (SObject planTactic : planTactics ) {
            String planTacticAccountPlan = (String) planTactic.get('Account_Plan_vod__c');
            if (planTacticAccountPlan == actTeamMember.Account_Plan_vod__c) {
                // check if the share with vod matches
                String shareWithValues = (String ) planTactic.get('Share_With_vod__c');
                if (Schema.getGlobalDescribe().get('Plan_Tactic_vod__Share') != null) {
                    String planTacticId = (String) planTactic.get('Id');
                    //addition path
                    if (shareWithValues != null && actTeamMember.Role_vod__c != null && shareWithValues.contains(actTeamMember.Role_vod__c)) {
                        planTacticIds.add(planTacticId);
                        SObject planTacticShareObj  = Schema.getGlobalDescribe().get('Plan_Tactic_vod__Share').newSObject();
                        planTacticShareObj.put('UserOrGroupId', actTeamMember.Team_Member_vod__c) ;
                        planTacticShareObj.put('ParentId' , planTacticId);
                        planTacticShareObj.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
                        if (actTeamMember.Access_vod__c.equals('Read_vod')) {
                            planTacticShareObj.put('AccessLevel' ,'Read');
                        } else if (actTeamMember.Access_vod__c.equals('Edit_vod')) {
                            planTacticShareObj.put('AccessLevel' ,'Edit' );
                        }
                        planTacticShareObjects.add(planTacticShareObj);
                        system.debug(' add the following in plan tactic share ' +  planTacticShareObj);
                    } else { // deletion path
                        accoutMemberIDs.add(actTeamMember.Team_Member_vod__c);
                        delPlanTacticIds.add(planTacticId);
                    }

                }
            }

        }
    }


    // now checking if anything need to be added to account tactic
    List<SObject> accountTacticShareObjects = new List<SObject> ();
    // map for the account tactic and team member
    //Map<Id, Account_Team_Member_vod__c> accountTacticIdTeamMemberMap = new Map<Id, Account_Team_Member_vod__c> ();
    system.debug(' before querying the account tactic object ' + planTacticIds);
    List<Account_Tactic_vod__c> accountTactics = Database.query(' Select Id, Account_Plan_vod__c, Plan_Tactic_vod__c from Account_Tactic_vod__c where Plan_Tactic_vod__c in : planTacticIds');
    system.debug(' after querying the account tactic ' + accountTactics );
    List<ID> accountTacticIds = new List<ID> ();
    for (Account_Team_Member_vod__c actMember : membersWithAccess) {
        // for the inserted plan tacics find acocunt tactics that qualify
        for (Account_Tactic_vod__c accountTacticRecord : accountTactics) {
            system.debug(' inside the loop for account tactic object abd the one record is  ' + accountTacticRecord );
            String planTacticId = (String) accountTacticRecord.Plan_Tactic_vod__c;
            //Account_Team_Member_vod__c actMember = planTacticIdTeamMemberMap.get(planTacticId);
            system.debug(' the value of account team member ' + actMember );
            if ((actMember.Account_Plan_vod__c == accountTacticRecord.Account_Plan_vod__c) && Schema.getGlobalDescribe().get('Account_Tactic_vod__Share') != null) {
                Id accountTacticId = accountTacticRecord.Id;
                accountTacticIds.add(accountTacticId);
                //accountTacticIdTeamMemberMap.put(accountTacticId, actMember);
                // create share object for the account tactic
                SObject accountTacticShareObj  = Schema.getGlobalDescribe().get('Account_Tactic_vod__Share').newSObject();
                accountTacticShareObj.put('UserOrGroupId', actMember.Team_Member_vod__c) ;
                accountTacticShareObj.put('ParentId' , accountTacticId );
                accountTacticShareObj.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
                //accountTacticShareObj.put('RowCause', 'Account_Plan_Share_vod');
                if (actMember.Access_vod__c.equals('Read_vod')) {
                    accountTacticShareObj.put('AccessLevel' ,'Read');
                } else if (actMember.Access_vod__c.equals('Edit_vod')) {
                    accountTacticShareObj.put('AccessLevel' ,'Edit' );
                }
                accountTacticShareObjects.add(accountTacticShareObj);
                system.debug(' add the following in account tactic share ' +  accountTacticShareObj);
            }
        }
    }

    // call obbjective sharing
    List<SObject> callObjectiveShareObjects = new List<SObject> ();
    system.debug(' the values of account tactics are ' + accountTacticIds);
    List<SObject> callobjectives = Database.query('Select Id, Account_Plan_vod__c, Account_Tactic_vod__c from Call_Objective_vod__c where Account_Tactic_vod__c in : accountTacticIds');
    system.debug(' the call objective corresponding to accounttactic are ' + callobjectives.size() );
    for (Account_Team_Member_vod__c actMember : membersWithAccess) {
        for (SObject callObjectiveRecord: callobjectives ) {
            String actTactic = (String) callObjectiveRecord.get('Account_Tactic_vod__c');
            //Account_Team_Member_vod__c actMember = accountTacticIdTeamMemberMap.get(actTactic);
            if ((actMember.Account_Plan_vod__c == callObjectiveRecord.get('Account_Plan_vod__c')) && Schema.getGlobalDescribe().get('Call_Objective_vod__Share') != null) {
                // create share object for the call objective
                String callObjectiveId = (String) callObjectiveRecord.get('Id');
                SObject callObjectiveShareObj  = Schema.getGlobalDescribe().get('Call_Objective_vod__Share').newSObject();
                callObjectiveShareObj.put('UserOrGroupId', actMember.Team_Member_vod__c) ;
                callObjectiveShareObj.put('ParentId' , callObjectiveId);
                callObjectiveShareObj.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
                //callObjectiveShareObj.put('RowCause', 'manual');
                if (actMember.Access_vod__c.equals('Read_vod')) {
                    callObjectiveShareObj.put('AccessLevel' ,'Read');
                } else if (actMember.Access_vod__c.equals('Edit_vod')) {
                    callObjectiveShareObj.put('AccessLevel' ,'Edit' );
                }
                callObjectiveShareObjects.add(callObjectiveShareObj);
                system.debug(' add the following in call objective share ' +  callObjectiveShareObj);
            }
        }
    }

    // now we need to check if plan tactic need to be deleted and way down to account tactic andd others if the role changed and that does not match the share with values
    system.debug('the value of the delete plan tactic ids are ' + delPlanTacticIds);
    List<SObject> toDelete = new List<SObject>();
    if (delPlanTacticIds.size() > 0) {
    if (VOD_Utils.hasObject('Plan_Tactic_vod__Share')) {
        List<SObject> planTacticShares = Database.query('SELECT Id, ParentId, RowCause, UserOrGroupId FROM Plan_Tactic_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' And UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Plan_Tactic_vod__c WHERE Id IN : delPlanTacticIds)');
        // if the share with does not match delete them
        for (SObject planTacticShare : planTacticShares) {
            toDelete.add(planTacticShare);
        }
    }

    // now the account tactic share that needs to be deleted
    Set<Id> delAccountTacticIds = new Set<Id> ();
    if (VOD_Utils.hasObject('Account_Tactic_vod__Share')) {
        List<SObject> accountTacticShares = Database.query('SELECT Id, ParentId, RowCause, UserOrGroupId, Parent.Account_Plan_vod__c FROM Account_Tactic_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' ' +
                                                     ' And UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Account_Tactic_vod__c WHERE Plan_Tactic_vod__c IN : delPlanTacticIds)');
        // if the share with does not match delete them
        for (SObject accountTacticShare: accountTacticShares) {
            String accountTacticId = (String) accountTacticShare.get('ParentId');
            delAccountTacticIds.add(accountTacticId);
            toDelete.add(accountTacticShare);
        }
    }

    // now add the call objective that needs to be deleted
    if (VOD_Utils.hasObject('Call_Objective_vod__Share')) {
        List<SObject> callObjectiveShares = Database.query('SELECT Id, ParentId, RowCause, UserOrGroupId, Parent.Account_Plan_vod__c FROM Call_Objective_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' '  +
                                                     ' And UserOrGroupId IN : accoutMemberIDs AND ParentId IN (SELECT Id FROM Call_Objective_vod__c WHERE Account_Tactic_vod__c IN : delAccountTacticIds)');
        // if the share with does not match delete them
        for (SObject callObjectiveshare: callObjectiveShares) {
            toDelete.add(callObjectiveshare);
        }
    }

    }


    List<SObject> toUpsert = new List<SObject>();

    toUpsert.addAll(accountPlanShareObjects);
    system.debug(' the size of account plan share objects ' + accountPlanShareObjects.size() );
    toUpsert.addAll(planTacticShareObjects);
    system.debug(' the size of plan tactic share objects ' + planTacticShareObjects.size() );
    toUpsert.addAll(accountTacticShareObjects);
    system.debug(' the size of account tactic share objects ' + accountTacticShareObjects.size() );
    toUpsert.addAll(callObjectiveShareObjects);
    system.debug(' the size of call objective share objects ' + callObjectiveShareObjects.size() );


    if(toUpsert.size() > 0 && !toUpsert.isEmpty())  {
       system.debug(' inside teh upsert check and the size of the upsert are ' + toUpsert.size());
       system.debug(' the values inside the upsert array are ' + toUpsert);
       insert toUpsert;
    }

    if (toDelete.size() > 0) {
        List<Database.DeleteResult> deleteResults = Database.delete(toDelete, false);
        // before calling the delete
        system.debug(' the objects needs to be deleted ' + toDelete);
        for (Database.DeleteResult result : deleteResults) {
           if (!result.isSuccess()) {
               system.debug('delete error: ' + result.getErrors()[0]);
           }
        }
    }

}