trigger VOD_EM_EVENT_SPEAKER_AFTER_INS_UPD on EM_Event_Speaker_vod__c (after insert, after update) {  
    if (!VOD_Utils.isTriggerEventAttendee()) {
        Map<String, String> statusMap = new Map<String, String>();
        statusMap.put('Invited_vod', 'Invited');
        statusMap.put('Accepted_vod', 'Accepted');
        statusMap.put('Rejected_vod', 'Rejected');
        statusMap.put('Attended_vod', 'Attended');
        
        VOD_Utils.setTriggerEmSpeaker(true);
        List<String> emEventIds = new List<String>();
        Map<String, EM_Event_Speaker_vod__c> emSpeakerMap = new Map<String, EM_Event_Speaker_vod__c>();
        for (EM_Event_Speaker_vod__c emSpeaker : Trigger.new) {
            emEventIds.add(emSpeaker.Event_vod__c);
            emSpeakerMap.put(emSpeaker.Id, emSpeaker);
        }
        
        
        Map<String,String> emEventsToMedEvents = new Map<String,String>();
        for (Medical_Event_vod__c eventStub : [SELECT Id, EM_Event_vod__c
                                               FROM Medical_Event_vod__c
                                               WHERE EM_Event_vod__c in :emEventIds]) {
                                                   emEventsToMedEvents.put(eventStub.EM_Event_vod__c, eventStub.Id);
                                               }
        
        Map<String,String> rtNameToId = new Map<String,String>();
        for (RecordType rt : [SELECT Id, DeveloperName
                              FROM RecordType
                              WHERE SobjectType = 'Event_Attendee_vod__c']) {
                                  rtNameToId.put(rt.DeveloperName, rt.Id);
                              }
        
        List<Event_Attendee_vod__c> attStubs = new List<Event_Attendee_vod__c>();
        if (Trigger.isInsert) {
            List<String> emSpeakerIds = new List<String>();
            for (EM_Event_Speaker_vod__c emSpeaker : Trigger.new) {
                emSpeakerIds.add(emSpeaker.Speaker_vod__c);
            }
            Map<String,String> speakerToAccount = new Map<String,String>();
            for (EM_Speaker_vod__c speaker : [SELECT Id, Account_vod__c
                                              FROM EM_Speaker_vod__c
                                              WHERE Id IN :emSpeakerIds]) {
                                                  speakerToAccount.put(speaker.Id, speaker.Account_vod__c);
                                              }
            
            for (EM_Event_Speaker_vod__c emSpeaker : Trigger.new) {    
                Event_Attendee_vod__c newStub = new Event_Attendee_vod__c(
                    Entity_Reference_Id_vod__c = emSpeaker.Entity_Reference_Id_vod__c,
                    Account_vod__c = speakerToAccount.get(emSpeaker.Speaker_vod__c),
                    Attendee_vod__c = emSpeaker.Speaker_Name_vod__c,
                    EM_Event_Speaker_vod__c = emSpeaker.Id,
                    Meal_Opt_In_vod__c = emSpeaker.Meal_Opt_In_vod__c,
                    Mobile_Id_vod__c = emSpeaker.Stub_Mobile_Id_vod__c,
                    Medical_Event_vod__c = emEventsToMedEvents.get(emSpeaker.Event_vod__c),
                    Signature_vod__c = emSpeaker.Signature_vod__c,
                    Signature_Datetime_vod__c = emSpeaker.Signature_Datetime_vod__c,
                    Override_Lock_vod__c = true
                );
                if (statusMap.get(emSpeaker.Status_vod__c) != null) {
                    newStub.Status_vod__c = statusMap.get(emSpeaker.Status_vod__c);
                } else {
                    newStub.Status_vod__c = emSpeaker.Status_vod__c;
                }
                if (emSpeaker.RecordType != null && rtNameToId.get(emSpeaker.RecordType.DeveloperName) != null) {
                    newStub.RecordTypeId = rtNameToId.get(emSpeaker.RecordType.DeveloperName);
                }
                attStubs.add(newStub);
            }

            if(attStubs.size() > 0) {
            	insert attStubs;
            }

            Map<String, String> idToStubMap = new Map<String,String>();

            for(Event_Attendee_vod__c stub: attStubs) {
            	for (EM_Event_Speaker_vod__c speaker : Trigger.new) {
                    if(stub.EM_Event_Speaker_vod__c == speaker.Id) {
                        idtoStubMap.put(speaker.Id, stub.Id);
                    }
                }
            }

			VOD_EVENT_UTILS.updateSpeakerStub(idToStubMap);

        } else if (Trigger.isUpdate) {
            Set<Id> changedSpeakerIds = new Set<Id>();
            
            Set<String> changeFields = new Set<String>();
            changeFields.add('Entity_Reference_Id_vod__c');
            changeFields.add('Account_vod__c');
            changeFields.add('Speaker_Name_vod__c');
            changeFields.add('Signature_vod__c');
            changeFields.add('Signature_Datetime_vod__c');
            changeFields.add('RecordTypeId');
            changeFields.add('Status_vod__c');            
            
            for(EM_Event_Speaker_vod__c oldSpeaker: Trigger.old) {
                EM_Event_Speaker_vod__c newSpeaker = Trigger.newMap.get(oldSpeaker.Id);
                for(String field: changeFields){
                    if(newSpeaker.get(field) != oldSpeaker.get(field)) {
                        changedSpeakerIds.add(newSpeaker.Id);
                        break;
                    }
                }
            }
            if(changedSpeakerIds.size() > 0) {
                for (Event_Attendee_vod__c attStub : [SELECT Account_vod__c, Contact_vod__c, User_vod__c, Attendee_vod__c,
                                                      Status_vod__c, EM_Event_Speaker_vod__c, Meal_Opt_In_vod__c,
                                                      Signature_vod__c, Signature_Datetime_vod__c, Entity_Reference_Id_vod__c
                                                      FROM Event_Attendee_vod__c
                                                      WHERE EM_Event_Speaker_vod__c IN :changedSpeakerIds]) {
                                                          EM_Event_Speaker_vod__c emSpeaker = emSpeakerMap.get(attStub.EM_Event_Speaker_vod__c);
                                                          attStub.Entity_Reference_Id_vod__c = emSpeaker.Entity_Reference_Id_vod__c;
                                                          attStub.Account_vod__c = emSpeaker.Account_vod__c;
                                                          attStub.Attendee_vod__c = emSpeaker.Speaker_Name_vod__c;
                                                          attStub.EM_Event_Speaker_vod__c = emSpeaker.Id;
                                                          attStub.Signature_vod__c = emSpeaker.Signature_vod__c;
                                                          attStub.Signature_Datetime_vod__c = emSpeaker.Signature_Datetime_vod__c;
                                                          attStub.Meal_Opt_In_vod__c = emSpeaker.Meal_Opt_In_vod__c;
                                                          attStub.Override_Lock_vod__c = true;
                                                          if (emSpeaker.RecordType != null && rtNameToId.get(emSpeaker.RecordType.DeveloperName) != null) {
                                                              attStub.RecordTypeId = rtNameToId.get(emSpeaker.RecordType.DeveloperName);
                                                          }
                                                          if (statusMap.get(emSpeaker.Status_vod__c) != null) {
                                                              attStub.Status_vod__c = statusMap.get(emSpeaker.Status_vod__c);
                                                          } else {
                                                              attStub.Status_vod__c = emSpeaker.Status_vod__c;
                                                          }
                                                          attStubs.add(attStub);
                                                      }    
            }      
            if(attStubs.size() > 0) {
                update attStubs;    
            }                
        }
    }
    if (VOD_Utils.hasObject('EM_Event_Speaker_vod__Share')) {
        List<SObject> newShares = new List<SObject>();
        Set<Id> eventIds = new Set<Id>();
        for (EM_Event_Speaker_vod__c speaker : Trigger.new) {
            eventIds.add(speaker.Event_vod__c);
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
            Map<Id, EM_Event_Speaker_vod__c> speakerMap = new Map<Id, EM_Event_Speaker_vod__c>();
            for (EM_Event_Speaker_vod__c speaker : Trigger.new) {
                if (speaker.Event_vod__c != Trigger.oldMap.get(speaker.Id).Event_vod__c) {
                    speakerMap.put(speaker.Id, speaker);
                }
            }
            if (!speakerMap.isEmpty()) {
                Set<Id> speakerSet = speakerMap.keySet();
                List<SObject> speakerShares = Database.query('SELECT Id FROM EM_Event_Speaker_vod__Share WHERE ParentId IN : speakerSet');
                List<Database.DeleteResult> results = Database.delete(speakerShares, false);
                for (Database.DeleteResult result: results) {
                    if (!result.isSuccess()) {
                     system.debug('Insert error: ' + result.getErrors()[0]);
                   }
                }
            }

            for (Id speakerId : speakerMap.keySet()) {
                EM_Event_Speaker_vod__c speaker = speakerMap.get(speakerId);
                if (eventToMembers.get(speaker.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(speaker.Event_vod__c)) {
                        SObject speakerShare = Schema.getGlobalDescribe().get('EM_Event_Speaker_vod__Share').newSObject();
                        speakerShare.put('ParentId', speakerId);
                        speakerShare.put('UserOrGroupId', memberId);
                        speakerShare.put('AccessLevel', 'edit');
                        speakerShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(speakerShare);
                    }
                }
            }
        } else {
            for (EM_Event_Speaker_vod__c speaker : Trigger.new) {
                if (eventToMembers.get(speaker.Event_vod__c) != null) {
                    for (Id memberId : eventToMembers.get(speaker.Event_vod__c)) {
                        SObject speakerShare = Schema.getGlobalDescribe().get('EM_Event_Speaker_vod__Share').newSObject();
                        speakerShare.put('ParentId', speaker.Id);
                        speakerShare.put('UserOrGroupId', memberId);
                        speakerShare.put('AccessLevel', 'edit');
                        speakerShare.put('RowCause', 'Event_Team_Member_vod__c');
                        newShares.add(speakerShare);
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