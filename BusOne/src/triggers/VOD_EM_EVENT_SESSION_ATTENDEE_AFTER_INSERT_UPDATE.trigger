trigger VOD_EM_EVENT_SESSION_ATTENDEE_AFTER_INSERT_UPDATE on EM_Event_Session_Attendee_vod__c (after insert, after update) {
    if (VOD_Utils.hasObject('EM_Event_Session_Attendee_vod__Share')) {
        List<SObject> newShares = new List<SObject>();
        Set<Id> sessionIds = new Set<Id>();
        for (EM_Event_Session_Attendee_vod__c attendee : Trigger.new) {
            sessionIds.add(attendee.Event_Session_vod__c);
        }

        Set<Id> eventIds = new Set<Id>();
        for(EM_Event_Session_vod__c session : [SELECT Event_vod__c FROM EM_Event_Session_vod__c WHERE Id IN : sessionIds]) {
            eventIds.add(session.Event_vod__c);
        }

        Set<String> groupNameSet = new Set<String>();
        for(EM_Event_Team_Member_vod__c member : [SELECT Group_Name_vod__c FROM EM_Event_Team_Member_vod__c WHERE Event_vod__c IN :eventIds AND Group_Name_vod__c != null]) {
            groupNameSet.add(member.Group_Name_vod__c);
        }

        Map<String, Id> groupNameToGroupId = new Map<String, Id>();
        for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNameSet]) {
            groupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
        }

        List<EM_Event_Team_Member_vod__c> members = [SELECT Id, Event_vod__c, Team_Member_vod__c, Group_Name_vod__c FROM EM_Event_Team_Member_vod__c
                                                     WHERE Event_vod__c IN :eventIds];
        Map<Id, Set<Id>> eventToMembers = new Map<Id, Set<Id>>();
        for (EM_Event_Team_Member_vod__c member : members) {
            if (eventToMembers.get(member.Event_vod__c) == null) {
                eventToMembers.put(member.Event_vod__c, new Set<Id>());
            }
            if(member.Team_Member_vod__c != null) {
                eventToMembers.get(member.Event_vod__c).add(member.Team_Member_vod__c);
            } else if(member.Group_Name_vod__c != null) {
                Id groupUserId = groupNameToGroupId.get(member.Group_Name_vod__c);
                if(groupUserId != null) {
                    eventToMembers.get(member.Event_vod__c).add(groupUserId);
                }
            }
        }
        Map<Id, EM_Event_Session_Attendee_vod__c> attendeeMap = new Map<Id,EM_Event_Session_Attendee_vod__c>([SELECT Id, Event_Session_vod__r.Event_vod__c
                                                                                                              FROM EM_Event_Session_Attendee_vod__c
                                                                                                              WHERE Id IN : Trigger.newMap.keySet()]);

        if (Trigger.isUpdate) {
            Map<Id, EM_Event_Session_Attendee_vod__c> changedAttendeeMap = new Map<Id, EM_Event_Session_Attendee_vod__c>();
            for (EM_Event_Session_Attendee_vod__c sessionAttendee : Trigger.new) {
                if (sessionAttendee.Event_Session_vod__c != Trigger.oldMap.get(sessionAttendee.Id).Event_Session_vod__c) {
                    changedAttendeeMap.put(sessionAttendee.Id, sessionAttendee);
                }
            }
            if (!changedAttendeeMap.isEmpty()) {
                Set<Id> sessionAttendeeSet = changedAttendeeMap.keySet();
                List<SObject> sessionAttendeeShares = Database.query('SELECT Id FROM EM_Event_Session_Attendee_vod__Share WHERE ParentId IN : sessionAttendeeSet');
                List<Database.DeleteResult> results = Database.delete(sessionAttendeeShares, false);
                for (Database.DeleteResult result: results) {
                    if (!result.isSuccess()) {
                     system.debug('Insert error: ' + result.getErrors()[0]);
                   }
                }
            }

            for (Id sessionAttendeeId : changedAttendeeMap.keySet()) {
                EM_Event_Session_Attendee_vod__c attendee = attendeeMap.get(sessionAttendeeId);
                if (eventToMembers.get(attendee.Event_Session_vod__r.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(attendee.Event_Session_vod__r.Event_vod__c)) {
                        SObject attendeeShare = Schema.getGlobalDescribe().get('EM_Event_Session_Attendee_vod__Share').newSObject();
                        attendeeShare.put('ParentId', sessionAttendeeId);
                        attendeeShare.put('UserOrGroupId', memberId);
                        attendeeShare.put('AccessLevel', 'edit');
                        attendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(attendeeShare);
                    }
                }
            }
        } else {
            for (Id sessionAttendeeId : attendeeMap.keySet()) {
                EM_Event_Session_Attendee_vod__c attendee = attendeeMap.get(sessionAttendeeId);
                if (eventToMembers.get(attendee.Event_Session_vod__r.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(attendee.Event_Session_vod__r.Event_vod__c)) {
                        SObject attendeeShare = Schema.getGlobalDescribe().get('EM_Event_Session_Attendee_vod__Share').newSObject();
                        attendeeShare.put('ParentId', sessionAttendeeId);
                        attendeeShare.put('UserOrGroupId', memberId);
                        attendeeShare.put('AccessLevel', 'edit');
                        attendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(attendeeShare);
                    }
                }
            }
        }
        List<Database.SaveResult> results = Database.insert(newShares, false);
        for (Database.SaveResult result: results) {
            if (!result.isSuccess()) {
             system.debug('Insert error: ' + result.getErrors()[0]);
           }
        }
    }
}