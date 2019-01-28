trigger VOD_EM_EVENT_HISTORY_UPSERT on EM_Event_History_vod__c (before insert, before update) {
 	List<EM_Event_Team_Member_vod__c> emTeamMembers = new List<EM_Event_Team_Member_vod__c>();
    boolean hasTeamMemberTypeFLS = Schema.SObjectType.EM_Event_Team_Member_vod__c.fields.Team_Member_Type_vod__c.isUpdateable();

    Set<Id> eventIds = new Set<Id>();
    for (EM_Event_History_vod__c history : Trigger.new) {
        eventIds.add(history.Event_vod__c);
    }
    List<EM_Event_vod__c> events = [SELECT Id, Override_Lock_vod__c, Lock_vod__c, OwnerId, (SELECT Id, Event_vod__c, Role_vod__c, Team_Member_vod__c, Group_Name_vod__c FROM EM_Event_Team_Member_vod__r)
                                    FROM EM_Event_vod__c
                                    WHERE Id IN : eventIds];
    Map<Id, List<EM_Event_Team_Member_vod__c>> eventToTeamMembers = new Map<Id, List<EM_Event_Team_Member_vod__c>>();
    Set<Id> lockedEvents = new Set<Id>();
    Map<Id, EM_Event_vod__c> eventsMap = new Map<Id, EM_Event_vod__c>();
    for (EM_Event_vod__c event : events) {
        if (Trigger.isUpdate && VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
        eventsMap.put(event.Id, event);
        if (event.EM_Event_Team_Member_vod__r != null) {
            eventToTeamMembers.put(event.Id, new List<EM_Event_Team_Member_vod__c>());
            for (EM_Event_Team_Member_vod__c teamMember : event.EM_Event_Team_Member_vod__r) {
                eventToTeamMembers.get(event.Id).add(teamMember);
            }
        }
    }
    for(EM_Event_history_vod__c history: Trigger.new) {
        if (history.Event_vod__c != null) {
            if(history.Override_Lock_vod__c == true) {
                history.Override_Lock_vod__c = false;
            } else if (history.Event_vod__c != null && lockedEvents.contains(history.Event_vod__c)) {
                history.addError('Event is locked');
            }

            boolean duplicate = false;
            EM_Event_Team_Member_vod__c teamMember;
            EM_Event_Team_Member_vod__c oldTeamMember = null;
            if(history.Next_Approver_Group_vod__c != null) {
                if (eventToTeamMembers.get(history.Event_vod__c) != null) {
                    for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                        if (existingMember.Group_Name_vod__c == history.Next_Approver_Group_vod__c) {
                            if(history.Next_Approver_Role_vod__c != null  && existingMember.Role_vod__c != history.Next_Approver_Role_vod__c) {
                                oldTeamMember = existingMember;
                                oldTeamMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                            } else {
                            	duplicate = true;
                            }
                            break;
                        }
                    }
                }
                if(oldTeamMember != null) {
                    emTeamMembers.add(oldTeamMember);
                } else if (!duplicate) {
                    String roleValue = null;
                    if(history.Next_Approver_Role_vod__c == null) {
                        roleValue = 'Approver_vod';
                    } else {
                        roleValue = history.Next_Approver_Role_vod__c;
                    }
                    teamMember = new EM_Event_Team_Member_vod__c(
                        Event_vod__c = history.Event_vod__c,
                        Role_vod__c = roleValue,
                        Group_Name_vod__c = history.Next_Approver_Group_vod__c
                    );
                    if (hasTeamMemberTypeFLS) {
                        teamMember.put('Team_Member_Type_vod__c', 'Group_vod');
                    }
                    emTeamMembers.add(teamMember);
                }
            } else if(history.Next_Approver_vod__c != null) {
                if (eventToTeamMembers.get(history.Event_vod__c) != null) {
                    for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                        if (existingMember.Team_Member_vod__c == history.Next_Approver_vod__c) {
                            if(history.Next_Approver_Role_vod__c != null  && existingMember.Role_vod__c != history.Next_Approver_Role_vod__c) {
                                oldTeamMember = existingMember;
                                oldTeamMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                            } else {
                            	duplicate = true;
                            }
                            break;
                        }
                    }
                }
                if(oldTeamMember != null) {
                    emTeamMembers.add(oldTeamMember);
                } else if (!duplicate) {
                    String roleValue = null;
                    if(history.Next_Approver_Role_vod__c == null) {
                        roleValue = 'Approver_vod';
                    } else {
                        roleValue = history.Next_Approver_Role_vod__c;
                    }
                    teamMember = new EM_Event_Team_Member_vod__c(
                        Event_vod__c = history.Event_vod__c,
                        Role_vod__c = roleValue,
                        Team_Member_vod__c = history.Next_Approver_vod__c
                     );
                    if (hasTeamMemberTypeFLS) {
                        teamMember.put('Team_Member_Type_vod__c', 'User_vod');
                    }
                    emTeamMembers.add(teamMember);
                }
            } else if (history.Approver_IDs_vod__c != null) {
            	List<EM_Event_Team_Member_vod__c> oldTeamMembers = new List<EM_Event_Team_Member_vod__c>();
                Set<String> approverIds = new Set<String>(history.Approver_IDs_vod__c.split(','));
            	if (eventToTeamMembers.get(history.Event_vod__c) != null) {
                    for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                        if (approverIds.contains(existingMember.Team_Member_vod__c)) {
                            approverIds.remove(existingMember.Team_Member_vod__c);
                            if(history.Next_Approver_Role_vod__c != null  && existingMember.Role_vod__c != history.Next_Approver_Role_vod__c) {
                                existingMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                                oldTeamMembers.add(existingMember);
                            }
                        }
                    }
                }
                emTeamMembers.addAll(oldTeamMembers);
                String roleValue = null;
                if(history.Next_Approver_Role_vod__c == null) {
                    roleValue = 'Approver_vod';
                } else {
                    roleValue = history.Next_Approver_Role_vod__c;
                }
                for(String approverId: approverIds) {
                    EM_Event_Team_Member_vod__c newTeamMember = new EM_Event_Team_Member_vod__c(
                        Event_vod__c = history.Event_vod__c,
                        Role_vod__c = roleValue,
                        Team_Member_vod__c = approverId
                    );
                    if (hasTeamMemberTypeFLS) {
                        if (approverId.startsWith(Schema.SObjectType.User.getKeyPrefix())) {
                        	newTeamMember.put('Team_Member_Type_vod__c', 'User_vod');
                        } else {
                        	newTeamMember.put('Team_Member_Type_vod__c', 'Group_vod');
                        }
                    }
                	emTeamMembers.add(newTeamMember);
                }


            } else if(history.Ending_Status_vod__c == null) {
                EM_Event_vod__c historyEvent = eventsMap.get(history.Event_vod__c);
                Id userId;
                if(historyEvent != null) {
                    userId = historyEvent.OwnerId;
                }
                if (eventToTeamMembers.get(history.Event_vod__c) != null && userId != null) {
                    for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                        if (existingMember.Team_Member_vod__c == userId) {
                            duplicate = true;
                            break;
                        }
                    }
                }
                if (!duplicate && userId != null) {
					teamMember = new EM_Event_Team_Member_vod__c(
                        Event_vod__c = history.Event_vod__c,
                        Team_Member_vod__c = userId
                    );
                    if (hasTeamMemberTypeFLS) {
                        teamMember.put('Team_Member_Type_vod__c', 'User_vod');
                    }

                    if(history.Next_Approver_Role_vod__c != null) {
                        teamMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                    }

                    emTeamMembers.add(teamMember);
                }
            }
        }
    }
    if (emTeamMembers.size() > 0) {
	    upsert emTeamMembers;
    }
}