trigger VOD_MEDICAL_EVENT_AFTER_INSERT_UPDATE on Medical_Event_vod__c (after insert, after update) {
	Map<String, Medical_Event_vod__c> emEventMap = new Map<String, Medical_Event_vod__c>();
	VOD_Utils.setTriggerMedicalEvent(true);
	for (Medical_Event_vod__c medEvent : Trigger.new) {
		if (medEvent.EM_Event_vod__c != null) {
			emEventMap.put(medEvent.EM_Event_vod__c, medEvent);
		}
	}

    if(emEventMap.values().size() > 0) {
    	Set<String> groupNameSet = new Set<String>();
        for (EM_Event_Team_Member_vod__c member : [SELECT Group_Name_vod__c
                                                   FROM EM_Event_Team_Member_vod__c
                                                   WHERE Event_vod__c IN :emEventMap.keySet() AND Group_Name_vod__c != null]) {
            groupNameSet.add(member.Group_Name_vod__c);
        }
    
        Map<String, Id> groupNameToGroupId = new Map<String, Id>();
        for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNameSet]) {
            groupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
        }
        
        Map<Id,Set<EM_Event_Team_Member_vod__c>> teamMemberMap = new Map<Id,Set<EM_Event_Team_Member_vod__c>>();
        for(EM_Event_Team_Member_vod__c member: [SELECT Id, Event_vod__c, Team_Member_vod__c, Group_Name_vod__c  FROM EM_Event_Team_Member_vod__c WHERE Event_vod__c IN :emEventMap.keySet()]) {                                           
            Set<EM_Event_Team_Member_vod__c> currentSet = teamMemberMap.get(member.Event_vod__c);
            if(currentSet == null) {
                currentSet = new Set<EM_Event_Team_Member_vod__c>();
            }
            currentSet.add(member);
            teamMemberMap.put(member.Event_vod__c, currentSet); 
        }
        
        Map<Id, Set<Id>> eventToMembers = new Map<Id, Set<Id>>();
        for(Id eventId : emEventMap.keySet()) {
            if (teamMemberMap.get(eventId) != null) {
                eventToMembers.put(eventId, new Set<Id>());
                for (EM_Event_Team_Member_vod__c member : teamMemberMap.get(eventId)) {
                    if(member.Team_Member_vod__c != null) {
                        eventToMembers.get(eventId).add(member.Team_Member_vod__c);
                    } else if(member.Group_Name_vod__c != null) {
                        Id groupUserId = groupNameToGroupId.get(member.Group_Name_vod__c);
                        if(groupUserId != null) {
                            eventToMembers.get(eventId).add(groupUserId);
                        }
                    }
                }
            }    
        }
        
    
        List<EM_Event_vod__c> updateEvent = new List<EM_Event_vod__c>();
        for (EM_Event_vod__c emEvent : [SELECT Id, Stub_SFDC_Id_vod__c, Override_Lock_vod__c, Lock_vod__c
                                        FROM EM_Event_vod__c
                                        WHERE Id IN :emEventMap.keySet()]) {
            boolean updateEventBool = false;
            Medical_Event_vod__c medEvent = emEventMap.get(emEvent.Id);
            if(Trigger.IsInsert) {
                emEvent.Stub_SFDC_Id_vod__c = medEvent.Id;
                updateEvent.add(emEvent);
                updateEventBool = true;
            }
    
            if(!VOD_Utils.isTriggerEMEvent()) {
                emEvent.Event_Display_Name_vod__c = medEvent.Event_Display_Name_vod__c;
                if(!updateEventBool) {
                    updateEvent.add(emEvent);
                    updateEventBool = true;
                }
            }      
        }
        if (!updateEvent.isEmpty()) {
            update updateEvent;
        }
    
        if (VOD_Utils.hasObject('Medical_Event_vod__Share')) {
            List<SObject> newShares = new List<SObject>();
            if (Trigger.isUpdate) {
                Map<Id, Medical_Event_vod__c> medicalEventMap = new Map<Id, Medical_Event_vod__c>();
                for (Medical_Event_vod__c medicalEvent : Trigger.new) {
                    if (medicalEvent.EM_Event_vod__c != Trigger.oldMap.get(medicalEvent.Id).EM_Event_vod__c) {
                        medicalEventMap.put(medicalEvent.Id, medicalEvent);
                    }
                }
                if (!medicalEventMap.isEmpty()) {
                    Set<Id> medicalEventSet = medicalEventMap.keySet();
                    List<SObject> medicalEventShares = Database.query('SELECT Id FROM Medical_Event_vod__Share WHERE ParentId IN : medicalEventSet');
                    List<Database.DeleteResult> results = Database.delete(medicalEventShares, false);
                    for (Database.DeleteResult result: results) {
                        if (!result.isSuccess()) {
                         system.debug('Insert error: ' + result.getErrors()[0]);
                       }
                    }
                }
    
                for (Id medicalEventId : medicalEventMap.keySet()) {
                    Medical_Event_vod__c medicalEvent = medicalEventMap.get(medicalEventId);
                    if (eventToMembers.get(medicalEvent.EM_Event_vod__c) != null) {
                        for (Id memberId : eventToMembers.get(medicalEvent.EM_Event_vod__c)) {
                            SObject medicalEventShare = Schema.getGlobalDescribe().get('Medical_Event_vod__Share').newSObject();
                            medicalEventShare.put('ParentId', medicalEventId);
                            medicalEventShare.put('UserOrGroupId', memberId);
                            medicalEventShare.put('AccessLevel', 'edit');
                            medicalEventShare.put('RowCause', 'Event_Team_Member_vod__c');
                            newShares.add(medicalEventShare);
                        }
                    }
                }
            } else {
                for (Medical_Event_vod__c medicalEvent : Trigger.new) {
                    if (eventToMembers.get(medicalEvent.EM_Event_vod__c) != null) {
                        for (Id memberId : eventToMembers.get(medicalEvent.EM_Event_vod__c)) {
                            SObject medicalEventShare = Schema.getGlobalDescribe().get('Medical_Event_vod__Share').newSObject();
                            medicalEventShare.put('ParentId', medicalEvent.Id);
                            medicalEventShare.put('UserOrGroupId', memberId);
                            medicalEventShare.put('AccessLevel', 'edit');
                            medicalEventShare.put('RowCause', 'Event_Team_Member_vod__c');
                            newShares.add(medicalEventShare);
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
}