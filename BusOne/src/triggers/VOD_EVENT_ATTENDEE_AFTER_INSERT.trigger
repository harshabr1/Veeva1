trigger VOD_EVENT_ATTENDEE_AFTER_INSERT on Event_Attendee_vod__c (after insert, after update) {        
    //Event Management logic
    if (!VOD_Utils.isTriggerEmAttendee() && !VOD_Utils.isTriggerEmSpeaker()) {
        if (Trigger.isInsert) {
            Map<String, String> idToStubMap = new Map<String,String>();
            for(Event_Attendee_vod__c attStub: Trigger.New) {
                if(attStub.EM_Attendee_vod__c != null) {
                	idToStubMap.put(attStub.EM_Attendee_vod__c, attStub.Id);
                }
            }
			VOD_EVENT_UTILS.updateAttendeeStub(idToStubMap);
        } else if (Trigger.isUpdate) {
            Map<String, String> statusMap = new Map<String, String>();
            statusMap.put('Invited', 'Invited_vod');
            statusMap.put('Accepted', 'Accepted_vod');
            statusMap.put('Rejected', 'Rejected_vod');
            statusMap.put('Attended', 'Attended_vod');
            Set<DescribeFieldResult> emFields = new Set<DescribeFieldResult>();
            Set<DescribeFieldResult> meFields = new Set<DescribeFieldResult>();
            String[] types = new String[]{'Event_Attendee_vod__c','EM_Attendee_vod__c'};
                Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);

            for(Schema.DescribeSObjectResult res :results) {
                Map<String,Schema.SObjectField> mfields = res.fields.getMap();
                for(Schema.SObjectField field: mfields.values()) {
                    DescribeFieldResult fDescribe = field.getDescribe();
                    if(fDescribe.isCustom() && !fDescribe.getName().endsWith('vod__c')) {
                        if(res.getName() == 'Event_Attendee_vod__c') {
                            meFields.add(fDescribe);
                        } else if(res.getName() == 'EM_Attendee_vod__c') {
                            emFields.add(fDescribe);
                        }
                    }
                }
            }
            Set<String> mappedFields = new Set<String>();
            for(DescribeFieldResult emDescribe: emFields) {
                for(DescribeFieldResult meDescribe: meFields) {
                    if(emDescribe.getName() == meDescribe.getName() && emDescribe.getType() == meDescribe.getType() &&
                       !(emDescribe.isCalculated() || meDescribe.isCalculated())) {
                           mappedFields.add(meDescribe.getName());
                           break;
                       }
                }
            }

            List<EM_Attendee_vod__c> emAtts = new List<EM_Attendee_vod__c>();
            List<EM_Event_Speaker_vod__c> emSpeakers = new List<EM_Event_Speaker_vod__c>();
            List<String> stubReferencedEmAtts = new List<String>();
            List<String> stubReferencedEmSpeakers = new List<String>();
            List<String> medEventIds = new List<String>();
            Map<String,Event_Attendee_vod__c> emIdsToStubs = new Map<String,Event_Attendee_vod__c>();
            Map<String,String> medEventIdsToEmEventIds = new Map<String,String>();

            for (Event_Attendee_vod__c att : Trigger.new) {
                if (att.Medical_Event_vod__c != null) {
                    medEventIds.add(att.Medical_Event_vod__c);
                }
            }

            if (medEventIds.size() > 0) {
                for (Medical_Event_vod__c medEvent : [SELECT Id, EM_Event_vod__c
                                                      FROM Medical_Event_vod__c
                                                      WHERE Id in :medEventIds AND EM_Event_vod__c != null]) {
                                                          medEventIdsToEmEventIds.put(medEvent.Id, medEvent.EM_Event_vod__c);
                                                      }
            }
            for (Event_Attendee_vod__c attStub : Trigger.new) {
                if (attStub.EM_Attendee_vod__c != null) {
                    stubReferencedEMAtts.add(attStub.EM_Attendee_vod__c);
                    emIdsToStubs.put(attStub.EM_Attendee_vod__c, attStub);
                } else if (attStub.EM_Event_Speaker_vod__c != null) {
                    stubReferencedEmSpeakers.add(attStub.EM_Event_Speaker_vod__c);
                    emIdsToStubs.put(attStub.EM_Event_Speaker_vod__c, attStub);
                }
            }
            if (medEventIdsToEmEventIds.size() > 0) {
                Map<Id, EM_Event_vod__c> emEvents = new Map<Id, EM_Event_vod__c>([SELECT Id, (SELECT Id, Status_vod__c, Signature_vod__c, Signature_Datetime_vod__c, Meal_Opt_In_vod__c
                                                                                    FROM EM_Attendee_Event_vod__r WHERE Id IN : stubReferencedEMAtts),
                                                                                    (SELECT Id, Status_vod__c, Signature_vod__c, Signature_Datetime_vod__c, Meal_Opt_In_vod__c
                                                                                    FROM EM_Event_Speaker_vod__r WHERE Id IN : stubReferencedEmSpeakers)
                                                                                    FROM EM_Event_vod__c WHERE Id IN : medEventIdsToEmEventIds.values()]);
                Map<Id, EM_Attendee_vod__c> attendeeMap = new Map<Id, EM_Attendee_vod__c>();
                Map<Id, EM_Event_Speaker_vod__c> speakerMap = new Map<Id, EM_Event_Speaker_vod__c>();
                for (Id eventId : emEvents.keySet()) {
                    EM_Event_vod__c emEvent = emEvents.get(eventId);
                    for (EM_Attendee_vod__c attendee : emEvent.EM_Attendee_Event_vod__r) {
                        attendeeMap.put(attendee.Id, attendee);
                    }
                    for (EM_Event_Speaker_vod__c speaker : emEvent.EM_Event_Speaker_vod__r) {
                        speakerMap.put(speaker.Id, speaker);
                    }
                }
                for (Id attendeeId : attendeeMap.keySet()) {
                    Event_Attendee_vod__c currAttStub = emIdsToStubs.get(attendeeId);
                    EM_Attendee_vod__c attendee = attendeeMap.get(attendeeId);
                    attendee.Attendee_Name_vod__c = currAttStub.Attendee_vod__c;
                    attendee.Signature_vod__c = currAttStub.Signature_vod__c;
                    attendee.Signature_Datetime_vod__c = currAttStub.Signature_Datetime_vod__c;
                    attendee.Meal_Opt_In_vod__c = currAttStub.Meal_Opt_In_vod__c;
                    if (currAttStub.Status_vod__c != Trigger.oldMap.get(currAttStub.Id).Status_vod__c) {
                        if (statusMap.get(currAttStub.Status_vod__c) != null) {
                            attendee.Status_vod__c = statusMap.get(currAttStub.Status_vod__c);
                        } else {
                            attendee.Status_vod__c = currAttStub.Status_vod__c;
                        }
                    }
                    attendee.Walk_In_Status_vod__c = currAttStub.Walk_In_Status_vod__c;
                    attendee.Address_Line_1_vod__c = currAttStub.Address_Line_1_vod__c;
                    attendee.Address_Line_2_vod__c = currAttStub.Address_Line_2_vod__c;
                    attendee.City_vod__c = currAttStub.City_vod__c;
                    attendee.Zip_vod__c = currAttStub.Zip_vod__c;
                    attendee.Phone_vod__c = currAttStub.Phone_vod__c;
                    attendee.Email_vod__c = currAttStub.Email_vod__c;
                    attendee.Prescriber_vod__c = currAttStub.Prescriber_vod__c;
                    attendee.First_Name_vod__c = currAttStub.First_Name_vod__c;
                    attendee.Last_Name_vod__c = currAttStub.Last_Name_vod__c;
                    attendee.Organization_vod__c = currAttStub.Organization_vod__c;
					attendee.Override_Lock_vod__c = true;
                    emAtts.add(attendee);
                    for(String mfield: mappedFields) {
                        attendee.put(mfield, currAttStub.get(mfield));
                    }
                }
                if (emAtts.size() > 0) {
                    update emAtts;
                }
                for (Id speakerId : speakerMap.keySet()) {
                    Event_Attendee_vod__c currSpeakerStub = emIdsToStubs.get(speakerId);
                    EM_Event_Speaker_vod__c speaker = speakerMap.get(speakerId);
                    speaker.Signature_vod__c = currSpeakerStub.Signature_vod__c;
                    speaker.Signature_Datetime_vod__c = currSpeakerStub.Signature_Datetime_vod__c;
                    speaker.Meal_Opt_In_vod__c = currSpeakerStub.Meal_Opt_In_vod__c;
                    speaker.Override_Lock_vod__c = true;
                    if (currSpeakerStub.Status_vod__c != Trigger.oldMap.get(currSpeakerStub.Id).Status_vod__c) {
                        if (statusMap.get(currSpeakerStub.Status_vod__c) != null) {
                            speaker.Status_vod__c = statusMap.get(currSpeakerStub.Status_vod__c);
                        } else {
                            speaker.Status_vod__c = currSpeakerStub.Status_vod__c;
                        }
                    }
                    emSpeakers.add(speaker);
                }
                if (emSpeakers.size() > 0) {
                    update emSpeakers;
                }
            }
        }
    }
}