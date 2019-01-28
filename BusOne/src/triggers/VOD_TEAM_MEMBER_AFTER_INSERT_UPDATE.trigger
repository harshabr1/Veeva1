trigger VOD_TEAM_MEMBER_AFTER_INSERT_UPDATE on EM_Event_Team_Member_vod__c (after insert, after update) {
    
    List<SObject> eventSharesToUpsert = new List<SObject>();
    List<SObject> medicalEventSharesToUpsert = new List<SObject>();
    List<SObject> attendeeSharesToUpsert = new List<SObject>();
    List<SObject> speakerSharesToUpsert = new List<SObject>();
    List<SObject> estimateSharesToUpsert = new List<SObject>();
    List<SObject> sessionSharesToUpsert = new List<SObject>();
    List<SObject> sessionAttendeeSharesToUpsert = new List<SObject>();
    List<SObject> headerSharesToUpsert = new List<SObject>();
    List<SObject> budgetSharesToUpsert = new List<SObject>();
    List<SObject> historySharesToUpsert = new List<SObject>();
    List<SObject> materialSharestoUpsert = new List<SObject>();
    
    Set<Id> event_ids = new Set<Id>();
    Set<Id> oldTeamMember = new Set<Id>();

    if (Trigger.isInsert) {
        for (EM_Event_Team_Member_vod__c member : Trigger.new) {
            event_ids.add(member.Event_vod__c);
        }
    } else {

        Set<String> oldGroupNameSet = new Set<String>();
        for(EM_Event_Team_Member_vod__c member : Trigger.old) {
            if(member.Group_Name_vod__c != null) {
                oldGroupNameSet.add(member.Group_Name_vod__c);
            }
        }

        Map<String, Id> oldGroupNameGroupId = new Map<String, Id>();
        for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :oldGroupNameSet]) {
            oldGroupNameGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
        }

        List<SObject> toDelete = new List<SObject>();
        List<Id> oldUser = new List<Id>();
        List<Id> oldEvent = new List<Id>();
        Map<Id, Set<Id>> eventToUsers = new Map<Id, Set<Id>>();
        for (EM_Event_Team_Member_vod__c member : Trigger.old) {
            if (member.Event_vod__c != Trigger.newMap.get(member.Id).Event_vod__c ||
                member.Team_Member_vod__c != Trigger.newMap.get(member.Id).Team_Member_vod__c ||
                member.Group_Name_vod__c != Trigger.newMap.get(member.Id).Group_Name_vod__c) {
                if (eventToUsers.get(member.Event_vod__c) == null) {
                    eventToUsers.put(member.Event_vod__c, new Set<Id>());
                }
                if(member.Team_Member_vod__c != null) {
                    eventToUsers.get(member.Event_vod__c).add(member.Team_Member_vod__c);
                    oldUser.add(member.Team_Member_vod__c);
                } else if(member.Group_Name_vod__c != null) {
                    Id groupUserId = oldGroupNameGroupId.get(member.Group_Name_vod__c);
                    if(groupUserId != null) {
                        oldUser.add(groupUserId);
                        eventToUsers.get(member.Event_vod__c).add(groupUserId);
                    }
                }
                oldEvent.add(member.Event_vod__c);
                oldTeamMember.add(member.Id);
                event_ids.add(Trigger.newMap.get(member.Id).Event_vod__c);
            }
        }
        if (!oldTeamMember.isEmpty()) {
            // delete old share records because Event_vod__c or Team_Member_vod__c or Group_Name_vod__c fields on event team member were changed
            if (VOD_Utils.hasObject('EM_Event_vod__Share')) {
                List<SObject> eventShares = Database.query('SELECT Id, ParentId, UserOrGroupId FROM EM_Event_vod__Share WHERE UserOrGroupId IN : oldUser AND ParentId IN : oldEvent');
                for (SObject eventShare : eventShares) {
                    if (eventToUsers.get((Id) eventShare.get('ParentId')).contains((Id) eventShare.get('UserOrGroupId'))) {
                        toDelete.add(eventShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('Medical_Event_vod__Share')) {
                List<SObject> medicalEventShares = Database.query('SELECT Id, Parent.EM_Event_vod__c, UserOrGroupId FROM Medical_Event_vod__Share ' +
                                                                  'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM Medical_Event_vod__c WHERE EM_Event_vod__c IN : oldEvent)');
                for (SObject medicalEventShare : medicalEventShares) {
                    if (eventToUsers.get((Id) medicalEventShare.getSObject('Parent').get('EM_Event_vod__c')).contains((Id) medicalEventShare.get('UserOrGroupId'))) {
                        toDelete.add(medicalEventShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('EM_Attendee_vod__Share')) {
                List<SObject> attendeeShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Attendee_vod__Share ' +
                                                              'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM EM_Attendee_vod__c WHERE Event_vod__c IN : oldEvent)');
                for (SObject attendeeShare : attendeeShares) {
                    if (eventToUsers.get((Id) attendeeShare.getSObject('Parent').get('Event_vod__c')).contains((Id) attendeeShare.get('UserOrGroupId'))) {
                        toDelete.add(attendeeShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('EM_Event_Speaker_vod__Share')) {
                List<SObject> speakerShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Speaker_vod__Share ' +
                                                             'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM EM_Event_Speaker_vod__c WHERE Event_vod__c IN : oldEvent)');
                for (SObject speakerShare : speakerShares) {
                    if (eventToUsers.get((Id) speakerShare.getSObject('Parent').get('Event_vod__c')).contains((Id) speakerShare.get('UserOrGroupId'))) {
                        toDelete.add(speakerShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('EM_Expense_Estimate_vod__Share')) {
                List<SObject> expenseShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Expense_Estimate_vod__Share ' +
                                                             'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM EM_Expense_Estimate_vod__c WHERE Event_vod__c IN : oldEvent)');
                for (SObject expenseShare : expenseShares) {
                    if (eventToUsers.get((Id) expenseShare.getSObject('Parent').get('Event_vod__c')).contains((Id) expenseShare.get('UserOrGroupId'))) {
                        toDelete.add(expenseShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('EM_Event_Session_vod__Share')) {
                List<SObject> sessionShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Session_vod__Share ' +
                                                             'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM EM_Event_Session_vod__c WHERE Event_vod__c IN : oldEvent)');
                for (SObject sessionShare : sessionShares) {
                    if (eventToUsers.get((Id) sessionShare.getSObject('Parent').get('Event_vod__c')).contains((Id) sessionShare.get('UserOrGroupId'))) {
                        toDelete.add(sessionShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('EM_Event_Session_Attendee_vod__Share')) {
                List<SObject> sessionAttendeeShares = Database.query('SELECT Id, Parent.Event_Session_vod__r.Event_vod__c, UserOrGroupId FROM EM_Event_Session_Attendee_vod__Share ' +
                                                                     'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM EM_Event_Session_Attendee_vod__c ' +
                                                                                                                         'WHERE Event_Session_vod__r.Event_vod__c IN : oldEvent)');
                for (SObject sessionAttendeeShare : sessionAttendeeShares) {
                    if (sessionAttendeeShare.getSObject('Parent').getSObject('Event_Session_vod__r') != null &&
                        eventToUsers.get((Id) sessionAttendeeShare.getSObject('Parent').getSObject('Event_Session_vod__r').get('Event_vod__c')).contains((Id) sessionAttendeeShare.get('UserOrGroupId'))) {
                        toDelete.add(sessionAttendeeShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('Expense_Header_vod__Share')) {
                List<SObject> headerShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM Expense_Header_vod__Share ' +
                                                            'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM Expense_Header_vod__c WHERE Event_vod__c IN : oldEvent)');
                for (SObject headerShare : headerShares) {
                    if (eventToUsers.get((Id) headerShare.getSObject('Parent').get('Event_vod__c')).contains((Id) headerShare.get('UserOrGroupId'))) {
                        toDelete.add(headerShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('EM_Event_Budget_vod__Share')) {
                List<SObject> budgetShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Budget_vod__Share ' +
                                                            'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM EM_Event_Budget_vod__c WHERE Event_vod__c IN : oldEvent)');
                for (SObject budgetShare : budgetShares) {
                    if (eventToUsers.get((Id) budgetShare.getSObject('Parent').get('Event_vod__c')).contains((Id) budgetShare.get('UserOrGroupId'))) {
                        toDelete.add(budgetShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('EM_Event_History_vod__Share')) {
                List<SObject> historyShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_History_vod__Share ' +
                                                             'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM EM_Event_History_vod__c WHERE Event_vod__c IN : oldEvent)');
                for (SObject historyShare : historyShares) {
                    if (eventToUsers.get((Id) historyShare.getSObject('Parent').get('Event_vod__c')).contains((Id) historyShare.get('UserOrGroupId'))) {
                        toDelete.add(historyShare);
                    }
                }
            }
            if (VOD_Utils.hasObject('EM_Event_Material_vod__Share')) {
                List<SObject> materialShares = Database.query('SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Material_vod__Share ' +
                                                              'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM EM_Event_Material_vod__c WHERE Event_vod__c IN : oldEvent)');
                for (SObject materialShare : materialShares) {
                    if (eventToUsers.get((Id) materialShare.getSObject('Parent').get('Event_vod__c')).contains((Id) materialShare.get('UserOrGroupId'))) {
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
    }

    Set<Id> lockedEvents = new Set<Id>();
    List<EM_Attendee_vod__c> attendees = new List<EM_Attendee_vod__c>();
    List<EM_Event_Speaker_vod__c> speakers = new List<EM_Event_Speaker_vod__c>();
    List<EM_Expense_Estimate_vod__c> expenses = new List<EM_Expense_Estimate_vod__c>();
    List<Expense_Header_vod__c> headers = new List<Expense_Header_vod__c>();
    List<EM_Event_Budget_vod__c> budgets = new List<EM_Event_Budget_vod__c>();
    List<EM_Event_History_vod__c> histories = new List<EM_Event_History_vod__c>();
    List<EM_Event_Material_vod__c> materials = new List<EM_Event_Material_vod__c>();
    Map<Id, Id> eventToMedicalEvent = new Map<Id, Id>();
    Map<Id, Set<Id>> eventToAttendees = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> eventToSpeakers = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> eventToExpenses = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> eventToSessions = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> eventToSessionAttendees = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> eventToHeaders = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> eventToBudgets = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> eventToHistories = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> eventToMaterials = new Map<Id, Set<Id>>();
    if (!event_ids.isEmpty()) {
        List<EM_Event_vod__c> events = [SELECT Id, Override_Lock_vod__c, Lock_vod__c,
                                        (SELECT Id, Event_vod__c FROM EM_Attendee_Event_vod__r), (SELECT Id, Event_vod__c FROM EM_Event_Speaker_vod__r),
                                        (SELECT Id, Event_vod__c FROM Expense_Estimate_vod__r), (SELECT Id, Event_vod__c FROM Expense_Header_vod__r),
                                        (SELECT Id, Event_vod__c FROM Event_vod__r), (SELECT Id, Event_vod__c FROM EM_Event_History_Event_vod__r),
                                        (SELECT Id, Event_vod__c FROM Event_Materials__r)
                                        FROM EM_Event_vod__c WHERE Id IN : event_ids];
        for (EM_Event_vod__c event : events) {
            for (EM_Attendee_vod__c attendee : event.EM_Attendee_Event_vod__r) {
                attendees.add(attendee);
            }
            for (EM_Event_Speaker_vod__c speaker : event.EM_Event_Speaker_vod__r) {
                speakers.add(speaker);
            }
            for (EM_Expense_Estimate_vod__c expense : event.Expense_Estimate_vod__r) {
                expenses.add(expense);
            }
            for (Expense_Header_vod__c header : event.Expense_Header_vod__r) {
                headers.add(header);
            }
            for (EM_Event_Budget_vod__c budget : event.Event_vod__r) {
                budgets.add(budget);
            }
            for (EM_Event_History_vod__c history : event.EM_Event_History_Event_vod__r) {
                histories.add(history);
            }
            for (EM_Event_Material_vod__c material : event.Event_Materials__r) {
                materials.add(material);
            }
        }
        if (VOD_Utils.hasObject('Medical_Event_vod__Share')) {
            List<Medical_Event_vod__c> medicalEvents = [SELECT Id, EM_Event_vod__c FROM Medical_Event_vod__c WHERE EM_Event_vod__c IN : event_ids];
            for (Medical_Event_vod__c medicalEvent : medicalEvents) {
                eventToMedicalEvent.put(medicalEvent.EM_Event_vod__c, medicalEvent.Id);
            }
        }
        if (VOD_Utils.hasObject('EM_Attendee_vod__Share')) {
            for (EM_Attendee_vod__c attendee : attendees) {
                if (eventToAttendees.get(attendee.Event_vod__c) == null) {
                    eventToAttendees.put(attendee.Event_vod__c, new Set<Id>());
                }
                eventToAttendees.get(attendee.Event_vod__c).add(attendee.Id);
            }
        }
        if (VOD_Utils.hasObject('EM_Event_Speaker_vod__Share')) {
            for (EM_Event_Speaker_vod__c speaker : speakers) {
                if (eventToSpeakers.get(speaker.Event_vod__c) == null) {
                    eventToSpeakers.put(speaker.Event_vod__c, new Set<Id>());
                }
                eventToSpeakers.get(speaker.Event_vod__c).add(speaker.Id);
            }
        }
        if (VOD_Utils.hasObject('EM_Expense_Estimate_vod__Share')) {
            for (EM_Expense_Estimate_vod__c expense : expenses) {
                if (eventToExpenses.get(expense.Event_vod__c) == null) {
                    eventToExpenses.put(expense.Event_vod__c, new Set<Id>());
                }
                eventToExpenses.get(expense.Event_vod__c).add(expense.Id);
            }
        }
        if (VOD_Utils.hasObject('EM_Event_Session_vod__Share') || VOD_Utils.hasObject('EM_Event_Session_Attendee_vod__Share')) {
            List<EM_Event_Session_vod__c> sessions = [SELECT Id, Event_vod__c, (SELECT Id FROM Event_Session_vod__r) FROM EM_Event_Session_vod__c WHERE Event_vod__c IN : event_ids];
            for (EM_Event_Session_vod__c session : sessions) {
                if (eventToSessions.get(session.Event_vod__c) == null) {
                    eventToSessions.put(session.Event_vod__c, new Set<Id>());
                }
                eventToSessions.get(session.Event_vod__c).add(session.Id);
                for (EM_Event_Session_Attendee_vod__c sessionAttendee : session.Event_Session_vod__r) {
                    if (eventToSessionAttendees.get(session.Event_vod__c) == null) {
                        eventToSessionAttendees.put(session.Event_vod__c, new Set<Id>());
                    }
                    eventToSessionAttendees.get(session.Event_vod__c).add(sessionAttendee.Id);
                }
            }
        }
        if (VOD_Utils.hasObject('Expense_Header_vod__Share')) {
            for (Expense_Header_vod__c header : headers) {
                if (eventToHeaders.get(header.Event_vod__c) == null) {
                    eventToHeaders.put(header.Event_vod__c, new Set<Id>());
                }
                eventToHeaders.get(header.Event_vod__c).add(header.Id);
            }
        }
        if (VOD_Utils.hasObject('EM_Event_Budget_vod__Share')) {
            for (EM_Event_Budget_vod__c budget : budgets) {
                if (eventToBudgets.get(budget.Event_vod__c) == null) {
                    eventToBudgets.put(budget.Event_vod__c, new Set<Id>());
                }
                eventToBudgets.get(budget.Event_vod__c).add(budget.Id);
            }
        }
        if (VOD_Utils.hasObject('EM_Event_History_vod__Share')) {
            for (EM_Event_History_vod__c history : histories) {
                if (eventToHistories.get(history.Event_vod__c) == null) {
                    eventToHistories.put(history.Event_vod__c, new Set<Id>());
                }
                eventToHistories.get(history.Event_vod__c).add(history.Id);
            }
        }
        if (VOD_Utils.hasObject('EM_Event_Material_vod__Share')) {
            for (EM_Event_Material_vod__c material : materials) {
                if (eventToMaterials.get(material.Event_vod__c) == null) {
                    eventToMaterials.put(material.Event_vod__c, new Set<Id>());
                }
                eventToMaterials.get(material.Event_vod__c).add(material.Id);
            }
        }
    }

    Set<String> newGroupNameSet = new Set<String>();
    for(EM_Event_Team_Member_vod__c member : Trigger.new) {
        if(member.Group_Name_vod__c != null) {
            newGroupNameSet.add(member.Group_Name_vod__c);
        }
    }

    Map<String, Id> newGroupNameToGroupId = new Map<String, Id>();
    for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :newGroupNameSet]) {
        newGroupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
    }

    for (EM_Event_Team_Member_vod__c member : Trigger.new) {
        if (member.Event_vod__c != null && lockedEvents.contains(member.Event_vod__c)) {
            member.addError('Event is locked');
        }
        if (Trigger.isInsert || (Trigger.isUpdate && oldTeamMember.contains(member.Id))) {
            if (VOD_Utils.hasObject('EM_Event_vod__Share')) {
                if(member.Team_Member_vod__c != null) {
                    SObject eventShare = Schema.getGlobalDescribe().get('EM_Event_vod__Share').newSObject();
                    eventShare.put('ParentId', member.Event_vod__c);
                    eventShare.put('UserOrGroupId', member.Team_Member_vod__c);
                    eventShare.put('AccessLevel', 'edit');
                    eventShare.put('RowCause', 'Event_Team_Member_vod__c');
                    eventSharesToUpsert.add(eventShare);
                } else if(member.Group_Name_vod__c != null) {
                    Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                    if(groupUserId != null) {
                        SObject eventShare = Schema.getGlobalDescribe().get('EM_Event_vod__Share').newSObject();
                        eventShare.put('ParentId', member.Event_vod__c);
                        eventShare.put('UserOrGroupId', groupUserId);
                        eventShare.put('AccessLevel', 'edit');
                        eventShare.put('RowCause', 'Event_Team_Member_vod__c');
                        eventSharesToUpsert.add(eventShare);
                    }
                }
            }

            if (VOD_Utils.hasObject('Medical_Event_vod__Share') && eventToMedicalEvent.get(member.Event_vod__c) != null) {
                if(member.Team_Member_vod__c != null) {
                    SObject medicalEventShare = Schema.getGlobalDescribe().get('Medical_Event_vod__Share').newSObject();
                    medicalEventShare.put('ParentId', eventToMedicalEvent.get(member.Event_vod__c));
                    medicalEventShare.put('UserOrGroupId', member.Team_Member_vod__c);
                    medicalEventShare.put('AccessLevel', 'edit');
                    medicalEventShare.put('RowCause', 'Event_Team_Member_vod__c');
                    medicalEventSharesToUpsert.add(medicalEventShare);
                } else if(member.Group_Name_vod__c != null) {
                    Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                    if(groupUserId != null) {
                        SObject medicalEventShare = Schema.getGlobalDescribe().get('Medical_Event_vod__Share').newSObject();
                        medicalEventShare.put('ParentId', eventToMedicalEvent.get(member.Event_vod__c));
                        medicalEventShare.put('UserOrGroupId', groupUserId);
                        medicalEventShare.put('AccessLevel', 'edit');
                        medicalEventShare.put('RowCause', 'Event_Team_Member_vod__c');
                        medicalEventSharesToUpsert.add(medicalEventShare);
                    }
                }
            }

            if (VOD_Utils.hasObject('EM_Attendee_vod__Share') && eventToAttendees.get(member.Event_vod__c) != null) {
                for (Id attendeeId : eventToAttendees.get(member.Event_vod__c)) {
                    if(member.Team_Member_vod__c != null) {
                        SObject attendeeShare = Schema.getGlobalDescribe().get('EM_Attendee_vod__Share').newSObject();
                        attendeeShare.put('ParentId', attendeeId);
                        attendeeShare.put('UserOrGroupId', member.Team_Member_vod__c);
                        attendeeShare.put('AccessLevel', 'edit');
                        attendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                        attendeeSharesToUpsert.add(attendeeShare);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            SObject attendeeShare = Schema.getGlobalDescribe().get('EM_Attendee_vod__Share').newSObject();
                            attendeeShare.put('ParentId', attendeeId);
                            attendeeShare.put('UserOrGroupId', groupUserId);
                            attendeeShare.put('AccessLevel', 'edit');
                            attendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                            attendeeSharesToUpsert.add(attendeeShare);
                        }
                    }
                }
            }

            if (VOD_Utils.hasObject('EM_Event_Speaker_vod__Share') && eventToSpeakers.get(member.Event_vod__c) != null) {
                for (Id speakerId : eventToSpeakers.get(member.Event_vod__c)) {
                    if(member.Team_Member_vod__c != null) {
                        SObject speakerShare = Schema.getGlobalDescribe().get('EM_Event_Speaker_vod__Share').newSObject();
                        speakerShare.put('ParentId', speakerId);
                        speakerShare.put('UserOrGroupId', member.Team_Member_vod__c);
                        speakerShare.put('AccessLevel', 'edit');
                        speakerShare.put('RowCause', 'Event_Team_Member_vod__c');
                        speakerSharesToUpsert.add(speakerShare);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            SObject speakerShare = Schema.getGlobalDescribe().get('EM_Event_Speaker_vod__Share').newSObject();
                            speakerShare.put('ParentId', speakerId);
                            speakerShare.put('UserOrGroupId', groupUserId);
                            speakerShare.put('AccessLevel', 'edit');
                            speakerShare.put('RowCause', 'Event_Team_Member_vod__c');
                            speakerSharesToUpsert.add(speakerShare);
                        }
                    }
                }
            }

            if (VOD_Utils.hasObject('EM_Expense_Estimate_vod__Share') && eventToExpenses.get(member.Event_vod__c) != null) {
                for (Id expenseId : eventToExpenses.get(member.Event_vod__c)) {
                    if(member.Team_Member_vod__c != null) {
                        SObject expenseShare = Schema.getGlobalDescribe().get('EM_Expense_Estimate_vod__Share').newSObject();
                        expenseShare.put('ParentId', expenseId);
                        expenseShare.put('UserOrGroupId', member.Team_Member_vod__c);
                        expenseShare.put('AccessLevel', 'edit');
                        expenseShare.put('RowCause', 'Event_Team_Member_vod__c');
                        estimateSharesToUpsert.add(expenseShare);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            SObject expenseShare = Schema.getGlobalDescribe().get('EM_Expense_Estimate_vod__Share').newSObject();
                            expenseShare.put('ParentId', expenseId);
                            expenseShare.put('UserOrGroupId', groupUserId);
                            expenseShare.put('AccessLevel', 'edit');
                            expenseShare.put('RowCause', 'Event_Team_Member_vod__c');
                            estimateSharesToUpsert.add(expenseShare);
                        }
                    }
                }
            }

            if (VOD_Utils.hasObject('EM_Event_Session_vod__Share') && eventToSessions.get(member.Event_vod__c) != null) {
                for (Id sessionId : eventToSessions.get(member.Event_vod__c)) {
                    if(member.Team_Member_vod__c != null) {
                        SObject sessionShare = Schema.getGlobalDescribe().get('EM_Event_Session_vod__Share').newSObject();
                        sessionShare.put('ParentId', sessionId);
                        sessionShare.put('UserOrGroupId', member.Team_Member_vod__c);
                        sessionShare.put('AccessLevel', 'edit');
                        sessionShare.put('RowCause', 'Event_Team_Member_vod__c');
                        sessionSharesToUpsert.add(sessionShare);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            SObject sessionShare = Schema.getGlobalDescribe().get('EM_Event_Session_vod__Share').newSObject();
                            sessionShare.put('ParentId', sessionId);
                            sessionShare.put('UserOrGroupId', groupUserId);
                            sessionShare.put('AccessLevel', 'edit');
                            sessionShare.put('RowCause', 'Event_Team_Member_vod__c');
                            sessionSharesToUpsert.add(sessionShare);
                        }
                    }
                }
            }

            if (VOD_Utils.hasObject('EM_Event_Session_Attendee_vod__Share') && eventToSessionAttendees.get(member.Event_vod__c) != null) {
                for (Id sessionAttendeeId : eventToSessionAttendees.get(member.Event_vod__c)) {
                    if(member.Team_Member_vod__c != null) {
                        SObject sessionAttendeeShare = Schema.getGlobalDescribe().get('EM_Event_Session_vod__Share').newSObject();
                        sessionAttendeeShare.put('ParentId', sessionAttendeeId);
                        sessionAttendeeShare.put('UserOrGroupId', member.Team_Member_vod__c);
                        sessionAttendeeShare.put('AccessLevel', 'edit');
                        sessionAttendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                        sessionAttendeeSharesToUpsert.add(sessionAttendeeShare);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            SObject sessionAttendeeShare = Schema.getGlobalDescribe().get('EM_Event_Session_vod__Share').newSObject();
                            sessionAttendeeShare.put('ParentId', sessionAttendeeId);
                            sessionAttendeeShare.put('UserOrGroupId', groupUserId);
                            sessionAttendeeShare.put('AccessLevel', 'edit');
                            sessionAttendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                            sessionAttendeeSharesToUpsert.add(sessionAttendeeShare);
                        }
                    }
                }
            }

            if (VOD_Utils.hasObject('Expense_Header_vod__Share') && eventToHeaders.get(member.Event_vod__c) != null) {
                for (Id headerId : eventToHeaders.get(member.Event_vod__c)) {
                    if(member.Team_Member_vod__c != null) {
                        SObject headerShare = Schema.getGlobalDescribe().get('Expense_Header_vod__Share').newSObject();
                        headerShare.put('ParentId', headerId);
                        headerShare.put('UserOrGroupId', member.Team_Member_vod__c);
                        headerShare.put('AccessLevel', 'edit');
                        headerShare.put('RowCause', 'Event_Team_Member_vod__c');
                        headerSharesToUpsert.add(headerShare);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            SObject headerShare = Schema.getGlobalDescribe().get('Expense_Header_vod__Share').newSObject();
                            headerShare.put('ParentId', headerId);
                            headerShare.put('UserOrGroupId', groupUserId);
                            headerShare.put('AccessLevel', 'edit');
                            headerShare.put('RowCause', 'Event_Team_Member_vod__c');
                            headerSharesToUpsert.add(headerShare);
                        }
                    }
                }
            }

            if (VOD_Utils.hasObject('EM_Event_Budget_vod__Share') && eventToBudgets.get(member.Event_vod__c) != null) {
                for (Id budgetId : eventToBudgets.get(member.Event_vod__c)) {
                    if(member.Team_Member_vod__c != null) {
                        SObject budgetShare = Schema.getGlobalDescribe().get('EM_Event_Budget_vod__Share').newSObject();
                        budgetShare.put('ParentId', budgetId);
                        budgetShare.put('UserOrGroupId', member.Team_Member_vod__c);
                        budgetShare.put('AccessLevel', 'edit');
                        budgetShare.put('RowCause', 'Event_Team_Member_vod__c');
                        budgetSharesToUpsert.add(budgetShare);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            SObject budgetShare = Schema.getGlobalDescribe().get('EM_Event_Budget_vod__Share').newSObject();
                            budgetShare.put('ParentId', budgetId);
                            budgetShare.put('UserOrGroupId', groupUserId);
                            budgetShare.put('AccessLevel', 'edit');
                            budgetShare.put('RowCause', 'Event_Team_Member_vod__c');
                            budgetSharesToUpsert.add(budgetShare);
                        }
                    }
                }
            }

            if (VOD_Utils.hasObject('EM_Event_History_vod__Share') && eventToHistories.get(member.Event_vod__c) != null) {
                for (Id historyId : eventToHistories.get(member.Event_vod__c)) {
                    if(member.Team_Member_vod__c != null) {
                        SObject historyShare = Schema.getGlobalDescribe().get('EM_Event_History_vod__Share').newSObject();
                        historyShare.put('ParentId', historyId);
                        historyShare.put('UserOrGroupId', member.Team_Member_vod__c);
                        historyShare.put('AccessLevel', 'edit');
                        historyShare.put('RowCause', 'Event_Team_Member_vod__c');
                        historySharesToUpsert.add(historyShare);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            SObject historyShare = Schema.getGlobalDescribe().get('EM_Event_History_vod__Share').newSObject();
                            historyShare.put('ParentId', historyId);
                            historyShare.put('UserOrGroupId', groupUserId);
                            historyShare.put('AccessLevel', 'edit');
                            historyShare.put('RowCause', 'Event_Team_Member_vod__c');
                            historySharesToUpsert.add(historyShare);
                        }
                    }
                }
            }

            if (VOD_Utils.hasObject('EM_Event_Material_vod__Share') && eventToMaterials.get(member.Event_vod__c) != null) {
                for (Id materialId : eventToMaterials.get(member.Event_vod__c)) {
                    if(member.Team_Member_vod__c != null) {
                        SObject materialShare = Schema.getGlobalDescribe().get('EM_Event_Material_vod__Share').newSObject();
                        materialShare.put('ParentId', materialId);
                        materialShare.put('UserOrGroupId', member.Team_Member_vod__c);
                        materialShare.put('AccessLevel', 'edit');
                        materialShare.put('RowCause', 'Event_Team_Member_vod__c');
                        materialSharesToUpsert.add(materialShare);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            SObject materialShare = Schema.getGlobalDescribe().get('EM_Event_Material_vod__Share').newSObject();
                            materialShare.put('ParentId', materialId);
                            materialShare.put('UserOrGroupId', groupUserId);
                            materialShare.put('AccessLevel', 'edit');
                            materialShare.put('RowCause', 'Event_Team_Member_vod__c');
                            materialSharesToUpsert.add(materialShare);
                        }
                    }
                }
            }
        }
    }

    List<SObject> toUpsert = new List<SObject>(); 
    
    toUpsert.addAll(eventSharesToUpsert);
    toUpsert.addAll(medicalEventSharesToUpsert);
    toUpsert.addAll(attendeeSharesToUpsert);
    toUpsert.addAll(speakerSharesToUpsert);
    toUpsert.addAll(estimateSharesToUpsert);
    toUpsert.addAll(sessionSharesToUpsert);
    toUpsert.addAll(sessionAttendeeSharesToUpsert);
    toUpsert.addAll(headerSharesToUpsert);
    toUpsert.addAll(budgetSharesToUpsert);
    toUpsert.addAll(historySharesToUpsert);
    
    //Can only upsert 10 different types of objects so we have to upsert twice
    if(!toUpsert.isEmpty()) {
		Database.insert(toUpsert, false);        
    }
        
    toUpsert = new List<SObject>(); 
    
	toUpsert.addAll(materialSharestoUpsert);
    
    if(!toUpsert.isEmpty()) {
    	Database.insert(toUpsert, false);    
    }         
}