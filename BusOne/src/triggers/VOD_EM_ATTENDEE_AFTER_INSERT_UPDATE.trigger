trigger VOD_EM_ATTENDEE_AFTER_INSERT_UPDATE on EM_Attendee_vod__c (after insert, after update) {
    if (VOD_Utils.hasObject('EM_Attendee_vod__Share')) {
        SObjectType attendeeShareType = Schema.getGlobalDescribe().get('EM_Attendee_vod__Share');
        List<SObject> newShares = new List<SObject>();
        Set<Id> eventIds = new Set<Id>();
        for (EM_Attendee_vod__c attendee : Trigger.new) {
            if(attendee.Event_vod__c != null) {
                eventIds.add(attendee.Event_vod__c);
            }
        }

        Set<String> groupNameSet = new Set<String>();
        List<EM_Event_Team_Member_vod__c> members = [SELECT Id, Event_vod__c, Team_Member_vod__c, Group_Name_vod__c FROM EM_Event_Team_Member_vod__c WHERE Event_vod__c IN : eventIds];
        for(EM_Event_Team_Member_vod__c member : members) {
            if(member.Group_Name_vod__c != null) {
            	groupNameSet.add(member.Group_Name_vod__c);
            }
        }

        Map<String, Id> groupNameToGroupId = new Map<String, Id>();
        for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNameSet]) {
            groupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
        }


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
            Map<Id, EM_Attendee_vod__c> attendeeMap = new Map<Id, EM_Attendee_vod__c>();
            for (EM_Attendee_vod__c attendee : Trigger.new) {
                if (attendee.Event_vod__c != Trigger.oldMap.get(attendee.Id).Event_vod__c) {
                    attendeeMap.put(attendee.Id, attendee);
                }
            }
            if (!attendeeMap.isEmpty()) {
                Set<Id> attendeeSet = attendeeMap.keySet();
                List<SObject> attendeeShares = Database.query('SELECT Id FROM EM_Attendee_vod__Share WHERE ParentId IN : attendeeSet');
                List<Database.DeleteResult> results = Database.delete(attendeeShares, false);
                for (Database.DeleteResult result: results) {
                    if (!result.isSuccess()) {
                     system.debug('Insert error: ' + result.getErrors()[0]);
                   }
                }
            }

            for (Id attendeeId : attendeeMap.keySet()) {
                EM_Attendee_vod__c attendee = attendeeMap.get(attendeeId);
                if (eventToMembers.get(attendee.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(attendee.Event_vod__c)) {
                        SObject attendeeShare = attendeeShareType.newSObject();
                        attendeeShare.put('ParentId', attendeeId);
                        attendeeShare.put('UserOrGroupId', memberId);
                        attendeeShare.put('AccessLevel', 'edit');
                        attendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(attendeeShare);
                    }
                }
            }
        } else {
            for (EM_Attendee_vod__c attendee : Trigger.new) {
                if (eventToMembers.get(attendee.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(attendee.Event_vod__c)) {
                        SObject attendeeShare = attendeeShareType.newSObject();
                        attendeeShare.put('ParentId', attendee.Id);
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