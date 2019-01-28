trigger VOD_EXPENSE_ATTRIBUTION_ROLLUP on Expense_Attribution_vod__c (after insert, after update, after delete) {
	Set<Id> speakerIdsToUpdate = new Set<Id>();
    Set<ID> accountIds = new Set<ID>();
    Set<ID> speakerIds = new Set<ID>();
    Set<ID> attendeeIds = new Set<ID>();
    Map<Id, Id> attendeeToAccountMap = new Map<Id, Id>();
    
    Map<Id, EM_Event_Speaker_vod__c> speakers = new Map<Id, EM_Event_Speaker_vod__c>();
    Map<Id, Account> accounts = new Map<Id, Account>();
    
    if(Trigger.isInsert || Trigger.isUpdate) {
    	for(Expense_Attribution_vod__c attr: Trigger.New) {
            accountIds.add(attr.Incurred_Expense_Account_vod__c);
            speakerIds.add(attr.Incurred_Expense_Speaker_vod__c);
            attendeeIds.add(attr.Incurred_Expense_Attendee_vod__c);
        }    
    }

    if (Trigger.isUpdate || Trigger.isDelete) {
    	for(Expense_Attribution_vod__c attr: Trigger.Old) {
            accountIds.add(attr.Incurred_Expense_Account_vod__c);
            speakerIds.add(attr.Incurred_Expense_Speaker_vod__c);
            attendeeIds.add(attr.Incurred_Expense_Attendee_vod__c);
        }
    }

    if(attendeeIds.size() > 0) {
        for(EM_Attendee_vod__c attendee: [SELECT Id, Account_vod__c FROM EM_Attendee_vod__c WHERE Id IN :attendeeIds]) {
            attendeeToAccountMap.put(attendee.Id, attendee.Account_vod__c);
            accountIds.add(attendee.Account_vod__c);
        }
    }

    if(accountIds.size() > 0) {
        for(Account account: [SELECT Id, Name, (SELECT Id, Year_To_date_Spend_vod__c FROM EM_Speaker_vod__r) FROM Account WHERE Id in :accountIds]) {
            accounts.put(account.Id, account);
        }
    }

    if(speakerIds.size() > 0) {
        for(EM_Event_Speaker_vod__c speaker: [SELECT Id, Speaker_Name_vod__c, Speaker_vod__c, Speaker_vod__r.Year_to_Date_Spend_vod__c FROM EM_Event_Speaker_vod__c WHERE Id in :speakerIds]) {
            speakers.put(speaker.Id, speaker);
        }
    }

    if(Trigger.isInsert) {
        for(Expense_Attribution_vod__c attr: Trigger.New) {
			if(attr.Incurred_Expense_Account_vod__c != null) {
                Account account = accounts.get(attr.Incurred_Expense_Account_vod__c);

                if(account != null && account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speakerIdstoUpdate.add(updateSpeaker.Id);
                }
            } else if(attr.Incurred_Expense_Speaker_vod__c != null) {
                EM_Event_Speaker_vod__c speaker = speakers.get(attr.Incurred_Expense_Speaker_vod__c);

                if(speaker != null) {
                    speakerIdsToUpdate.add(speaker.Speaker_vod__c);
                }
            } else if(attr.Incurred_Expense_Attendee_vod__c != null) {
            	Account account = accounts.get(attendeeToAccountMap.get(attr.Incurred_Expense_Attendee_vod__c));

                if(account != null && account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speakerIdstoUpdate.add(updateSpeaker.Id);
                }
            }
        }
    } else if(Trigger.isUpdate) {
    	for(Expense_Attribution_vod__c attr: Trigger.New) {
            Expense_Attribution_vod__c oldAttr;
            oldAttr = Trigger.oldMap.get(attr.Id);

            if(oldAttr != null && oldAttr.Incurred_Expense_Account_vod__c != attr.Incurred_Expense_Account_vod__c) {
                Account oldAccount = accounts.get(oldAttr.Incurred_Expense_Account_vod__c);
                Account account = accounts.get(attr.Incurred_Expense_Account_vod__c);

                if(account != null && account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speakerIdstoUpdate.add(updateSpeaker.Id);
                }

                if(oldAccount != null && oldAccount.EM_Speaker_vod__r != null && !oldAccount.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c oldUpdateSpeaker = oldAccount.EM_Speaker_vod__r;
                    speakerIdsToUpdate.add(oldUpdateSpeaker.Id);
                }
            }

            if(oldAttr != null && oldAttr.Incurred_Expense_Attendee_vod__C != attr.Incurred_Expense_Attendee_vod__c) {
                Account oldAccount = accounts.get(attendeeToAccountMap.get(oldAttr.Incurred_Expense_Attendee_vod__c));
            	Account account = accounts.get(attendeeToAccountMap.get(attr.Incurred_Expense_Attendee_vod__c));

                if(account != null && account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speakerIdstoUpdate.add(updateSpeaker.Id);
                }

                if(oldAccount != null && oldAccount.EM_Speaker_vod__r != null && !oldAccount.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c oldUpdateSpeaker = oldAccount.EM_Speaker_vod__r;
                    speakerIdsToUpdate.add(oldUpdateSpeaker.Id);
                }
            }

            if(oldAttr != null && oldAttr.Incurred_Expense_Speaker_vod__c != attr.Incurred_Expense_Speaker_vod__c) {
                EM_Event_Speaker_vod__c speaker = speakers.get(attr.Incurred_Expense_Speaker_vod__c);
                EM_Event_Speaker_vod__c oldSpeaker = speakers.get(oldAttr.Incurred_Expense_Speaker_vod__c);

                if(speaker != null) {
                    speakerIdsToUpdate.add(speaker.Speaker_vod__c);
                }
                if(oldSpeaker != null) {
                    speakerIdsToUpdate.add(oldSpeaker.Speaker_vod__c);
                }
            }
        }    
    } else if (Trigger.isDelete) {
        for(Expense_Attribution_vod__c attr: Trigger.Old) {
            if(attr.Incurred_Expense_Account_vod__c != null) {
                Account account = accounts.get(attr.Incurred_Expense_Account_vod__c);
                if(account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {
                	EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speakerIdstoUpdate.add(updateSpeaker.Id);      
                }
            } else if(attr.Incurred_Expense_Speaker_vod__c != null) {
                EM_Event_Speaker_vod__c speaker = speakers.get(attr.Incurred_Expense_Speaker_vod__c);
                if(speaker != null) {
                	speakerIdstoUpdate.add(speaker.Speaker_vod__c);
                }

            } else if(attr.Incurred_Expense_Attendee_vod__c != null) {
            	Account account = accounts.get(attendeeToAccountMap.get(attr.Incurred_Expense_Attendee_vod__c)); 
                if(account != null && account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {				    
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speakerIdstoUpdate.add(updateSpeaker.Id);   
                }    
            }                 
        }
    }
    
    if(!speakerIdsToUpdate.isEmpty()) {
        SpeakerYTDCalculator.calculate(speakerIdsToUpdate);
    } 
}