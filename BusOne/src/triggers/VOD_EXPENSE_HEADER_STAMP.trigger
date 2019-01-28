trigger VOD_EXPENSE_HEADER_STAMP on Expense_Header_vod__c (before insert, before update) {
    Set<Id> eventIds = new Set<Id>();
    Set<ID> accountIds = new Set<ID>();
    Set<ID> attendeeIds = new Set<ID>();
    Set<ID> speakerIds = new Set<ID>();
    Set<ID> teamMemberIds = new Set<ID>();
    Set<ID> vendorIds = new Set<ID>();
    Set<ID> venueIds = new Set<ID>();
    SET<ID> headerIds = new SET<ID>();
	
    Map<Id, Id> attendeeToAccountMap = new Map<Id, Id>();
    
    if(Trigger.isUpdate) {
		for(Expense_Header_vod__c header: Trigger.old) {
            accountIds.add(header.Incurred_Expense_Account_vod__c);
            speakerIds.add(header.Incurred_Expense_Speaker_vod__c);
            
            accountIds.add(header.Payee_Account_vod__c);
            speakerIds.add(header.Payee_Speaker_vod__c);
            headerIds.add(header.Id);
        }        
    }

    for(Expense_Header_vod__c header: Trigger.New) {
        if(header.Split_Lines_vod__c == 'Yes_vod') {
        	header.Incurred_Expense_Account_vod__c = null;
			header.Incurred_Expense_Attendee_vod__c = null;
            header.Incurred_Expense_Speaker_vod__c = null;
			header.Incurred_Expense_Team_Member_vod__c = null;
			header.Incurred_Expense_Vendor_vod__c = null;
			header.Incurred_Expense_Venue_vod__c = null;  	
        }
        
        eventIds.add(header.Event_vod__c);
		accountIds.add(header.Incurred_Expense_Account_vod__c);
		attendeeIds.add(header.Incurred_Expense_Attendee_vod__c);
        speakerIds.add(header.Incurred_Expense_Speaker_vod__c);
		teamMemberIds.add(header.Incurred_Expense_Team_Member_vod__c);
		vendorIds.add(header.Incurred_Expense_Vendor_vod__c);
		venueIds.add(header.Incurred_Expense_Venue_vod__c);   
        
        accountIds.add(header.Payee_Account_vod__c);
		attendeeIds.add(header.Payee_Attendee_vod__c);
        speakerIds.add(header.Payee_Speaker_vod__c);
		teamMemberIds.add(header.Payee_Team_Member_vod__c);
		vendorIds.add(header.Payee_Vendor_vod__c);
		venueIds.add(header.Payee_Venue_vod__c);
        headerIds.add(header.Id);
    }
    
	Map<Id, Account> accounts = new Map<Id, Account>();
    Map<Id, EM_Attendee_vod__c> attendees = new Map<Id, EM_Attendee_vod__c>();
    Map<Id, EM_Event_Speaker_vod__c> speakers = new Map<Id, EM_Event_Speaker_vod__c>();
    Map<Id, EM_Event_Team_Member_vod__c> teamMembers = new Map<Id, EM_Event_Team_Member_vod__c>();
    Map<Id, EM_Vendor_vod__c> vendors = new Map<Id, EM_Vendor_vod__c>();
    Map<Id, EM_Venue_vod__c> venues = new Map<Id, EM_Venue_vod__c>();   
    Set<Id> speakerIdsToUpdate = new Set<Id>();

    List<EM_Event_vod__c> events = [SELECT Id, Override_Lock_vod__c, Lock_vod__c,
                                    (SELECT Id, Attendee_Name_vod__c FROM EM_Attendee_Event_vod__r WHERE Id in :attendeeIds),
                                    (SELECT Id, Speaker_Name_vod__c, Speaker_vod__c, Speaker_vod__r.Year_to_Date_Spend_vod__c FROM EM_Event_Speaker_vod__r WHERE Id in :speakerIds),
                                    (SELECT Id, Name FROM EM_Event_Team_Member_vod__r WHERE Id in :teamMemberIds)
                                    FROM EM_Event_vod__c WHERE Id IN : eventIds];
    
    List<Expense_Line_vod__c> expenseLines = [SELECT Expense_Header_vod__c, Expense_Type_vod__r.Included_In_Speaker_Cap_vod__c, Actual_vod__c FROM Expense_Line_vod__c 
                                              WHERE Expense_Header_vod__c IN :headerIds];
    Set<Id> lockedEvents = new Set<Id>();
    for (EM_Event_vod__c event : events) {
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
        if (event.EM_Attendee_Event_vod__r != null) {
            for (EM_Attendee_vod__c attendee : event.EM_Attendee_Event_vod__r) {
                attendees.put(attendee.Id, attendee);
            }
        }
        if (event.EM_Event_Speaker_vod__r != null) {
            for (EM_Event_Speaker_vod__c speaker : event.EM_Event_Speaker_vod__r) {
                speakers.put(speaker.Id, speaker);
            }
        }
        if (event.EM_Event_Team_Member_vod__r != null) {
            for (EM_Event_Team_Member_vod__c teamMember : event.EM_Event_Team_Member_vod__r) {
                teamMembers.put(teamMember.Id, teamMember);
            }
        }
    }

    if(accountIds.size() > 0) {
        for(Account account: [SELECT Id, Name, (SELECT Id, Year_To_date_Spend_vod__c FROM EM_Speaker_vod__r) FROM Account WHERE Id in :accountIds]) {
            accounts.put(account.Id, account);
        }
    }
    
    if(attendeeIds.size() > 0) {
        for(EM_Attendee_vod__c attendee: [SELECT Id, Account_vod__c FROM EM_Attendee_vod__c WHERE Id IN :attendeeIds]) {
            attendeeToAccountMap.put(attendee.Id, attendee.Account_vod__c);
            accountIds.add(attendee.Account_vod__c);
        }
    }
    
    if(vendorIds.size() > 0) {
        for(EM_Vendor_vod__c vendor: [SELECT Id, Name FROM EM_Vendor_vod__c WHERE Id in :vendorIds]) {
            vendors.put(vendor.Id, vendor);
        }
    }
    
    if(venueIds.size() > 0) {
        for(EM_Venue_vod__c venue: [SELECT Id, NAME FROM EM_Venue_vod__c WHERE Id in :venueIds]) {
            venues.put(venue.Id, venue);
        }
    }

    for(Expense_Header_vod__c header: Trigger.New) {
        Expense_Header_vod__c oldHeader;
        
        if(Trigger.isUpdate) {
            oldHeader = Trigger.oldMap.get(header.Id);
        }
        String payeeName;
        String incurredExpenseName;

        if(header.Override_Lock_vod__c == true) {
            header.Override_Lock_vod__c = false;
        } else if (header.Event_vod__c != null && lockedEvents.contains(header.Event_vod__c)) {
            header.addError('Event is locked');
        }
        
        if(header.Incurred_Expense_Account_vod__c != null) {
            Account account = accounts.get(header.Incurred_Expense_Account_vod__c); 
            if(account != null) {				
                incurredExpenseName = account.Name;    
            }         
        }
        
        if(oldHeader != null && oldHeader.Incurred_Expense_Account_vod__c != header.Incurred_Expense_Account_vod__c) { 
            Account oldAccount = accounts.get(oldHeader.Incurred_Expense_Account_vod__c);
            Account account = accounts.get(header.Incurred_Expense_Account_vod__c); 

            if(account != null && account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {				    
                EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                speakerIdstoUpdate.add(updateSpeaker.Id);   
            }  
            
            if(oldAccount != null && oldAccount.EM_Speaker_vod__r != null && !oldAccount.EM_Speaker_vod__r.isEmpty()) {     
                EM_Speaker_vod__c oldUpdateSpeaker = oldAccount.EM_Speaker_vod__r;
                speakerIdsToUpdate.add(oldUpdateSpeaker.Id);
            }
        }
        
        if(header.Incurred_Expense_Attendee_vod__c != null) {
            if(oldHeader != null) {
            	Account oldAccount = accounts.get(attendeeToAccountMap.get(oldheader.Incurred_Expense_Attendee_vod__c));
                Account account = accounts.get(attendeeToAccountMap.get(header.Incurred_Expense_Attendee_vod__c)); 
                
                if(account != null && account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {				    
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speakerIdstoUpdate.add(updateSpeaker.Id);   
                }  
                
                if(oldAccount != null && oldAccount.EM_Speaker_vod__r != null && !oldAccount.EM_Speaker_vod__r.isEmpty()) {     
                    EM_Speaker_vod__c oldUpdateSpeaker = oldAccount.EM_Speaker_vod__r;
                    speakerIdsToUpdate.add(oldUpdateSpeaker.Id);
                }     
            }
            
            if(attendees.get(header.Incurred_Expense_Attendee_vod__c ) != null) {
            	incurredExpenseName = attendees.get(header.Incurred_Expense_Attendee_vod__c ).Attendee_Name_vod__c;    
            }	    
        }
        
        if(header.Incurred_Expense_Speaker_vod__c != null) {
            EM_Event_Speaker_vod__c speaker = speakers.get(header.Incurred_Expense_Speaker_vod__c);
            if(speaker != null) {
                speakerIdstoUpdate.add(speaker.Speaker_vod__c);
                incurredExpenseName = speaker.Speaker_Name_vod__c; 
            }    
        }

        if(oldHeader != null && oldHeader.Incurred_Expense_Speaker_vod__c != header.Incurred_Expense_Speaker_vod__c) {
            EM_Event_Speaker_vod__c speaker = speakers.get(header.Incurred_Expense_Speaker_vod__c);
            EM_Event_Speaker_vod__c oldspeaker = speakers.get(oldHeader.Incurred_Expense_Speaker_vod__c);

            if(speaker != null) {
                speakerIdsToUpdate.add(speaker.Speaker_vod__c);
            }
            if(oldSpeaker != null) {
                speakerIdsToUpdate.add(oldSpeaker.Speaker_vod__c);
            }
        }		        
        
        if(header.Incurred_Expense_Team_Member_vod__c != null) {
            if(teamMembers.get(header.Incurred_Expense_Team_Member_vod__c) != null) {
            	incurredExpenseName = teamMembers.get(header.Incurred_Expense_Team_Member_vod__c).Name;    
            }
        }
        
        if(header.Incurred_Expense_Vendor_vod__c != null){
            if(vendors.get(header.Incurred_Expense_Vendor_vod__c) != null) {
            	incurredExpenseName = vendors.get(header.Incurred_Expense_Vendor_vod__c).Name;    
            }
        }       
        
        if(header.Incurred_Expense_Venue_vod__c != null) {
            if(venues.get(header.Incurred_Expense_Venue_vod__c) != null) {
            	incurredExpenseName = venues.get(header.Incurred_Expense_Venue_vod__c).Name;
            }
        }       	        
        
        header.Incurred_Expense_vod__c = incurredExpenseName;
        
        if(header.Payee_Account_vod__c != null) {
            if(accounts.get(header.Payee_Account_vod__c) != null) {
            	payeeName = accounts.get(header.Payee_Account_vod__c).Name;    
            }
        }
        
        if(header.Payee_Attendee_vod__c != null) {
            if(attendees.get(header.Payee_Attendee_vod__c) != null) {
            	payeeName = attendees.get(header.Payee_Attendee_vod__c).Attendee_Name_vod__c;    
            }
        }
        
        if(header.Payee_Speaker_vod__c != null) {
            if(speakers.get(header.Payee_Speaker_vod__c) != null) {
            	payeeName = speakers.get(header.Payee_Speaker_vod__c).Speaker_Name_vod__c;    
            }
        }
        
        if(header.Payee_Team_Member_vod__c != null) {
            if(teamMembers.get(header.Payee_Team_Member_vod__c) != null) {
            	payeeName = teamMembers.get(header.Payee_Team_Member_vod__c).Name;    
            }
        }
        
        if(header.Payee_Vendor_vod__c != null) {
            if(vendors.geT(header.Payee_Vendor_vod__c) != null) {
            	payeeName = vendors.get(header.Payee_Vendor_vod__c).Name;    
            }
        }
        
        if(header.Payee_Venue_vod__c != null) {
            if(venues.get(header.Payee_Venue_vod__c) != null) {
            	payeeName = venues.get(header.Payee_Venue_vod__c).Name;    
            }

        }
                   
 		header.Payee_vod__c = payeeName;          
    	
    }
    if(!speakerIdsToUpdate.isEmpty()) {
        SpeakerYTDCalculator.calculate(speakerIdsToUpdate);
    }   
}