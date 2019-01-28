trigger VOD_TEAM_MEMBER_AFTER_DELETE on EM_Event_Team_Member_vod__c (after delete) {
    Set<String> groupNameSet = new Set<String>();
    for(EM_Event_Team_Member_vod__c member : Trigger.old) {
        if(member.Group_Name_vod__c != null) {
            groupNameSet.add(member.Group_Name_vod__c);
        }
    }

    Map<String, Id> groupNameToGroupId = new Map<String, Id>();
    for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNameSet]) {
        groupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
    }

    Set<Id> membersId = new Set<Id>();
    Map<Id, Set<Id>> eventToMembers = new Map<Id, Set<Id>>();
    for (EM_Event_Team_Member_vod__c member : Trigger.old) {
        if (eventToMembers.get(member.Event_vod__c) == null) {
            eventToMembers.put(member.Event_vod__c, new Set<Id>());
        }
        if(member.Team_Member_vod__c != null) {
            membersId.add(member.Team_Member_vod__c);
            eventToMembers.get(member.Event_vod__c).add(member.Team_Member_vod__c);
        } else if(member.Group_Name_vod__c != null) {
            Id groupUserId = groupNameToGroupId.get(member.Group_Name_vod__c);
            if(groupUserId != null) {
                membersId.add(groupUserId);
                eventToMembers.get(member.Event_vod__c).add(groupUserId);
            }
        }
    }
    Set<Id> eventsId = eventToMembers.keySet();

    List<SObject> toDelete = new List<SObject>();
    if (VOD_Utils.hasObject('EM_Event_vod__Share')) {
        List<SObject> eventShares = Database.query('SELECT Id, ParentId, UserOrGroupId FROM EM_Event_vod__Share WHERE UserOrGroupId IN : membersId AND ParentId IN : eventsId');
        for (SObject eventShare : eventShares) {
            if (eventToMembers.get((Id) eventShare.get('ParentId')).contains((Id) eventShare.get('UserOrGroupId'))) {
                toDelete.add(eventShare);
            }
        }
    }

    if (VOD_Utils.hasObject('Medical_Event_vod__Share')) {
        List<SObject> medicalEventShares = Database.query('SELECT Id, Parent.EM_Event_vod__c, UserOrGroupId FROM Medical_Event_vod__Share ' +
                                                          'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM Medical_Event_vod__c WHERE EM_Event_vod__c IN : eventsId)');
        for (SObject medicalEventShare : medicalEventShares) {
            if (eventToMembers.get((Id) medicalEventShare.getSObject('Parent').get('EM_Event_vod__c')).contains((Id) medicalEventShare.get('UserOrGroupId'))) {
                toDelete.add(medicalEventShare);
            }
        }
    }

    if (VOD_Utils.hasObject('EM_Attendee_vod__Share')) {
        List<SObject> attendeeShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Attendee_vod__Share ' +
                                                      'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Attendee_vod__c WHERE Event_vod__c IN : eventsId)');
        for (SObject attendeeShare : attendeeShares) {
            if (eventToMembers.get((Id) attendeeShare.getSObject('Parent').get('Event_vod__c')).contains((Id) attendeeShare.get('UserOrGroupId'))) {
                toDelete.add(attendeeShare);
            }
        }
    }

    if (VOD_Utils.hasObject('EM_Event_Speaker_vod__Share')) {
        List<SObject> speakerShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Speaker_vod__Share ' +
                                                     'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Speaker_vod__c WHERE Event_vod__c IN : eventsId)');
        for (SObject speakerShare : speakerShares) {
            if (eventToMembers.get((Id) speakerShare.getSObject('Parent').get('Event_vod__c')).contains((Id) speakerShare.get('UserOrGroupId'))) {
                toDelete.add(speakerShare);
            }
        }
    }

    if (VOD_Utils.hasObject('EM_Expense_Estimate_vod__Share')) {
        List<SObject> expenseShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Expense_Estimate_vod__Share ' +
                                                     'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Expense_Estimate_vod__c WHERE Event_vod__c IN : eventsId)');
        for (SObject expenseShare : expenseShares) {
            if (eventToMembers.get((Id) expenseShare.getSObject('Parent').get('Event_vod__c')).contains((Id) expenseShare.get('UserOrGroupId'))) {
                toDelete.add(expenseShare);
            }
        }
    }

    if (VOD_Utils.hasObject('EM_Event_Session_vod__Share')) {
        List<SObject> sessionShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Session_vod__Share ' +
                                                     'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Session_vod__c WHERE Event_vod__c IN : eventsId)');
        for (SObject sessionShare : sessionShares) {
            if (eventToMembers.get((Id) sessionShare.getSObject('Parent').get('Event_vod__c')).contains((Id) sessionShare.get('UserOrGroupId'))) {
                toDelete.add(sessionShare);
            }
        }
    }

    if (VOD_Utils.hasObject('EM_Event_Session_Attendee_vod__Share')) {
        List<SObject> sessionAttendeeShares = Database.query('SELECT Id, Parent.Event_Session_vod__r.Event_vod__c, UserOrGroupId FROM EM_Event_Session_Attendee_vod__Share ' +
                                                             'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Session_Attendee_vod__c ' +
                                                                                                                 'WHERE Event_Session_vod__r.Event_vod__c IN : eventsId)');
        for (SObject sessionAttendeeShare : sessionAttendeeShares) {
            if (sessionAttendeeShare.getSObject('Parent').getSObject('Event_Session_vod__r') != null &&
                eventToMembers.get((Id) sessionAttendeeShare.getSObject('Parent').getSObject('Event_Session_vod__r').get('Event_vod__c')).contains((Id) sessionAttendeeShare.get('UserOrGroupId'))) {
                toDelete.add(sessionAttendeeShare);
            }
        }
    }

    if (VOD_Utils.hasObject('Expense_Header_vod__Share')) {
        List<SObject> headerShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM Expense_Header_vod__Share ' +
                                                    'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM Expense_Header_vod__c WHERE Event_vod__c IN : eventsId)');
        for (SObject headerShare : headerShares) {
            if (eventToMembers.get((Id) headerShare.getSObject('Parent').get('Event_vod__c')).contains((Id) headerShare.get('UserOrGroupId'))) {
                toDelete.add(headerShare);
            }
        }
    }

    if (VOD_Utils.hasObject('EM_Event_Budget_vod__Share')) {
        List<SObject> budgetShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Budget_vod__Share ' +
                                                    'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Budget_vod__c WHERE Event_vod__c IN : eventsId)');
        for (SObject budgetShare : budgetShares) {
            if (eventToMembers.get((Id) budgetShare.getSObject('Parent').get('Event_vod__c')).contains((Id) budgetShare.get('UserOrGroupId'))) {
                toDelete.add(budgetShare);
            }
        }
    }

    if (VOD_Utils.hasObject('EM_Event_History_vod__Share')) {
        List<SObject> historyShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_History_vod__Share ' +
                                                     'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_History_vod__c WHERE Event_vod__c IN : eventsId)');
        for (SObject historyShare : historyShares) {
            if (eventToMembers.get((Id) historyShare.getSObject('Parent').get('Event_vod__c')).contains((Id) historyShare.get('UserOrGroupId'))) {
                toDelete.add(historyShare);
            }
        }
    }

    if (VOD_Utils.hasObject('EM_Event_Material_vod__Share')) {
        List<SObject> materialShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Material_vod__Share ' +
                                                      'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Material_vod__c WHERE Event_vod__c IN : eventsId)');
        for (SObject materialShare : materialShares) {
            if (eventToMembers.get((Id) materialShare.getSObject('Parent').get('Event_vod__c')).contains((Id) materialShare.get('UserOrGroupId'))) {
                toDelete.add(materialShare);
            }
        }
    }

    List<Database.DeleteResult> deleteResults = Database.delete(toDelete, false);
    for (Database.DeleteResult result : deleteResults) {
       if (!result.isSuccess()) {
           system.debug('delete error: ' + result.getErrors()[0]);
       }
    }
}