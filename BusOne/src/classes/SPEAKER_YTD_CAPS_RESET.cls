global with sharing class SPEAKER_YTD_CAPS_RESET implements Database.Batchable<sObject>, Schedulable {
    String query;
    Date defaultResetDate;
    
    global SPEAKER_YTD_CAPS_RESET() {

    }
    
	global Database.QueryLocator start(Database.BatchableContext BC) {
        Schema.DescribeFieldResult dayDescribe = EM_Speaker_vod__c.Year_To_Date_Reset_Day_vod__c.getDescribe();
        Schema.DescribeFieldResult monthDescribe = EM_Speaker_vod__c.Year_To_Date_Reset_Month_vod__c.getDescribe();

        defaultResetDate = Date.newInstance(System.Today().year(), Integer.valueOf(monthDescribe.getDefaultValue()), Integer.valueOf(dayDescribe.getDefaultValue()));

		// This is the base query that dirves the chunking.
		// We are grabbing all EM speakers
		query = 'SELECT Id,' +
		        '       Year_To_Date_Reset_Month_vod__c,' +
		        '       Year_To_Date_Reset_Day_vod__c,' +
                '		Next_Year_Reset_Date_vod__c' +
		        ' FROM EM_Speaker_vod__c';

		return Database.getQueryLocator(query);
	}

    global void execute(SchedulableContext sc) {
        Database.Batchable<SObject> b = new SPEAKER_YTD_CAPS_RESET();
        Database.executeBatch(b, 50);
    }

    global void execute(Database.BatchableContext BC, List<sObject> batch) {
		// Loop through all the rows in the batch of Cycle Plan Details
		Set<Id> speakerIdsToRecalculate = new Set<Id> ();
        List<EM_Speaker_vod__c> speakerstoUpdate = new List<EM_Speaker_vod__c>();
		for (sObject obj : batch) {
			EM_Speaker_vod__c speaker = (EM_Speaker_vod__c)obj;

            if(speaker.Next_Year_Reset_Date_vod__c == null) {
                speakerstoUpdate.add(speaker);
                speakerIdstoRecalculate.add(speaker.Id);
            }

            if(speaker.Year_To_Date_Reset_Month_vod__c != null && speaker.Year_To_Date_Reset_Day_vod__c != null) {
            	Date speakerResetDate = Date.newInstance(System.Today().year(), Integer.valueOf(speaker.Year_To_Date_Reset_Month_vod__c), Integer.valueOf(speaker.Year_To_Date_Reset_Day_vod__c));
                if(speakerResetDate == System.Today()) {
                    speakersToUpdate.add(speaker);
                    speakerIdsToRecalculate.add(speaker.Id);
                }
            } else if(System.Today() == defaultResetDate) {
                speakersToUpdate.add(speaker);
				speakerIdsToRecalculate.add(speaker.Id);
            }
		}

        if(speakersToUpdate.size() > 0) {
            update speakersToUpdate;
        }
        if (speakerIdsToRecalculate.size () > 0) {
			SpeakerYTDCalculator.calculate(speakerIdsToRecalculate);            
        }
	}
    global void finish(Database.BatchableContext BC) {
		// Access initialState here
	}   
}