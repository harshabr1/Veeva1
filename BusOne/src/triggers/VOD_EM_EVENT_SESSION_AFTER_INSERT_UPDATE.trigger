trigger VOD_EM_EVENT_SESSION_AFTER_INSERT_UPDATE on EM_Event_Session_vod__c (after insert, after update) {
    if (VOD_Utils.hasObject('EM_Event_Session_vod__Share')) {
        List<SObject> newShares = new List<SObject>();
        Set<Id> eventIds = new Set<Id>();
        for (EM_Event_Session_vod__c session : Trigger.new) {
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

        List<EM_Event_Team_Member_vod__c> members = [SELECT Id, Event_vod__c, Team_Member_vod__c, Group_Name_vod__c FROM EM_Event_Team_Member_vod__c WHERE Event_vod__c IN : eventIds];
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

        if (Trigger.isUpdate) {
            Map<Id, EM_Event_Session_vod__c> sessionMap = new Map<Id, EM_Event_Session_vod__c>();
            for (EM_Event_Session_vod__c session : Trigger.new) {
                if (session.Event_vod__c != Trigger.oldMap.get(session.Id).Event_vod__c) {
                    sessionMap.put(session.Id, session);
                }
            }
            if (!sessionMap.isEmpty()) {
                Set<Id> sessionSet = sessionMap.keySet();
                List<SObject> sessionShares = Database.query('SELECT Id FROM EM_Event_Session_vod__Share WHERE ParentId IN : sessionSet');
                List<Database.DeleteResult> results = Database.delete(sessionShares, false);
                for (Database.DeleteResult result: results) {
                    if (!result.isSuccess()) {
                     system.debug('Insert error: ' + result.getErrors()[0]);
                   }
                }
            }

            for (Id sessionId : sessionMap.keySet()) {
                EM_Event_Session_vod__c session = sessionMap.get(sessionId);
                if (eventToMembers.get(session.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(session.Event_vod__c)) {
                        SObject sessionShare = Schema.getGlobalDescribe().get('EM_Event_Session_vod__Share').newSObject();
                        sessionShare.put('ParentId', sessionId);
                        sessionShare.put('UserOrGroupId', memberId);
                        sessionShare.put('AccessLevel', 'edit');
                        sessionShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(sessionShare);
                    }
                }
            }
        } else {
            for (EM_Event_Session_vod__c session : Trigger.new) {
                if (eventToMembers.get(session.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(session.Event_vod__c)) {
                        SObject sessionShare = Schema.getGlobalDescribe().get('EM_Event_Session_vod__Share').newSObject();
                        sessionShare.put('ParentId', session.Id);
                        sessionShare.put('UserOrGroupId', memberId);
                        sessionShare.put('AccessLevel', 'edit');
                        sessionShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(sessionShare);
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