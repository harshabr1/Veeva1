trigger VEEVA_BEFORE_SURVEY_TARGET_UPSERT on Survey_Target_vod__c (before insert, before update) {
    Set<Id> surveyIds = VEEVA_SURVEY_UTILS.getSurveyIds(Trigger.new);
    List<Survey_vod__c> surveyList = [SELECT Id, Segment_vod__c FROM Survey_vod__c WHERE Id IN :surveyIds];
    Map<Id, Survey_vod__c> surveyMap = VEEVA_SURVEY_UTILS.createIdToSurveyMap(surveyList);
    Map<Id, List<VEEVA_SURVEY_UTILS.Segment>> surveyIdToSegmentsMap = VEEVA_SURVEY_UTILS.createSurveyIdToSegmentsMap(surveyMap);
    Schema.DescribeFieldResult subDatetimeFld = Schema.SObjectType.Survey_Target_vod__c.fields.Submitted_DateTime_vod__c;

    Map<Survey_Target_vod__c, Id> targetToAccountIdMap = new Map<Survey_Target_vod__c, Id>();
    for(Survey_Target_vod__c target : Trigger.new) {
    	// if an Entity_Reference_Id_vod exists, stamp the Account field with it
    	if(target.Entity_Reference_Id_vod__c != null && target.Entity_Reference_Id_vod__c != '') {
    		target.Account_vod__c = target.Entity_Reference_Id_vod__c;
    		// clear Entity Refernce after being used
    		target.Entity_Reference_Id_vod__c = null;
    	}
    	
        // Create a map of Survey Target to Account Id for filling out Account_Display_Name_vod__c
        if(target.Account_vod__c != null) {
            targetToAccountIdMap.put(target, target.Account_vod__c);
        }

        target.Segment_vod__c = null;        
        Survey_Target_vod__c oldTarget = null;
        if(trigger.oldMap != null) {
            oldTarget = trigger.oldMap.get(target.Id);
        }

        if(isSubmittedStatus(target.Status_vod__c)) {
            // Assign Segment
            List<VEEVA_SURVEY_UTILS.Segment> segments = surveyIdToSegmentsMap.get(target.Survey_vod__c);
            if(segments != null && !segments.isEmpty() && target.Score_vod__c != null) {
                for(VEEVA_SURVEY_UTILS.Segment segment : segments) {
                    if(segment.containsScore(target.Score_vod__c)) {
                        target.Segment_vod__c = segment.getName();
                        break;
                    }
                }
            }
        
            if(oldTarget == null || !isSubmittedStatus(oldTarget.Status_vod__c)) {
                // Logic for deciding between Submitted_vod and Late_Submission_vod statuses
                if(target.End_Date_vod__c < Date.TODAY()) {
                    target.Status_vod__c = 'Late_Submission_vod';
                } else {
                    target.Status_vod__c = 'Submitted_vod';
                }
                
                //Logic for setting Submitted_DateTime_vod field
                if (subDatetimeFld != null && subDatetimeFld.isUpdateable() && target.Submitted_DateTime_vod__c == null) {
                    DateTime submittedNow = DateTime.now();
                    target.Submitted_DateTime_vod__c = submittedNow;
                }
            }
        } else if (oldTarget != null && isSubmittedStatus(oldTarget.Status_vod__c)) {
            //survey target change from submitted to not submitted, so clear submitted datetime
            target.Submitted_DateTime_vod__c = null;
        }
        
        //Logic for setting report status to recalled (removed)
        //if (target.Recalled_Datetime_vod__c != null && (target.Completed_Datetime_vod__c == null || target.Recalled_Datetime_vod__c < target.Completed_Datetime_vod__c)) {
          //  target.Report_Status_vod__c = 'Recalled_vod';
        //}
    }

    Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Formatted_Name_vod__c FROM Account WHERE Id IN :targetToAccountIdMap.values()]);
    for(Survey_Target_vod__c target : targetToAccountIdMap.keySet()) {
        target.Account_Display_Name_vod__c = accounts.get(target.Account_vod__c).Formatted_Name_vod__c;
    }
    
    private boolean isSubmittedStatus(String status) {
        return 'Submitted_vod'.equals(status) || 'Late_Submission_vod'.equals(status);
    }
}