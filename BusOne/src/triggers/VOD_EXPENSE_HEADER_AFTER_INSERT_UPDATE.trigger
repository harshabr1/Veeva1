trigger VOD_EXPENSE_HEADER_AFTER_INSERT_UPDATE on Expense_Header_vod__c (after insert, after update) {
    if (VOD_Utils.hasObject('Expense_Header_vod__Share')) {
        List<SObject> newShares = new List<SObject>();
        Set<Id> eventIds = new Set<Id>();
        for (Expense_Header_vod__c header : Trigger.new) {
            eventIds.add(header.Event_vod__c);
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
            Map<Id, Expense_Header_vod__c> headerMap = new Map<Id, Expense_Header_vod__c>();
            for (Expense_Header_vod__c header : Trigger.new) {
                if (header.Event_vod__c != Trigger.oldMap.get(header.Id).Event_vod__c) {
                    headerMap.put(header.Id, header);
                }
            }
            if (!headerMap.isEmpty()) {
                Set<Id> headerSet = headerMap.keySet();
                List<SObject> headerShares = Database.query('SELECT Id FROM Expense_Header_vod__Share WHERE ParentId IN : headerSet');
                List<Database.DeleteResult> results = Database.delete(headerShares, false);
                for (Database.DeleteResult result: results) {
                    if (!result.isSuccess()) {
                     system.debug('Insert error: ' + result.getErrors()[0]);
                   }
                }
            }

            for (Id headerId : headerMap.keySet()) {
                Expense_Header_vod__c header = headerMap.get(headerId);
                if (eventToMembers.get(header.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(header.Event_vod__c)) {
                        SObject headerShare = Schema.getGlobalDescribe().get('Expense_Header_vod__Share').newSObject();
                        headerShare.put('ParentId', headerId);
                        headerShare.put('UserOrGroupId', memberId);
                        headerShare.put('AccessLevel', 'edit');
                        headerShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(headerShare);
                    }
                }
            }
        } else {
            for (Expense_Header_vod__c header : Trigger.new) {
                if (eventToMembers.get(header.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(header.Event_vod__c)) {
                        SObject headerShare = Schema.getGlobalDescribe().get('Expense_Header_vod__Share').newSObject();
                        headerShare.put('ParentId', header.Id);
                        headerShare.put('UserOrGroupId', memberId);
                        headerShare.put('AccessLevel', 'edit');
                        headerShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(headerShare);
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

    Map<String, EM_Event_vod__c> eventsMap = new Map<String, EM_Event_vod__c>();
    if(Trigger.isUpdate) {
        for(Expense_Header_vod__c newHeader: Trigger.new) {
            Expense_Header_vod__c oldHeader = Trigger.oldMap.get(newHeader.Id);
            if(oldHeader.Concur_Status_vod__c != newHeader.Concur_Status_vod__c) {
                if(eventsMap.get(newHeader.Event_vod__c) == null) {
                    EM_Event_vod__c event = new EM_Event_vod__c(Id = newHeader.Event_vod__c,
                        										Failed_Expense_vod__c = true,
                                                                Override_Lock_vod__c = true);
                    eventsMap.put(newHeader.Event_vod__c, event);
                }
            }
        }
    }

    if(eventsMap.values() != null) {
        update eventsMap.values();
    }
}