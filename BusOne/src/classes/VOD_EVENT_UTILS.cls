public class VOD_EVENT_UTILS {
	public static List<EM_Event_vod__c> rollupCountsToEvent(Set<Id> eventIds) {

    	Set<String> validStatuses = VOD_Utils.getAttendeeStatuses();
        Set<String> speakerStatuses = SpeakerYTDCalculator.getSpeakerStatuses();

        List<EM_Attendee_vod__c> attendees = [SELECT Status_vod__c, Meal_Opt_In_vod__c, Walk_In_Status_vod__c, Online_Registration_Status_vod__c, Event_vod__c, Account_vod__c FROM EM_Attendee_vod__c WHERE Event_vod__c IN: eventIds];
        List<EM_Event_Speaker_vod__c> speakers = [SELECT Status_vod__c, Meal_Opt_In_vod__c, Event_vod__c, Account_vod__c FROM EM_Event_Speaker_vod__c WHERE Event_vod__c IN: eventIds];

        Map<Id, EM_Event_vod__c> eventsToUpdate = new Map<Id, EM_Event_vod__c>();

        Map<Id, Decimal> eventToAggregateCost = getAggregateCosts(eventIds);

        for(Id eventId: eventIds) {
        	EM_Event_vod__C event = new EM_Event_vod__c(Id = eventId,
                                            Invited_Attendees_vod__c = 0,
                                            Walk_In_Count_vod__c = 0,
                                            Online_Registrant_Count_vod__c = 0,
                                            Actual_Attendance_vod__c = 0,
                                            Attendees_Requesting_Meals_vod__c = 0,
                                            Attendees_With_Meals_vod__c = 0,
                                            HCPs_With_Meals_vod__c = 0);
            eventsToUpdate.put(eventId, event);
        }

        for(EM_Attendee_vod__c attendee: attendees) {
            EM_Event_vod__c event = eventsToUpdate.get(attendee.Event_vod__c);

            event.Invited_Attendees_vod__c += 1;

            boolean validStatus = validStatuses.contains(attendee.Status_vod__c);
            boolean mealOptIn = attendee.Meal_Opt_In_vod__c;
            boolean isWalkIn = attendee.Walk_In_Status_vod__c != null;
            boolean isOnlineRegistrant = attendee.Online_Registration_Status_vod__c != null;

            if(isWalkIn) {
            	event.Walk_In_Count_vod__c += 1;
            }

            if(isOnlineRegistrant) {
            	event.Online_Registrant_Count_vod__c += 1;
            }

            if(validStatus) {
                event.Actual_Attendance_vod__c += 1;

            }

            if(mealOptIn) {
                event.Attendees_Requesting_Meals_vod__c += 1;
            }

            if(mealOptIn && validStatus) {
                event.Attendees_With_Meals_vod__c += 1;
                Decimal cost = eventToAggregateCost.get(event.Id) == null? 0: eventToAggregateCost.get(event.Id);
                VOD_EXPENSE_LINE_TRIG.rollUpMeals(event, cost, true);
            }

            if(attendee.Account_vod__c != null && validStatus && mealOptIn) {
            	event.HCPs_With_Meals_vod__c += 1;
            }
            eventsToUpdate.put(attendee.Event_vod__c, event);
        }

        for (EM_Event_Speaker_vod__c speaker : speakers) {
            EM_Event_vod__c event = eventsToUpdate.get(speaker.Event_vod__c);

            EM_Event_Speaker_vod__c oldSpeaker;
            boolean rollupStatus = speakerStatuses.contains(speaker.Status_vod__c);
            boolean mealOptIn = speaker.Meal_Opt_In_vod__c;

            event.Invited_Attendees_vod__c += 1;

            if (rollupStatus) {
            	event.Actual_Attendance_vod__c += 1;
            }

            if (mealOptIn) {
            	event.Attendees_Requesting_Meals_vod__c += 1;
            }

            if (mealOptIn && rollupStatus) {
                event.Attendees_With_Meals_vod__c += 1;
                Decimal cost = eventToAggregateCost.get(event.Id) == null? 0: eventToAggregateCost.get(event.Id);
                VOD_EXPENSE_LINE_TRIG.rollUpMeals(event, cost, true);
            }

            if (speaker.Account_vod__c != null && rollupStatus && mealOptIn) {
            	event.HCPs_With_Meals_vod__c += 1;
            }
            eventsToUpdate.put(speaker.Event_vod__c, event);
        }

		return eventsToUpdate.values();

    }

    public static void updateAttendeeStub(Map<String, String> idToStubMap) {
        if(System.isFuture() || System.isBatch()) {
        	updateAttendeeStubSync(idToStubMap);
        } else {
        	updateAttendeeStubFuture(idToStubMap);
        }
    }

    @future
    public static void updateAttendeeStubFuture(Map<String, String> idToStubMap) {
        updateAttendeeStubSync(idToStubMap);
    }

    public static void updateAttendeeStubSync(Map<String, String> idToStubMap) {
    	List<EM_Attendee_vod__c> updateAttendees = new List<EM_Attendee_vod__c>();
        for(String keyId: idToStubMap.keySet()) {
            String stubId = idtoStubMap.get(keyId);
            updateAttendees.add(new EM_Attendee_vod__c(Id = keyId, Stub_SFDC_Id_vod__c = stubId));
        }
        if(updateAttendees.size() > 0) {
            update updateAttendees;
        }
    }

    public static void updateSpeakerStub(Map<String, String> idToStubMap) {
        if(System.isFuture() || System.isBatch()) {
        	updateSpeakerStubSync(idToStubMap);
        } else {
        	updateSpeakerStubFuture(idToStubMap);
        }
    }

    @future
    public static void updateSpeakerStubFuture(Map<String, String> idToStubMap) {
        updateSpeakerStubSync(idToStubMap);
    }

    public static void updateSpeakerStubSync(Map<String, String> idToStubMap) {
    	List<EM_Event_Speaker_vod__c> updateSpeakers = new List<EM_Event_Speaker_vod__c>();
        for(String keyId: idToStubMap.keySet()) {
            String stubId = idtoStubMap.get(keyId);
            updateSpeakers.add(new EM_Event_Speaker_vod__c(Id = keyId, Stub_SFDC_Id_vod__c = stubId));
        }
        if(updateSpeakers.size() > 0) {
            update updateSpeakers;
        }
    }

    public static Map<Id, Decimal> getAggregateCosts(Set<Id> eventIds) {
        boolean multiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

        List<Expense_Line_vod__c> expenseLines = new List<Expense_Line_vod__c>();

        if(multiCurrency) {
        	expenseLines = Database.query('SELECT Event_vod__c, Actual_vod__c, CurrencyIsoCode, Event_vod__r.CurrencyIsoCode FROM Expense_Line_vod__c WHERE Expense_Type_vod__r.Meal_Expense_vod__c = true AND Event_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(eventIds));
        } else {
        	expenseLines = [SELECT Event_vod__c, Actual_vod__c FROM Expense_Line_vod__c
                            WHERE Expense_Type_vod__r.Meal_Expense_vod__c = true AND Event_vod__c IN : eventIds];
        }

        Map<Id, Decimal> eventToAggregateCost = new Map<Id, Decimal>();

        for (Expense_Line_vod__c line : expenseLines) {
            if(eventToAggregateCost.get(line.Event_vod__c) == null) {
                eventToAggregateCost.put(line.Event_vod__c, 0);
            }
            Decimal lineCost = line.Actual_vod__c != null ? line.Actual_vod__c : 0;
            Decimal eventAggregate = eventToAggregateCost.get(line.Event_vod__c);

            if(multiCurrency) {
                lineCost = MultiCurrencyUtil.convertCurrency((String)line.get('CurrencyIsoCode'), (String)line.getSobject('Event_vod__r').get('CurrencyIsoCode'), lineCost);
            }
            eventAggregate += lineCost;
            eventToAggregateCost.put(line.Event_vod__c, eventAggregate);
        }

        return eventToAggregateCost;
    }
}