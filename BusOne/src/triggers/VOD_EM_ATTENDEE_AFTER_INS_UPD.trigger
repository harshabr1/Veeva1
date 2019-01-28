trigger VOD_EM_ATTENDEE_AFTER_INS_UPD on EM_Attendee_vod__c (after insert, after update) {
	if (!VOD_Utils.isTriggerEventAttendee()) {
        Map<String, String> statusMap = new Map<String, String>();
        statusMap.put('Invited_vod', 'Invited');
        statusMap.put('Accepted_vod', 'Accepted');
        statusMap.put('Rejected_vod', 'Rejected');
        statusMap.put('Attended_vod', 'Attended');

        Set<DescribeFieldResult> emFields = new Set<DescribeFieldResult>();
        Set<DescribeFieldResult> meFields = new Set<DescribeFieldResult>();
        String[] types = new String[]{'Event_Attendee_vod__c','EM_Attendee_vod__c'};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);

        for(Schema.DescribeSobjectResult res : results) {
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

        VOD_Utils.setTriggerEmAttendee(true);
        List<String> emEventIds = new List<String>();
        Map<String, EM_Attendee_vod__c> emAttMap = new Map<String, EM_Attendee_vod__c>();
        for (EM_Attendee_vod__c emAtt : Trigger.new) {
						if(emAtt.Event_vod__c != null) {
            		emEventIds.add(emAtt.Event_vod__c);
						}
            emAttMap.put(emAtt.Id, emAtt);
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
            Map<ID,Schema.RecordTypeInfo> emRTMap = EM_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosById();
            Map<String,Schema.RecordTypeInfo> eaRTMap = Event_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosByName();
            for (EM_Attendee_vod__c emAtt : Trigger.new) {
                Event_Attendee_vod__c newStub = new Event_Attendee_vod__c(
                    Entity_Reference_Id_vod__c = emAtt.Entity_Reference_Id_vod__c,
                    Account_vod__c = emAtt.Account_vod__c,
                    Contact_vod__c = emAtt.Contact_vod__c,
                    User_vod__c = emAtt.User_vod__c,
                    Attendee_vod__c = emAtt.Attendee_Name_vod__c,
                    EM_Attendee_vod__c = emAtt.Id,
                    Meal_Opt_In_vod__c = emAtt.Meal_Opt_In_vod__c,
                    Mobile_Id_vod__c = emAtt.Stub_Mobile_Id_vod__c,
                    Medical_Event_vod__c = emEventsToMedEvents.get(emAtt.Event_vod__c),
                    Signature_vod__c = emAtt.Signature_vod__c,
                    Signature_Datetime_vod__c = emAtt.Signature_Datetime_vod__c,
                    Walk_In_Status_vod__c = emAtt.Walk_In_Status_vod__c,
                    Address_Line_1_vod__c = emAtt.Address_Line_1_vod__c,
                    Address_Line_2_vod__c = emAtt.Address_Line_2_vod__c,
                    City_vod__c = emAtt.City_vod__c,
                    Zip_vod__c = emAtt.Zip_vod__c,
                    Phone_vod__c = emAtt.Phone_vod__c,
                    Email_vod__c = emAtt.Email_vod__c,
                    Prescriber_vod__c = emAtt.Prescriber_vod__c,
                    First_Name_vod__c = emAtt.First_Name_vod__c,
                    Last_Name_vod__c = emAtt.Last_Name_vod__c,
                    Organization_vod__c = emAtt.Organization_vod__c,
                    Override_Lock_vod__c = true
                );

                RecordTypeInfo eaInfo = eaRTMap.get(emRTMap.get(emAtt.RecordTypeId).getName());
                if(eaInfo != null && eaInfo.isAvailable()) {
                    newStub.RecordTypeId = eaInfo.getRecordTypeId();
                }

                if (statusMap.get(emAtt.Status_vod__c) != null) {
                    newStub.Status_vod__c = statusMap.get(emAtt.Status_vod__c);
                } else {
                    newStub.Status_vod__c = emAtt.Status_vod__c;
                }
                for(String mfield: mappedFields) {
                    newStub.put(mfield, emAtt.get(mfield));
                }
                if (emAtt.RecordType != null && rtNameToId.get(emAtt.RecordType.DeveloperName) != null) {
                    newStub.RecordTypeId = rtNameToId.get(emAtt.RecordType.DeveloperName);
                }
                attStubs.add(newStub);
            }
            if(attStubs.size() > 0) {
            	insert attStubs;
            }

			Map<String, String> idToStubMap = new Map<String,String>();

            for(Event_Attendee_vod__c stub: attStubs) {
            	for (EM_Attendee_vod__c emAtt : Trigger.new) {
                    if(stub.EM_Attendee_vod__c == emAtt.Id) {
                        idtoStubMap.put(emAtt.Id, stub.Id);
                    }
                }
            }

			VOD_EVENT_UTILS.updateAttendeeStub(idToStubMap);

        } else if (Trigger.isUpdate) {
            Set<Id> changedAttendeeIds = new Set<Id>();

            Set<String> changeFields = new Set<String>();
            changeFields.addAll(mappedFields);
            changeFields.add('Entity_Reference_Id_vod__c');
            changeFields.add('Account_vod__c');
            changeFields.add('Contact_vod__c');
            changeFields.add('Attendee_Name_vod__c');
            changeFields.add('Meal_Opt_In_vod__c');
            changeFields.add('Signature_vod__c');
            changeFields.add('Signature_Datetime_vod__c');
            changeFields.add('Walk_In_Status_vod__c');
            changeFields.add('Address_Line_1_vod__c');
            changeFields.add('Address_Line_2_vod__c');
            changeFields.add('City_vod__c');
            changeFields.add('Phone_vod__c');
            changeFields.add('Zip_vod__c');
            changeFields.add('Email_vod__c');
            changeFields.add('Prescriber_vod__c');
            changeFields.add('First_Name_vod__c');
            changeFields.add('Last_Name_vod__c');
            changeFields.add('Organization_vod__c');
            changeFields.add('RecordTypeId');
            changeFields.add('Status_vod__c');

            for(EM_Attendee_vod__c oldAtt: Trigger.old) {
                EM_Attendee_vod__c newAtt = Trigger.newMap.get(oldAtt.Id);
                for(String field: changeFields){
                    if(newAtt.get(field) != oldAtt.get(field)) {
                        changedAttendeeIds.add(newAtt.Id);
                        break;
                    }
                }
            }

            if(changedAttendeeIds.size() > 0) {
            	for (Event_Attendee_vod__c attStub : [SELECT Account_vod__c, Contact_vod__c, User_vod__c, Attendee_vod__c,
                                                  Status_vod__c, EM_Attendee_vod__c, Meal_Opt_In_vod__c, Signature_vod__c,
                                                  Signature_Datetime_vod__c, Walk_In_Status_vod__c, Address_Line_1_vod__c,
                                                  Address_Line_2_vod__c, City_vod__c, Zip_vod__c, Phone_vod__c, Email_vod__c,
                                                  Prescriber_vod__c, First_Name_vod__c, Last_Name_vod__c, Entity_Reference_Id_vod__c
                                                  FROM Event_Attendee_vod__c
                                                  WHERE EM_Attendee_vod__c IN :changedAttendeeIds]) {
                    EM_Attendee_vod__c emAtt = emAttMap.get(attStub.EM_Attendee_vod__c);
                    attStub.Entity_Reference_Id_vod__c = emAtt.Entity_Reference_Id_vod__c;
                    attStub.Account_vod__c = emAtt.Account_vod__c;
                    attStub.Contact_vod__c = emAtt.Contact_vod__c;
                    attStub.User_vod__c = emAtt.User_vod__c;
                    attStub.Attendee_vod__c = emAtt.Attendee_Name_vod__c;
                    attStub.EM_Attendee_vod__c = emAtt.Id;
                    attStub.Meal_Opt_In_vod__c = emAtt.Meal_Opt_In_vod__c;
                    attStub.Signature_vod__c = emAtt.Signature_vod__c;
                    attStub.Signature_Datetime_vod__c = emAtt.Signature_Datetime_vod__c;
                    attStub.Walk_In_Status_vod__c = emAtt.Walk_In_status_vod__c;
                    attStub.Address_Line_1_vod__c = emAtt.Address_Line_1_vod__c;
                    attStub.Address_Line_2_vod__c = emAtt.Address_Line_2_vod__c;
                    attStub.City_vod__c = emAtt.City_vod__c;
                    attStub.Phone_vod__c = emAtt.Phone_vod__c;
                    attStub.Zip_vod__c = emAtt.Zip_vod__c;
                    attStub.Email_vod__c = emAtt.Email_vod__c;
                    attStub.Prescriber_vod__c = emAtt.Prescriber_vod__c;
                    attStub.First_Name_vod__c = emAtt.First_Name_vod__c;
                    attStub.Last_Name_vod__c = emAtt.Last_Name_vod__c;
                    attStub.Organization_vod__c = emAtt.Organization_vod__c;
                    attStub.Override_Lock_vod__c = true;
                    if (emAtt.RecordType != null && rtNameToId.get(emAtt.RecordType.DeveloperName) != null) {
                        attStub.RecordTypeId = rtNameToId.get(emAtt.RecordType.DeveloperName);
                    }
                    if (statusMap.get(emAtt.Status_vod__c) != null) {
                        attStub.Status_vod__c = statusMap.get(emAtt.Status_vod__c);
                    } else {
                        attStub.Status_vod__c = emAtt.Status_vod__c;
                    }
                    for(String mfield: mappedFields) {
                        attStub.put(mfield, emAtt.get(mfield));
                    }
                    attStubs.add(attStub);
                }
            }

            if(attStubs.size() > 0) {
            	update attStubs;
            }
        }
    }
}