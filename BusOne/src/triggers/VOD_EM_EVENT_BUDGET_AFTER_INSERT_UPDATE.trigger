trigger VOD_EM_EVENT_BUDGET_AFTER_INSERT_UPDATE on EM_Event_Budget_vod__c (after insert, after update) {
    if (VOD_Utils.hasObject('EM_Event_Budget_vod__Share')) {
        List<SObject> newShares = new List<SObject>();
        Set<Id> eventIds = new Set<Id>();
        for (EM_Event_Budget_vod__c budget : Trigger.new) {
            eventIds.add(budget.Event_vod__c);
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
            Map<Id, EM_Event_Budget_vod__c> budgetMap = new Map<Id, EM_Event_Budget_vod__c>();
            for (EM_Event_Budget_vod__c budget : Trigger.new) {
                if (budget.Event_vod__c != Trigger.oldMap.get(budget.Id).Event_vod__c) {
                    budgetMap.put(budget.Id, budget);
                }
            }
            if (!budgetMap.isEmpty()) {
                Set<Id> budgetSet = budgetMap.keySet();
                List<SObject> budgetShares = Database.query('SELECT Id FROM EM_Event_Budget_vod__Share WHERE ParentId IN : budgetSet');
                List<Database.DeleteResult> results = Database.delete(budgetShares, false);
                for (Database.DeleteResult result: results) {
                    if (!result.isSuccess()) {
                        system.debug('Insert error: ' + result.getErrors()[0]);
                    }
                }
            }

            for (Id budgetId : budgetMap.keySet()) {
                EM_Event_Budget_vod__c budget = budgetMap.get(budgetId);
                if (eventToMembers.get(budget.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(budget.Event_vod__c)) {
                        SObject budgetShare = Schema.getGlobalDescribe().get('EM_Event_Budget_vod__Share').newSObject();
                        budgetShare.put('ParentId', budgetId);
                        budgetShare.put('UserOrGroupId', memberId);
                        budgetShare.put('AccessLevel', 'edit');
                        budgetShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(budgetShare);
                    }
                }
            }
        } else {
            for (EM_Event_Budget_vod__c budget : Trigger.new) {
                if (eventToMembers.get(budget.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(budget.Event_vod__c)) {
                        SObject budgetShare = Schema.getGlobalDescribe().get('EM_Event_Budget_vod__Share').newSObject();
                        budgetShare.put('ParentId', budget.Id);
                        budgetShare.put('UserOrGroupId', memberId);
                        budgetShare.put('AccessLevel', 'edit');
                        budgetShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(budgetShare);
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