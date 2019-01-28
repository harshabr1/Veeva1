trigger VOD_EXPENSE_ESTIMATE_AFTER_INSERT_UPDATE on EM_Expense_Estimate_vod__c (after insert, after update) {
    if (VOD_Utils.hasObject('EM_Expense_Estimate_vod__Share')) {
        List<SObject> newShares = new List<SObject>();
        Set<Id> eventIds = new Set<Id>();
        for (EM_Expense_Estimate_vod__c expense : Trigger.new) {
            eventIds.add(expense.Event_vod__c);
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
            Map<Id, EM_Expense_Estimate_vod__c> expenseMap = new Map<Id, EM_Expense_Estimate_vod__c>();
            for (EM_Expense_Estimate_vod__c expense : Trigger.new) {
                if (expense.Event_vod__c != Trigger.oldMap.get(expense.Id).Event_vod__c) {
                    expenseMap.put(expense.Id, expense);
                }
            }
            if (!expenseMap.isEmpty()) {
                Set<Id> expenseSet = expenseMap.keySet();
                List<SObject> expenseShares = Database.query('SELECT Id FROM EM_Expense_Estimate_vod__Share WHERE ParentId IN : expenseSet');
                List<Database.DeleteResult> results = Database.delete(expenseShares, false);
                for (Database.DeleteResult result: results) {
                    if (!result.isSuccess()) {
                     system.debug('Insert error: ' + result.getErrors()[0]);
                   }
                }
            }

            for (Id expenseId : expenseMap.keySet()) {
                EM_Expense_Estimate_vod__c expense = expenseMap.get(expenseId);
                if (eventToMembers.get(expense.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(expense.Event_vod__c)) {
                        SObject expenseShare = Schema.getGlobalDescribe().get('EM_Expense_Estimate_vod__Share').newSObject();
                        expenseShare.put('ParentId', expenseId);
                        expenseShare.put('UserOrGroupId', memberId);
                        expenseShare.put('AccessLevel', 'edit');
                        expenseShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(expenseShare);
                    }
                }
            }
        } else {
            for (EM_Expense_Estimate_vod__c expense : Trigger.new) {
                if (eventToMembers.get(expense.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(expense.Event_vod__c)) {
                        SObject expenseShare = Schema.getGlobalDescribe().get('EM_Expense_Estimate_vod__Share').newSObject();
                        expenseShare.put('ParentId', expense.Id);
                        expenseShare.put('UserOrGroupId', memberId);
                        expenseShare.put('AccessLevel', 'edit');
                        expenseShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(expenseShare);
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