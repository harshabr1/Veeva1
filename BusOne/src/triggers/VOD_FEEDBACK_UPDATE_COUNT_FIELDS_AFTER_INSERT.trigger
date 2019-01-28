trigger VOD_FEEDBACK_UPDATE_COUNT_FIELDS_AFTER_INSERT on Suggestion_Feedback_vod__c (after insert) 
{    
    List<String> suggestionIds = new List<String>();
    for(Suggestion_Feedback_vod__c rec: Trigger.new) 
    {
        suggestionIds.add(rec.Suggestion_vod__c);
    }
    
    List<RecordType> feedbackRTs = [SELECT Id, DeveloperName from RecordType where SobjectType = 'Suggestion_Feedback_vod__c'];
    Map<Id, String> IdToDeveloperName = new Map<Id, String>();
    for(RecordType rt: feedbackRTs) 
    {
        IdToDeveloperName.put(rt.Id, rt.DeveloperName);
    }
    
    for (Suggestion_vod__c suggestion: [Select Id, Dismiss_Count_vod__c, Action_Count_vod__c, Mark_Complete_Count_vod__c FROM Suggestion_vod__c where Id in :suggestionIds]) 
    {
        suggestion.Action_Count_vod__c = 0;
        suggestion.Mark_Complete_Count_vod__c = 0;
        suggestion.Dismiss_Count_vod__c = 0;
        for (Suggestion_Feedback_vod__c feedback: [Select Id, RecordTypeId, Suggestion_vod__c FROM Suggestion_Feedback_vod__c where Suggestion_vod__c =:suggestion.Id]) 
        {
            if (IdToDeveloperName.containsKey(feedback.RecordTypeId)) 
            {
                string devName = IdToDeveloperName.get(feedback.RecordTypeId);
                if (devName == 'Dismiss_vod') 
                {
                    suggestion.Dismiss_Count_vod__c = suggestion.Dismiss_Count_vod__c + 1;
                    suggestion.Dismissed_vod__c = 1;
                } 
                else if (devName == 'Activity_Execution_vod') 
                {
                    suggestion.Action_Count_vod__c = suggestion.Action_Count_vod__c + 1;
                    suggestion.Actioned_vod__c = 1;
                } 
                else if (devName == 'Mark_As_Complete_vod') 
                {
                    suggestion.Mark_Complete_Count_vod__c = suggestion.Mark_Complete_Count_vod__c + 1;
                    suggestion.Marked_As_Complete_vod__c = 1;
                }
            }
        }
        update suggestion;
    }
}