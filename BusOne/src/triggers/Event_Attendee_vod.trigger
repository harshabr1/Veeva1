trigger Event_Attendee_vod on Event_Attendee_vod__c (before update, before insert) {   
    Set<String> accountIds = new Set<String>();
    Set<String> contactIds = new Set<String>();
    Set<String> userIds = new Set<String>();
    VOD_Utils.setTriggerEventAttendee(true);
    // assumption is we will only get one of the below values per record
    for (Integer i=0; i < Trigger.new.size(); i++) {
        if (Trigger.new[i].Entity_Reference_Id_vod__c != null) {
            Trigger.new[i].Account_vod__c = Trigger.new[i].Entity_Reference_Id_vod__c;
            accountIds.add(Trigger.new[i].Account_vod__c);
        } else if (Trigger.new[i].Account_vod__c != null) {
            accountIds.add(Trigger.new[i].Account_vod__c);
        } else if (Trigger.new[i].Contact_vod__c != null) {
            contactIds.add(Trigger.new[i].Contact_vod__c);
        } else if (Trigger.new[i].User_vod__c != null) {
            userIds.add(Trigger.new[i].User_vod__c);
        }
    }

    Map<Id, Account> accounts = new Map<Id, Account>();
    if (accountIds.size() > 0) {
        accounts = new Map<Id, Account>([Select Id,Name,Formatted_Name_vod__c,FirstName,LastName From Account Where Id In :accountIds]);
    }
    Map<Id, Contact> contacts = new Map<Id, Contact>();
    if (contactIds.size() > 0) {
        contacts = new Map<Id, Contact>([Select Id,Name,FirstName,LastName From Contact Where Id In :contactIds]);
    }
    Map<Id, User> users = new Map<Id, User>();
    if (userIds.size() > 0) {
        users = new Map<Id, User>([Select Id,Name,FirstName,LastName From User Where Id In :userIds]);
    }

    for (Integer i=0; i < Trigger.new.size(); i++) {
        String attendeeName = '';
        String attendeeFirstName = '';
        String attendeeLastName = '';
        if (Trigger.new[i].Account_vod__c != null) {
            Account acct = accounts.get(Trigger.new[i].Account_vod__c);
            if (acct != null) {
                if (acct.Formatted_Name_vod__c != null) {
                    attendeeName = acct.Formatted_Name_vod__c;
                } else if (acct.LastName != null && acct.FirstName != null) {
                    attendeeName = acct.LastName + ', ' + acct.FirstName;
                } else {
                    attendeeName = acct.Name;
                }

                if(acct.LastName != null) {
                	attendeeLastName = acct.LastName;
                }

                if(acct.FirstName != null) {
                    attendeeFirstName = acct.FirstName;
                }
            }
        } else if (Trigger.new[i].Contact_vod__c != null) {
            Contact ctct = contacts.get(Trigger.new[i].Contact_vod__c);
            if (ctct != null) {
                if (ctct.LastName != null && ctct.FirstName != null) {
                    attendeeName = ctct.LastName + ', ' + ctct.FirstName;
                } else {
                    attendeeName = ctct.Name;
                }

                if(ctct.LastName != null) {
                	attendeeLastName = ctct.LastName;
                }

                if(ctct.FirstName != null) {
                    attendeeFirstName = ctct.FirstName;
                }
            }
        } else if (Trigger.new[i].User_vod__c != null) {
            User usr = users.get(Trigger.new[i].User_vod__c);
            if (usr != null) {
                if (usr.LastName != null && usr.FirstName != null) {
                    attendeeName = usr.LastName + ', ' + usr.FirstName;
                } else {
                    attendeeName = usr.Name;
                }

                if(usr.LastName != null) {
                	attendeeLastName = usr.LastName;
                }

                if(usr.FirstName != null) {
                    attendeeFirstName = usr.FirstName;
                }
            }
        }
        if (attendeeName != '') {
            Trigger.new[i].Attendee_vod__c = attendeeName;
        }

        if(attendeeFirstName != '') {
        	Trigger.new[i].First_Name_vod__c = attendeeFirstName;
        }

        if(attendeeLastName != '') {
        	Trigger.new[i].Last_Name_vod__c = attendeeLastName;
        }
    }    

	if(Trigger.IsInsert &&!VOD_Utils.isTriggerEmAttendee() && !VOD_Utils.isTriggerEmSpeaker()) {
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
        Map<ID,Schema.RecordTypeInfo> eaRTMap = Event_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosById();
        Map<String,Schema.RecordTypeInfo> emRTMap = EM_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        for (Integer i=0; i<Trigger.new.size(); i++) {
            Event_Attendee_vod__c attStub = Trigger.new[i];
            if (medEventIdsToEmEventIds.get(attStub.Medical_Event_vod__c) != null) {
                if(attStub.Mobile_ID_vod__c == null) {
                    attStub.Mobile_ID_vod__c = GuidUtil.NewGuid();
                }
                EM_Attendee_vod__c newEmAtt = new EM_Attendee_vod__c(
                    Entity_Reference_Id_vod__c = attStub.Entity_Reference_Id_vod__c,
                    Account_vod__c = attStub.Account_vod__c,
                    Contact_vod__c = attStub.Contact_vod__c,
                    User_vod__c = attStub.User_vod__c,
                    Attendee_Name_vod__c = attStub.Attendee_vod__c,
                    Signee_vod__c = attStub.Signee_vod__c,
                    Signature_Datetime_vod__c = attStub.Signature_Datetime_vod__c,
                    Signature_vod__c = attStub.Signature_vod__c,
                    Meal_Opt_In_vod__c = attStub.Meal_Opt_In_vod__c,
                    Event_vod__c = medEventIdsToEmEventIds.get(attStub.Medical_Event_vod__c),
                    Walk_In_Status_vod__c = attStub.Walk_In_Status_vod__c,
                    Address_Line_1_vod__c = attStub.Address_Line_1_vod__c,
                    Address_Line_2_vod__c = attStub.Address_Line_2_vod__c,
                    City_vod__c = attStub.City_vod__c,
                    Zip_vod__c = attStub.Zip_vod__c,
                    Phone_vod__c = attStub.Phone_vod__c,
                    Email_vod__c = attStub.Email_vod__c,
                    Prescriber_vod__c = attStub.Prescriber_vod__c,
                    First_Name_vod__c = attStub.First_Name_vod__c,
                    Last_Name_vod__c = attStub.Last_Name_vod__c,
                    Organization_vod__c = attStub.Organization_vod__c,
                    Stub_Mobile_ID_vod__c = attStub.Mobile_ID_vod__c,
                    Override_Lock_vod__c = true
                );
                RecordTypeInfo eaInfo = emRTMap.get(eaRTMap.get(attStub.RecordTypeId).getName());
                if(eaInfo != null && eaInfo.isAvailable()) {
                    newEmAtt.RecordTypeId = eaInfo.getRecordTypeId();
                }

                if (statusMap.get(attStub.Status_vod__c) != null) {
                    newEmAtt.Status_vod__c = statusMap.get(attStub.Status_vod__c);
                } else {
                    newEmAtt.Status_vod__c = attStub.Status_vod__c;
                }
                for(String mfield: mappedFields) {
                    newEmAtt.put(mfield, attStub.get(mfield));
                }
                emAtts.add(newEmAtt);
            }
        }
        if (emAtts.size() > 0) {
            List<Event_Attendee_vod__c> updateAttendees = new List<Event_Attendee_vod__c>();
            Database.SaveResult[] emAttResults = Database.insert(emAtts);
            for (Integer i=0; i<Trigger.new.size(); i++) {
                Event_Attendee_vod__c attStub = Trigger.new[i];
                Database.SaveResult createdEmAtt = emAttResults.get(i);
                if (createdEmAtt.getId() != null) {
                    attStub.EM_Attendee_vod__c = createdEmAtt.getId();
                }
            }

        }
	}
}