trigger VOD_EXPENSE_ATTRIBUTION_STAMP on Expense_Attribution_vod__c (before insert, before update) {
	Set<Id> expenseLineIds = new Set<Id>();
    Set<ID> accountIds = new Set<ID>();
    Set<ID> attendeeIds = new Set<ID>();
    Set<ID> speakerIds = new Set<ID>();
    Set<ID> teamMemberIds = new Set<ID>();
    Set<ID> vendorIds = new Set<ID>();
    Set<ID> venueIds = new Set<ID>();
    SET<ID> attrIds = new SET<ID>();

    for(Expense_Attribution_vod__c attr: Trigger.New) {        
        expenseLineIds.add(attr.Expense_Line_vod__c);
        accountIds.add(attr.Incurred_Expense_Account_vod__c);
        attendeeIds.add(attr.Incurred_Expense_Attendee_vod__c);
        speakerIds.add(attr.Incurred_Expense_Speaker_vod__c);
        teamMemberIds.add(attr.Incurred_Expense_Team_Member_vod__c);
        vendorIds.add(attr.Incurred_Expense_Vendor_vod__c);
        venueIds.add(attr.Incurred_Expense_Venue_vod__c);   
    }
    
  	Map<Id, Account> accounts = new Map<Id, Account>();
    Map<Id, EM_Attendee_vod__c> attendees = new Map<Id, EM_Attendee_vod__c>();
    Map<Id, EM_Event_Speaker_vod__c> speakers = new Map<Id, EM_Event_Speaker_vod__c>();
    Map<Id, EM_Event_Team_Member_vod__c> teamMembers = new Map<Id, EM_Event_Team_Member_vod__c>();
    Map<Id, EM_Vendor_vod__c> vendors = new Map<Id, EM_Vendor_vod__c>();
    Map<Id, EM_Venue_vod__c> venues = new Map<Id, EM_Venue_vod__c>();   
            
    List<EM_Event_vod__c> events = [SELECT (SELECT Id, Attendee_Name_vod__c FROM EM_Attendee_Event_vod__r WHERE Id in :attendeeIds),
                                    (SELECT Id, Speaker_Name_vod__c, Speaker_vod__c, Speaker_vod__r.Year_to_Date_Spend_vod__c FROM EM_Event_Speaker_vod__r WHERE Id in :speakerIds),
                                    (SELECT Id, Name FROM EM_Event_Team_Member_vod__r WHERE Id in :teamMemberIds)
                                    FROM EM_Event_vod__c WHERE Id IN (Select Event_vod__c FROM Expense_Line_vod__c WHERE Id IN :expenseLineIds)];
    
    
    for (EM_Event_vod__c event : events) {
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
        for(Account account: [SELECT Id, Name FROM Account WHERE Id in :accountIds]) {
            accounts.put(account.Id, account);
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

    for(Expense_Attribution_vod__c attr: Trigger.New) {        
        String incurredExpenseName;
        
        if(attr.Incurred_Expense_Account_vod__c != null) {
            Account account = accounts.get(attr.Incurred_Expense_Account_vod__c); 
            if(account != null) {        
                incurredExpenseName = account.Name;    
            }         
        }      
        
        if(attr.Incurred_Expense_Attendee_vod__c != null) {
            if(attendees.get(attr.Incurred_Expense_Attendee_vod__c ) != null) {
              incurredExpenseName = attendees.get(attr.Incurred_Expense_Attendee_vod__c ).Attendee_Name_vod__c;    
            }      
        }
        
        if(attr.Incurred_Expense_Speaker_vod__c != null) {
            EM_Event_Speaker_vod__c speaker = speakers.get(attr.Incurred_Expense_Speaker_vod__c);
            if(speaker != null) {
                incurredExpenseName = speaker.Speaker_Name_vod__c; 
            }    
        }                   
        
        if(attr.Incurred_Expense_Team_Member_vod__c != null) {
            if(teamMembers.get(attr.Incurred_Expense_Team_Member_vod__c) != null) {
              incurredExpenseName = teamMembers.get(attr.Incurred_Expense_Team_Member_vod__c).Name;    
            }
        }
        
        if(attr.Incurred_Expense_Vendor_vod__c != null){
            if(vendors.get(attr.Incurred_Expense_Vendor_vod__c) != null) {
              incurredExpenseName = vendors.get(attr.Incurred_Expense_Vendor_vod__c).Name;    
            }
        }       
        
        if(attr.Incurred_Expense_Venue_vod__c != null) {
            if(venues.get(attr.Incurred_Expense_Venue_vod__c) != null) {
              incurredExpenseName = venues.get(attr.Incurred_Expense_Venue_vod__c).Name;
            }
        }                 
        
        attr.Incurred_Expense_vod__c = incurredExpenseName;
    }
}