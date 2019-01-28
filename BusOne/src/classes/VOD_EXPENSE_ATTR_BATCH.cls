global with sharing class VOD_EXPENSE_ATTR_BATCH implements Database.Batchable<sObject>, Schedulable {

    String query;
    
    global VOD_EXPENSE_ATTR_BATCH() {
        
    }
    
	global Database.QueryLocator start(Database.BatchableContext BC) {
        
		// This is the base query that drives the chunking.
		query = 'SELECT Id,(SELECT Id, Incurred_Expense_vod__c FROM Expense_Attributions_vod__r),' +
            	'Expense_Header_vod__r.Incurred_Expense_vod__c, ' +
                'Expense_Header_vod__r.Incurred_Expense_Account_vod__c, ' + 
                'Expense_Header_vod__r.Incurred_Expense_Attendee_vod__c, ' +
                'Expense_Header_vod__r.Incurred_Expense_Speaker_vod__c, ' + 
            	'Expense_Header_vod__r.Incurred_Expense_Team_Member_vod__c, ' +
            	'Expense_Header_vod__r.Incurred_Expense_Vendor_vod__c, ' +
            	'Expense_Header_vod__r.Incurred_Expense_Venue_vod__c ' +
            	'FROM Expense_Line_vod__c ' +
            	'WHERE Expense_Header_vod__r.Incurred_Expense_vod__c != null ' +
            	'AND Expense_Header_vod__r.Split_Lines_vod__c != \'Yes_vod\' ' +
            	'AND Event_vod__r.Lock_vod__c = false';
		
		return Database.getQueryLocator(query);
	}
    
    global void execute(SchedulableContext sc) {
        Database.Batchable<SObject> b = new VOD_EXPENSE_ATTR_BATCH();
        Database.executeBatch(b, 50);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
        List<Expense_Attribution_vod__c> attrsToUpsert = new List<Expense_Attribution_vod__c>();
        
        for (sObject obj : batch) {
			Expense_Line_vod__c line = (Expense_Line_vod__c)obj;
            List<Expense_Attribution_vod__c> attrs = line.Expense_Attributions_vod__r;
            Id incurredId;
            String incurredType = '';
            Expense_Header_vod__c header = line.Expense_Header_vod__r;
            if(header.Incurred_Expense_Account_vod__c != null) {
                incurredType = 'Account_vod';
                incurredId = header.Incurred_Expense_Account_vod__c;
            } else if (header.Incurred_Expense_Attendee_vod__c != null) {
                incurredType = 'Attendee_vod';
                incurredId = header.Incurred_Expense_Attendee_vod__c;
            } else if (header.Incurred_Expense_Speaker_vod__c != null) {
                incurredType = 'Event_Speaker_vod';
                incurredId = header.Incurred_Expense_Speaker_vod__c;
            } else if (header.Incurred_Expense_Team_Member_vod__c != null) {
                incurredType = 'Event_Team_Member_vod';
                incurredId = header.Incurred_Expense_Team_Member_vod__c;
            } else if (header.Incurred_Expense_Vendor_vod__c != null) {
                incurredType = 'Vendor_vod';
                incurredId = header.Incurred_Expense_Team_Member_vod__c;
            } else if (header.Incurred_Expense_Venue_vod__c != null) {
                incurredType = 'Venue_vod';
                incurredId = header.Incurred_Expense_Venue_vod__c;
            }
            
            if(attrs == null || attrs.size() == 0) {
                Expense_Attribution_vod__c attr = new Expense_Attribution_vod__c(
                    Expense_Line_vod__c = line.Id,
					Incurred_Expense_Type_vod__c = incurredType                   
                );
                
                setIncurred(attr, incurredType, incurredId);
            	attrsToUpsert.add(attr);    
            } else {
                for(Expense_Attribution_vod__c attr: line.Expense_Attributions_vod__r) {
                    if(attr.Incurred_Expense_vod__c != line.Expense_Header_vod__r.Incurred_Expense_vod__c) {
                        attr.Incurred_Expense_Type_vod__c = incurredType;
                        setIncurred(attr, incurredType, incurredId);
                    	attrsToUpsert.add(attr);  
                    }
                }
            }
           			
		}
        if(attrsToUpsert.size() > 0) {
        	upsert attrsToUpsert;    
        }        
	}
    
    private void setIncurred(Expense_Attribution_vod__c attr, String incurredType, Id incurredId) {
        if(incurredType == 'Account_vod') {
            attr.Incurred_Expense_Account_vod__c = incurredId;
        } else if (incurredType == 'Attendee_vod') {
            attr.Incurred_Expense_Attendee_vod__c = incurredId;
        } else if (incurredType == 'Event_Speaker_vod') {
            attr.Incurred_Expense_Speaker_vod__c = incurredId;
        } else if (incurredType == 'Event_Team_Member_vod') {
            attr.Incurred_Expense_Team_Member_vod__c = incurredId;
        } else if (incurredType == 'Vendor_vod') {
            attr.Incurred_Expense_Vendor_vod__c = incurredId;
        } else if (incurredType == 'Venue_vod') {
            attr.Incurred_Expense_Venue_vod__c = incurredId;
        }
    }
    global void finish(Database.BatchableContext BC) {
		// Access initialState here
	} 
}