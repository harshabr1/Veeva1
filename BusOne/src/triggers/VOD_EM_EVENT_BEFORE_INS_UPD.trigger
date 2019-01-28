trigger VOD_EM_EVENT_BEFORE_INS_UPD on EM_Event_vod__c (before insert, before update) {
    Map<String, String> eventToVenue = new Map<String, String>();
    Map<String, String[]> venueToAddress = new Map<String, String[]>();
    Set<String> venueSet = new Set<String>();
	boolean failedExpense = false;

    VOD_Utils.setTriggerEMEvent(true);
	List<Medical_Event_vod__c> medEventStubs = new List<Medical_Event_vod__c>();
    List<EM_Event_History_vod__c> histories = new List<EM_Event_History_vod__c>();
    boolean hasOwner = Schema.getGlobalDescribe().get('Medical_Event_vod__c').getDescribe().fields.getMap().keySet().contains('OwnerId');
    boolean isAutoNumber = Schema.getGlobalDescribe().get('Medical_Event_vod__c').getDescribe().fields.getMap().get('Name').getDescribe().isAutoNumber();

    for (EM_Event_vod__c event : Trigger.new) {
        if (event.Venue_vod__c != null) {
            eventToVenue.put(event.Id, event.Venue_vod__c);
            venueSet.add(event.Venue_vod__c);
        }
        if(event.Failed_Expense_vod__c) {
            failedExpense = true;
        }
    }

    boolean stampVenue = false;
    if(Trigger.isInsert) {
        stampVenue = true;
    } else if (Trigger.isUpdate) {
        for(EM_Event_vod__c newEvent: Trigger.new) {
            EM_Event_vod__c oldEvent = Trigger.oldMap.get(newEvent.Id);
            if(newEvent.Venue_vod__c != oldEvent.Venue_vod__c) {
                stampVenue = true;
                break;
            }
        }
    }
    if(stampVenue) {
    	for (EM_Venue_vod__c venue : [SELECT Id, Name, Address_vod__c, Address_Line_2_vod__c, City_vod__c, State_Province_vod__c, Postal_Code_vod__c
                               		  FROM EM_Venue_vod__c
                                      WHERE Id IN :venueSet]) {
        	venueToAddress.put(venue.Id, new String[] {venue.Name, venue.Address_vod__c, venue.Address_Line_2_vod__c, venue.City_vod__c, venue.State_Province_vod__c, venue.Postal_Code_vod__c});
    	}
    }

    if(failedExpense) {
        Set<Id> failedExpenseEvents = new Set<Id>();
        for(Expense_Header_vod__c header: [SELECT Event_vod__c FROM Expense_Header_vod__c WHERE Event_vod__c IN :Trigger.newMap.keySet() AND Concur_Status_vod__c IN ('Failed_Connection_vod', 'Failed_Config_vod', 'Failed_Duplicate_vod')]) {
            failedExpenseEvents.add(header.Event_vod__c);
        }
        for(EM_Event_vod__c event: Trigger.new) {
            event.Failed_Expense_vod__c = failedExpenseEvents.contains(event.Id);
        }
    }

    for (EM_Event_vod__c event : Trigger.new) {
        if((event.Walk_In_Fields_vod__c == null 
            || event.Online_Registration_Fields_vod__c == null 
            || event.Account_Attendee_Fields_vod__c == null 
            || event.User_Attendee_Fields_vod__c == null 
            || event.Contact_Attendee_Fields_vod__c == null) 
           	&& event.Event_Configuration_vod__c != null) {
            List<EM_Event_Rule_vod__c> eventRules = [SELECT Walk_In_Fields_vod__c, Online_Registration_Fields_vod__c, Account_Attendee_Fields_vod__c, User_Attendee_Fields_vod__c, Contact_Attendee_Fields_vod__c, 
                                                     		RecordType.DeveloperName, Country_Override_vod__c
                                                     FROM EM_Event_Rule_vod__c
                                                     WHERE RecordType.DeveloperName IN ('Walk_In_Fields_vod', 'Online_Registration_Fields_vod', 'Attendee_Fields_vod') AND
                                                       Event_Configuration_vod__c =:event.Event_Configuration_vod__c AND
                                                       (Country_Override_vod__c = NULL OR
                                                       (Country_Override_vod__r.Country_vod__c =:event.Country_vod__c AND
                                                       Country_Override_vod__r.Event_Configuration_vod__c =:event.Event_Configuration_vod__c))
                                                    ];
            EM_Event_Rule_vod__c resultWalkInRule;
            EM_Event_Rule_vod__c resultRegistrationRule;
            EM_Event_Rule_vod__c resultAttendeeFieldsRule;
            List<EM_Event_Rule_vod__c> walkInList = new List<EM_Event_Rule_vod__c>(); 
            List<EM_Event_Rule_vod__c> registrationList = new List<EM_Event_Rule_vod__c>();
            List<EM_Event_Rule_vod__c> attendeeFieldsList = new List<EM_Event_Rule_vod__c>();
            
            for(EM_Event_Rule_vod__c rule: eventRules) {
                if(rule.RecordType.DeveloperName == 'Walk_In_Fields_vod') {
                    walkInList.add(rule);
                } else if(rule.RecordType.DeveloperName == 'Online_Registration_Fields_vod') {
                    registrationList.add(rule);
                } else if(rule.RecordType.DeveloperName == 'Attendee_Fields_vod') {
                	attendeeFieldsList.add(rule);    
                }
            }
            
            if (walkInList.size() == 1) {
                resultWalkInRule = walkInList.get(0);
            } else if (walkInList.size() == 2) {
                for (EM_Event_Rule_vod__c row : walkInList) {
                    if (row.Country_Override_vod__c != null) {
                        resultWalkInRule = row;
                        break;
                    }
                }
            }
            
            if (registrationList.size() == 1) {
                resultRegistrationRule = registrationList.get(0);
            } else if (registrationList.size() == 2) {
                for (EM_Event_Rule_vod__c row : registrationList) {
                    if (row.Country_Override_vod__c != null) {
                        resultRegistrationRule = row;
                        break;
                    }
                }
            }
            
            if(attendeeFieldsList.size() == 1) {
                resultAttendeeFieldsRule = attendeeFieldsList.get(0);
            } else if (attendeeFieldsList.size() == 2) {
                for (EM_Event_Rule_vod__c row: attendeeFieldsList) {
                    if(row.Country_Override_vod__c != null) {
                        resultAttendeeFieldsRule = row;
                        break;
                    }
                }
            }

            if(resultWalkInRule != null && resultWalkInRule.Walk_In_Fields_vod__c != null) {
                event.Walk_In_Fields_vod__c = resultWalkInRule.Walk_In_Fields_vod__c;
            }
            
            if(resultRegistrationRule != null && resultRegistrationRule.Online_Registration_Fields_vod__c != null) {
                event.Online_Registration_Fields_vod__c = resultRegistrationRule.Online_Registration_Fields_vod__c;
            }
            
            if(resultAttendeeFieldsRule != null && 
               (resultAttendeeFieldsRule.Account_Attendee_Fields_vod__c != null
               	|| resultAttendeeFieldsRule.User_Attendee_Fields_vod__c != null
               	|| resultAttendeeFieldsRule.Contact_Attendee_Fields_vod__c != null)) {
                event.Account_Attendee_Fields_vod__c = resultAttendeeFieldsRule.Account_Attendee_Fields_vod__c;
                event.User_Attendee_Fields_vod__c = resultAttendeeFieldsRule.User_Attendee_Fields_vod__c;
                event.Contact_Attendee_Fields_vod__c = resultAttendeeFieldsRule.Contact_Attendee_Fields_vod__c;
            }
        }
        String venue = eventToVenue.get(event.Id);
        if (venue != null) {
            String[] address = venueToAddress.get(venue);
            if(address != null) {
            	event.Location_vod__c = address[0];
                event.Location_Address_vod__c = address[1];
                event.Location_Address_Line_2_vod__c = address[2];
                event.City_vod__c = address[3];
                event.State_Province_vod__c = address[4];
                event.Postal_Code_vod__c = address[5];    
            }           
        }
    }
}