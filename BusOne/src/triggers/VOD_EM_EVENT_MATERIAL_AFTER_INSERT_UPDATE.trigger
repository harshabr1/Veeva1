trigger VOD_EM_EVENT_MATERIAL_AFTER_INSERT_UPDATE on EM_Event_Material_vod__c (after insert, after update) {
    if (VOD_Utils.hasObject('EM_Event_Material_vod__Share')) {
        List<SObject> newShares = new List<SObject>();
        Set<Id> eventIds = new Set<Id>();
        for (EM_Event_Material_vod__c material : Trigger.new) {
            eventIds.add(material.Event_vod__c);
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
            Map<Id, EM_Event_Material_vod__c> materialMap = new Map<Id, EM_Event_Material_vod__c>();
            for (EM_Event_Material_vod__c material : Trigger.new) {
                if (material.Event_vod__c != Trigger.oldMap.get(material.Id).Event_vod__c) {
                    materialMap.put(material.Id, material);
                }
            }
            if (!materialMap.isEmpty()) {
                Set<Id> materialSet = materialMap.keySet();
                List<SObject> materialShares = Database.query('SELECT Id FROM EM_Event_Material_vod__Share WHERE ParentId IN : materialSet');
                List<Database.DeleteResult> results = Database.delete(materialShares, false);
                for (Database.DeleteResult result: results) {
                    if (!result.isSuccess()) {
                     system.debug('Insert error: ' + result.getErrors()[0]);
                   }
                }
            }

            for (Id materialId : materialMap.keySet()) {
                EM_Event_Material_vod__c material = materialMap.get(materialId);
                if (eventToMembers.get(material.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(material.Event_vod__c)) {
                        SObject materialShare = Schema.getGlobalDescribe().get('EM_Event_Material_vod__Share').newSObject();
                        materialShare.put('ParentId', materialId);
                        materialShare.put('UserOrGroupId', memberId);
                        materialShare.put('AccessLevel', 'edit');
                        materialShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(materialShare);
                    }
                }
            }
        } else {
            for (EM_Event_Material_vod__c material : Trigger.new) {
                if (eventToMembers.get(material.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(material.Event_vod__c)) {
                        SObject materialShare = Schema.getGlobalDescribe().get('EM_Event_Material_vod__Share').newSObject();
                        materialShare.put('ParentId', material.Id);
                        materialShare.put('UserOrGroupId', memberId);
                        materialShare.put('AccessLevel', 'edit');
                        materialShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(materialShare);
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