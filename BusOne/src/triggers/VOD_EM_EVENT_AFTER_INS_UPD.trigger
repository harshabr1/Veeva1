trigger VOD_EM_EVENT_AFTER_INS_UPD on EM_Event_vod__c (after insert, after update) {
	List<EM_Event_vod__c> childEventstoUpdate = new List<EM_Event_vod__c>();
    List<EM_Event_vod__c> childEvents = new List<EM_Event_vod__c>();
    List<Task> taskstoUpdate = new List<Task>();
    List<Task> tasks = new List<Task>();
    VOD_Utils.setTriggerEMEvent(true);

    List<Id> canceledEvents = new List<Id>();

    Set<String> topicSet = new Set<String>();
    Set<String> configSet = new Set<String>();
    Set<String> countrySet = new Set<String>();

    for(EM_Event_vod__c event: Trigger.new){
        if(event.Status_vod__c == 'Canceled_vod') {
            canceledEvents.add(event.Id);
        }
        if (event.Topic_vod__c != null) {
            topicSet.add(event.Topic_vod__c);
        }
        if (event.Country_vod__c != null) {
            countrySet.add(event.Country_vod__c);
        }
        if (event.Event_Configuration_vod__c != null) {
            configSet.add(event.Event_Configuration_vod__c);
        }
    }

    if(canceledEvents.size() > 0) {
        childEvents = [SELECT Id
                       FROM EM_Event_vod__c
                       WHERE Parent_Event_vod__c IN: canceledEvents AND
                       Start_Time_vod__c >=: Datetime.now()];
        tasks = [SELECT Id
                 FROM Task
                 WHERE WhatId IN: canceledEvents];
    }

    for(Task task: tasks) {
        task.Event_Canceled_vod__c = true;
        taskstoUpdate.add(task);
    }

    for(EM_Event_vod__c childEvent: childEvents) {
        childEvent.Status_vod__c = 'Canceled_vod';
        childEventstoUpdate.add(childEvent);
    }

    if(taskstoUpdate.size() > 0) {
        update taskstoUpdate;
    }

    if(childEventstoUpdate.size() > 0) {
		update childEventstoUpdate;
    }
    Map<String,String> medEventRtNameToId = new Map<String,String>();
    Map<String,String> emRtIdToName = new Map<String,String>();
    for (RecordType rt : [SELECT Id,DeveloperName,SobjectType
                          FROM RecordType
                          WHERE SobjectType IN ('Medical_Event_vod__c', 'EM_Event_vod__c')]) {
        if (rt.SobjectType == 'Medical_Event_vod__c') {
            medEventRtNameToId.put(rt.DeveloperName, rt.Id);
        } else if (rt.SobjectType == 'EM_Event_vod__c') {
            emRtIdToName.put(rt.Id, rt.DeveloperName);
        }
    }

    List<Medical_Event_vod__c> medEventStubs = new List<Medical_Event_vod__c>();
    List<EM_Event_History_vod__c> histories = new List<EM_Event_History_vod__c>();
    boolean hasOwner = Schema.getGlobalDescribe().get('Medical_Event_vod__c').getDescribe().fields.getMap().keySet().contains('OwnerId');
    boolean isAutoNumber = Schema.getGlobalDescribe().get('Medical_Event_vod__c').getDescribe().fields.getMap().get('Name').getDescribe().isAutoNumber();
    if (Trigger.isInsert) {
        for (EM_Event_vod__c emEvent : Trigger.new) {
            Medical_Event_vod__c newStub = new Medical_Event_vod__c(
                Description_vod__c = emEvent.Description_vod__c,
                Location__c = emEvent.Location_vod__c,
                Start_Time_vod__c = emEvent.Start_Time_vod__c,
                End_Time_vod__c = emEvent.End_Time_vod__c,
                Start_Date_vod__c = (emEvent.Start_Time_vod__c != null ? emEvent.Start_Time_vod__c.date() : null),
                End_Date_vod__c = (emEvent.End_Time_vod__c != null ? emEvent.End_Time_vod__c.date() : null),
                Mobile_Id_vod__c = emEvent.Stub_Mobile_Id_vod__c,
                EM_Event_vod__c = emEvent.Id,
                Event_Display_Name_vod__c = emEvent.Event_Display_Name_vod__c,
                Walk_In_Fields_vod__c = emEvent.Walk_In_Fields_vod__c,
                Account_Attendee_Fields_vod__c = emEvent.Account_Attendee_Fields_vod__c,
                User_Attendee_Fields_vod__c = emEvent.User_Attendee_Fields_vod__c,
                Contact_Attendee_Fields_vod__c = emEvent.Contact_Attendee_Fields_vod__c,
                Override_Lock_vod__c = true
                
            );
            if (!isAutoNumber) {
                newStub.put('Name', emEvent.Name);
            }
            if (hasOwner) {
                newStub.put('OwnerId', emEvent.OwnerId);
            }
            
            if (emEvent.Location_vod__c != null && emEvent.Location_vod__c.length() > 40) {
                newStub.Location__c = emEvent.Location_vod__c.substring(0,40);
            } else {
                newStub.Location__c = emEvent.Location_vod__c;
            }
            
            if (emEvent.RecordTypeId != null && medEventRtNameToId.get(emRtIdToName.get(emEvent.RecordTypeId)) != null) {
                newStub.RecordTypeId = medEventRtNameToId.get(emRtIdToName.get(emEvent.RecordTypeId));
            }
            medEventStubs.add(newStub);
            EM_Event_History_vod__c history = new EM_Event_History_vod__c(
                Event_vod__c = emEvent.Id,
                User_vod__c = UserInfo.getUserId(),
                Action_Datetime_vod__c = System.now(),
                Action_Type_vod__c = 'Created_vod',
                Starting_Status_vod__c = emEvent.Status_vod__c
            );
            
            histories.add(history);
        }
        insert medEventStubs;
        insert histories;

    } else if (Trigger.isUpdate && !VOD_Utils.isTriggerMedicalEvent()) {
        Map<String, EM_Event_vod__c> emEventMap = new Map<String, EM_Event_vod__c>();
        for (EM_Event_vod__c emEvent : Trigger.new) {
            emEventMap.put(emEvent.Id, emEvent);
        }
        List<Medical_Event_vod__c> eventStubs = new List<Medical_Event_vod__c>();
        String events = '';
        for (String key : emEventMap.keySet()) {
            if (events.length() > 0) {
                events += ',';
            }
            events += '\'' + key + '\'';
        }
        
        Set<Id> changedEventIds = new Set<Id>();
            
        Set<String> changeFields = new Set<String>();
        changeFields.add('Description_vod__c');
        changeFields.add('Location_vod__c');
        changeFields.add('Start_Time_vod__c');
        changeFields.add('End_Time_vod__c');
        changeFields.add('Event_Display_Name_vod__c');
        changeFields.add('Walk_In_Fields_vod__c');
        changeFields.add('Account_Attendee_Fields_vod__c');
        changeFields.add('User_Attendee_Fields_vod__c');
        changeFields.add('Contact_Attendee_Fields_vod__c');
        changeFields.add('Name');
        changeFields.add('OwnerId');
        changeFields.add('Location_vod__c');
        changeFields.add('RecordTypeId');

        for(EM_Event_vod__c oldEvent: Trigger.old) {
            EM_Event_vod__c newEvent = Trigger.newMap.get(oldEvent.Id);
            for(String field: changeFields){
                if(newEvent.get(field) != oldEvent.get(field)) {
                    changedEventIds.add(newEvent.Id);
                    break;
                }
            }
        }

        if(changedEventIds.size() > 0) {
            if (hasOwner) {
            eventStubs = Database.query('SELECT Name, Description_vod__c, Location__c, Start_Time_vod__c, End_Time_vod__c, Start_Date_vod__c, End_Date_vod__c, OwnerId, EM_Event_vod__c ' +
                          'FROM Medical_Event_vod__c ' +
                          'WHERE EM_Event_vod__c IN (' + events + ')');
            } else {
                eventStubs = Database.query('SELECT Name, Description_vod__c, Location__c, Start_Time_vod__c, End_Time_vod__c, Start_Date_vod__c, End_Date_vod__c, EM_Event_vod__c ' +
                                            'FROM Medical_Event_vod__c ' +
                                            'WHERE EM_Event_vod__c IN (' + events + ')');
        }
  
        }
        for (Medical_Event_vod__c eventStub : eventStubs) {
            EM_Event_vod__c emEvent = emEventMap.get(eventStub.EM_Event_vod__c);
            eventStub.Description_vod__c = emEvent.Description_vod__c;
            eventStub.Location__c = emEvent.Location_vod__c;
            eventStub.Start_Time_vod__c = emEvent.Start_Time_vod__c;
            eventStub.End_Time_vod__c = emEvent.End_Time_vod__c;
            eventStub.Start_Date_vod__c = (emEvent.Start_Time_vod__c != null ? emEvent.Start_Time_vod__c.date() : null);
            eventStub.End_Date_vod__c = (emEvent.End_Time_vod__c != null ? emEvent.End_Time_vod__c.date() : null);
            eventStub.EM_Event_vod__c = emEvent.Id;
            eventStub.Event_Display_Name_vod__c = emEvent.Event_Display_Name_vod__c;
            eventStub.Walk_In_Fields_vod__c = emEvent.Walk_In_Fields_vod__c;
            eventStub.Account_Attendee_Fields_vod__c = emEvent.Account_Attendee_Fields_vod__c;
            eventStub.User_Attendee_Fields_vod__c = emEvent.User_Attendee_Fields_vod__c;
            eventStub.Contact_Attendee_Fields_vod__c = emEvent.Contact_Attendee_Fields_vod__c;
            eventStub.Override_Lock_vod__c = true;
            
            if (hasOwner) {
                eventStub.put('OwnerId', emEvent.OwnerId);
            }
            
            if (!isAutoNumber) {
                eventStub.put('Name', emEvent.Name);
            }
            
            if (emEvent.Location_vod__c != null && emEvent.Location_vod__c.length() > 40) {
                eventStub.Location__c = emEvent.Location_vod__c.substring(0,40);
            } else {
                eventStub.Location__c = emEvent.Location_vod__c;
            }
            
            if (emEvent.RecordTypeId != null && medEventRtNameToId.get(emRtIdToName.get(emEvent.RecordTypeId)) != null) {
                eventStub.RecordTypeId = medEventRtNameToId.get(emRtIdToName.get(emEvent.RecordTypeId));
            }
            
            medEventStubs.add(eventStub);
        }
        update medEventStubs;
    }
    // Create event materials based on event rule and topic material
    List<EM_Event_Material_vod__c> eventMaterials = new List<EM_Event_Material_vod__c>();
    List<EM_Topic_Material_vod__c> topicMaterials = [SELECT Id, Material_vod__c, Material_vod__r.RecordType.DeveloperName, Topic_vod__c, Email_Template_vod__c, CLM_Presentation_vod__c FROM EM_Topic_Material_vod__c
                                                     WHERE ((Material_vod__c != null AND Material_vod__r.Status_vod__c = 'Approved_vod')
                                                            OR (Email_Template_vod__c != null AND Email_Template_vod__r.Status_vod__c IN ('Approved_vod', 'Staged_vod'))
                                                            OR (CLM_Presentation_vod__c != null AND CLM_Presentation_vod__r.Status_vod__c IN ('Approved_vod', 'Staged_vod', '') AND CLM_Presentation_vod__r.Content_Channel_vod__c != null))
                                                     AND Topic_vod__c IN : topicSet];
    List<EM_Event_Rule_vod__c> eventRules = [SELECT Id, Event_Configuration_vod__c, Country_Override_vod__c, Country_Override_vod__r.Country_vod__c,
                                             Material_vod__c, Material_vod__r.RecordType.DeveloperName, Email_Template_vod__c, CLM_Presentation_vod__c FROM EM_Event_Rule_vod__c
                                             WHERE ((Material_vod__c != null AND Material_vod__r.Status_vod__c = 'Approved_vod')
                                             OR (Email_Template_vod__c != null AND Email_Template_vod__r.Status_vod__c IN ('Approved_vod', 'Staged_vod'))
                                             OR (CLM_Presentation_vod__c != null AND CLM_Presentation_vod__r.Status_vod__c IN ('Approved_vod', 'Staged_vod', '') AND CLM_Presentation_vod__r.Content_Channel_vod__c != null))
                                             AND Event_Configuration_vod__c IN : configSet
                                             AND (Country_Override_vod__c = null OR Country_Override_vod__r.Country_vod__c IN : countrySet)];
    List<RecordType> types = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'EM_Event_Material_vod__c'];
    Map<String, String> materialRT = new Map<String, String>();
    Map<String, String> materialToRecordType = new Map<String, String>();
    for (RecordType type : types) {
        materialRT.put(type.DeveloperName, type.Id);
    }

    if (Trigger.isInsert) {
        for (EM_Event_vod__c event : Trigger.new) {
            Set<String> materials = new Set<String>();
            for (EM_Topic_Material_vod__c topicMaterial : topicMaterials) {
                Boolean hasValidTopic = topicMaterial.Topic_vod__c == event.Topic_vod__c;

                if (hasValidTopic) {
                    if (topicMaterial.Material_vod__c!= null && !materials.contains(topicMaterial.Material_vod__c)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            Material_vod__c = topicMaterial.Material_vod__c,
                            Event_vod__c = event.Id
                        );
                        if (materialRT.get(topicMaterial.Material_vod__r.RecordType.DeveloperName) != null) {
                            eventMaterial.RecordTypeId = materialRT.get(topicMaterial.Material_vod__r.RecordType.DeveloperName);
                        }
                        materials.add(topicMaterial.Material_vod__c);
                        eventMaterials.add(eventMaterial);
                    } else if (topicMaterial.Email_Template_vod__c != null && !materials.contains(topicMaterial.Email_Template_vod__c)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            Email_Template_vod__c = topicMaterial.Email_Template_vod__c,
                            Event_vod__c = event.Id
                        );
                        String templateRecordType = materialRT.get('Email_Template_vod');
                        if (templateRecordType != null) {
                            eventMaterial.RecordTypeId = templateRecordType;
                        }
                        materials.add(topicMaterial.Email_Template_vod__c);
                        eventMaterials.add(eventMaterial);
                    }
                    else if (topicMaterial.CLM_Presentation_vod__c != null && !materials.contains(topicMaterial.CLM_Presentation_vod__c)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            CLM_Presentation_vod__c = topicMaterial.CLM_Presentation_vod__c,
                            Event_vod__c = event.Id
                        );
                        String templateRecordType = materialRT.get('CLM_Presentation_vod');
                        if (templateRecordType != null) {
                            eventMaterial.RecordTypeId = templateRecordType;
                        }
                        materials.add(topicMaterial.CLM_Presentation_vod__c);
                        eventMaterials.add(eventMaterial);
                    }
                }
            }
            for (EM_Event_Rule_vod__c eventRule : eventRules) {
                Boolean hasValidEventConfiguration = eventRule.Event_Configuration_vod__c == event.Event_Configuration_vod__c;
                Boolean hasValidCountryOverride = eventRule.Country_Override_vod__c == null || eventRule.Country_Override_vod__r.Country_vod__c == event.Country_vod__c;

                if(hasValidEventConfiguration && hasValidCountryOverride) {
                    if (eventRule.Material_vod__c != null && !materials.contains(eventRule.Material_vod__c)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            Material_vod__c = eventRule.Material_vod__c,
                            Event_vod__c = event.Id
                        );
                        if (materialRT.get(eventRule.Material_vod__r.RecordType.DeveloperName) != null) {
                            eventMaterial.RecordTypeId = materialRT.get(eventRule.Material_vod__r.RecordType.DeveloperName);
                        }
                        materials.add(eventRule.Material_vod__c);
                        eventMaterials.add(eventMaterial);
                    }
                    else if (eventRule.Email_Template_vod__c != null && !materials.contains(eventRule.Email_Template_vod__c)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            Email_Template_vod__c = eventRule.Email_Template_vod__c,
                            Event_vod__c = event.Id
                        );
                        String templateRecordType = materialRT.get('Email_Template_vod');
                        if (templateRecordType != null) {
                            eventMaterial.RecordTypeId = templateRecordType;
                        }
                        materials.add(eventRule.Email_Template_vod__c);
                        eventMaterials.add(eventMaterial);
                    }
                    else if (eventRule.CLM_Presentation_vod__c != null && !materials.contains(eventRule.CLM_Presentation_vod__c)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            CLM_Presentation_vod__c = eventRule.CLM_Presentation_vod__c,
                            Event_vod__c = event.Id
                        );
                        String templateRecordType = materialRT.get('CLM_Presentation_vod');
                        if(templateRecordType != null) {
                            eventMaterial.RecordTypeId = templateRecordType;
                        }
                        materials.add(eventRule.CLM_Presentation_vod__c);
                        eventMaterials.add(eventMaterial);
                    }
                }
            }
        }
    } else {
        List<EM_Event_Material_vod__c> deleteEventMaterials = new List<EM_Event_Material_vod__c>();
        List<EM_Event_Material_vod__c> existingMaterials = [SELECT Id, Event_vod__c, Material_vod__c, Email_Template_vod__c, CLM_Presentation_vod__c, Material_Used_vod__c
                                                            FROM EM_Event_Material_vod__c
                                                            WHERE Event_vod__c IN : Trigger.newMap.keySet()];
        Map<String, Set<String>> eventToMaterials = new Map<String, Set<String>>();       
        for (EM_Event_Material_vod__c material : existingMaterials) {
            if (eventToMaterials.get(material.Event_vod__c) == null) {
                eventToMaterials.put(material.Event_vod__c, new Set<String>());
            }
            if(material.Material_vod__c != null) {
            	eventToMaterials.get(material.Event_vod__c).add(material.Material_vod__c);   
            } else if (material.Email_Template_vod__c != null) {
            	eventToMaterials.get(material.Event_vod__c).add(material.Email_Template_vod__c);    
            }
            else if (material.CLM_Presentation_vod__c != null) {
                eventToMaterials.get(material.Event_vod__c).add(material.CLM_Presentation_vod__c);
            }
        }

        for (EM_Event_vod__c event : Trigger.new) {
            EM_Event_vod__c oldEvent = Trigger.oldMap.get(event.Id);
            if (oldEvent.Topic_vod__c == event.Topic_vod__c && oldEvent.Event_Configuration_vod__c == event.Event_Configuration_vod__c) {
                continue;
            }
            Set<String> materials = new Set<String>();
            Set<String> approvedDocuments = new Set<String>();
            Set<String> clmPresentations = new Set<String>();
            for (EM_Topic_Material_vod__c topicMaterial : topicMaterials) {
                if (topicMaterial.Topic_vod__c == event.Topic_vod__c) {
                    if(topicMaterial.Material_vod__c != null) {
                    	materials.add(topicMaterial.Material_vod__c);
                        materialToRecordType.put(topicMaterial.Material_vod__c, topicMaterial.Material_vod__r.RecordType.DeveloperName);
                    } else if(topicMaterial.Email_Template_vod__c != null) {
                        approvedDocuments.add(topicMaterial.Email_Template_vod__c);
                    }
                    else if(topicMaterial.CLM_Presentation_vod__c != null) {
                        clmPresentations.add(topicMaterial.CLM_Presentation_vod__c);
                    }
                }
            }
            Set<String> ruleMaterials = new Set<String>();
            Set<String> ruleApprovedDocuments = new Set<String>();
            Set<String> ruleClmPresentations = new Set<String>();
            for (EM_Event_Rule_vod__c eventRule : eventRules) {
                if (eventRule.Event_Configuration_vod__c == event.Event_Configuration_vod__c &&
                (eventRule.Country_Override_vod__c == null || eventRule.Country_Override_vod__r.Country_vod__c == event.Country_vod__c)) {
                    if(eventRule.Material_vod__c != null) {
                    	ruleMaterials.add(eventRule.Material_vod__c);
                        materialToRecordType.put(eventRule.Material_vod__c, eventRule.Material_vod__r.RecordType.DeveloperName);
                    } else if (eventRule.Email_Template_vod__c != null) {
                        ruleApprovedDocuments.add(eventRule.Email_Template_vod__c);
                    }
                    else if (eventRule.CLM_Presentation_vod__c != null) {
                        ruleClmPresentations.add(eventRule.CLM_Presentation_vod__c);
                    }
                }
            }

            if (oldEvent.Topic_vod__c != event.Topic_vod__c) {
                for (String material : materials) {
                    if (eventToMaterials.get(event.Id) == null || !eventToMaterials.get(event.Id).contains(material)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            Material_vod__c = material,
                            Event_vod__c = event.Id
                        );
                        String rtDeveloperName = materialToRecordType.get(material);
                        if (rtDeveloperName != null && materialRT.get(rtDeveloperName) != null) {
                            eventMaterial.RecordTypeId = materialRT.get(rtDeveloperName);
                        }
                        
                        eventMaterials.add(eventMaterial);
                    }
                }
                for(String approvedDocument: approvedDocuments) {
                	if (eventToMaterials.get(event.Id) == null || !eventToMaterials.get(event.Id).contains(approvedDocument)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            Email_Template_vod__c = approvedDocument,
                            Event_vod__c = event.Id
                        );
                        
                        String templateRecordType = materialRT.get('Email_Template_vod');
                        if (templateRecordType != null) {
                            eventMaterial.RecordTypeId = templateRecordType;
                        }
                        
                        eventMaterials.add(eventMaterial);
                    }    
                }
                for(String clmPresentation: clmPresentations) {
                    if (eventToMaterials.get(event.Id) == null || !eventToMaterials.get(event.Id).contains(clmPresentation)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                                CLM_Presentation_vod__c = clmPresentation,
                                Event_vod__c = event.Id
                        );

                        String templateRecordType = materialRT.get('CLM_Presentation_vod');
                        if (templateRecordType != null) {
                            eventMaterial.RecordTypeId = templateRecordType;
                        }

                        eventMaterials.add(eventMaterial);
                    }
                }
            }
            if (oldEvent.Event_Configuration_vod__c != event.Event_Configuration_vod__c || oldEvent.Country_vod__c != event.Country_vod__c) {
                for (String material : ruleMaterials) {
                    if (eventToMaterials.get(event.Id) == null || !eventToMaterials.get(event.Id).contains(material)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            Material_vod__c = material,
                            Event_vod__c = event.Id
                        );
                        String rtDeveloperName = materialToRecordType.get(material);
                        if (rtDeveloperName != null && materialRT.get(rtDeveloperName) != null) {
                            eventMaterial.RecordTypeId = materialRT.get(rtDeveloperName);
                        }
                        
                        eventMaterials.add(eventMaterial);
                    }
                }
                for(String approvedDocument: ruleApprovedDocuments) {
                    if (eventToMaterials.get(event.Id) == null || !eventToMaterials.get(event.Id).contains(approvedDocument)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                            Email_Template_vod__c = approvedDocument,
                            Event_vod__c = event.Id
                        );
                        
                        String templateRecordType = materialRT.get('Email_Template_vod');
                        if (templateRecordType != null) {
                            eventMaterial.RecordTypeId = templateRecordType;
                        }
                        
                        eventMaterials.add(eventMaterial);
                    }    
                }
                for(String clmPresentation: ruleClmPresentations) {
                    if (eventToMaterials.get(event.Id) == null || !eventToMaterials.get(event.Id).contains(clmPresentation)) {
                        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                                CLM_Presentation_vod__c = clmPresentation,
                                Event_vod__c = event.Id
                        );

                        String templateRecordType = materialRT.get('CLM_Presentation_vod');
                        if (templateRecordType != null) {
                            eventMaterial.RecordTypeId = templateRecordType;
                        }

                        eventMaterials.add(eventMaterial);
                    }
                }
            }

            for (EM_Event_Material_vod__c material : existingMaterials) {
                if (material.Event_vod__c == event.Id && !material.Material_Used_vod__c &&
                        ((material.Material_vod__c != null && !materials.contains(material.Material_vod__c) && !ruleMaterials.contains(material.Material_vod__c)) ||
                         (material.Email_Template_vod__c != null && !approvedDocuments.contains(material.Email_Template_vod__c) && !ruleApprovedDocuments.contains(material.Email_Template_vod__c)) ||
                         (material.CLM_Presentation_vod__c != null && !clmPresentations.contains(material.CLM_Presentation_vod__c) && !ruleClmPresentations.contains(material.CLM_Presentation_vod__c)))) {
                    deleteEventMaterials.add(material);
                }
            }
        }
        if (!deleteEventMaterials.isEmpty()) {
            delete deleteEventMaterials;
        }
    }

    if (!eventMaterials.isEmpty()) {
        insert eventMaterials;
    }
}