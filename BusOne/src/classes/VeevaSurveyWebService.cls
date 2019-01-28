// THIS CLASS MUST BE DEPLOYED WITH API 27 OR HIGHER.

global class VeevaSurveyWebService {
    webService static String schedulePublish(String surveyId, List<String> surveyTerritoryIds, Boolean onlyNewTargets, Integer scope) {
        String customSettingValue = Veeva_Settings_vod__c.getInstance().Survey_Publish_Apex_vod__c;

        // Default String to return is a generic success message.
        String resultMsg = 'Success';

        BATCH_SURVEY_PUBLISH_ABSTRACT batch = null;
        if(customSettingValue == null) {
            // If the custom setting is not set, use the Veeva default publish strategy.
            batch = new VEEVA_BATCH_SURVEY_PUBLISH();
        } else {
            // System.Type is analogous to Java's Class<?> class.
            Type batchType = System.Type.forName(customSettingValue);

            if(batchType != null) {
                try {
                    // 1) The Apex class must have a no parameter constructor for .newInstance to work.
                    // 2) The class must implement BATCH_SURVEY_PUBLISH_ABSTRACT
                    // 3) Note that it is also recommended that the class implement Database.Stateful, but not required.
                    batch = (BATCH_SURVEY_PUBLISH_ABSTRACT) batchType.newInstance();
                } catch(System.TypeException e) {
                    resultMsg = customSettingValue + ' does not implement BATCH_SURVEY_PUBLISH_INTERFACE';
                } catch(Exception e) {
                    // Specifically, this is for a thrown common.apex.runtime.impl.ExecutionException
                    resultMsg = customSettingValue + ' does not have a no-args constructor';
                }
            } else {
                // batchType is null if no Apex class with the given name is found.
                resultMsg = 'Could not find Apex class with name ' + customSettingValue;
            }
        }

        if(batch != null) {
            Integer BATCH_LIMIT = 5;
            Integer runningBatchJobs = [
              select count()
              from AsyncApexJob
              where JobType = 'BatchApex'
              and status in ('Queued','Processing','Preparing')
            ];
            
            if(runningBatchJobs >= BATCH_LIMIT) {
                resultMsg = 'Unable to publish: batch limit exceeded (limit is '+BATCH_LIMIT+'). Please try again once other batch processes have finished.';
            } else {                
                Survey_vod__c surveyToUpdate = Database.query('SELECT Id FROM Survey_vod__c WHERE Id = :surveyId');
                surveyToUpdate.Status_vod__c = 'Publishing_vod';
                update surveyToUpdate;

                // Modify Survey_Question_vod__c.LastModifiedDate to ensure that Survey Question records will be sync'ed to mobile platforms.
                List<Survey_Question_vod__c> questionsToUpdate = Database.query('SELECT Id FROM Survey_Question_vod__c WHERE Survey_vod__c = :surveyId');
                update questionsToUpdate;

                batch.veevaSetterMethod(surveyId, surveyTerritoryIds, onlyNewTargets);
    
                batch.init();
                Database.executeBatch(batch, scope);
            }
            
        }

        System.debug(resultMsg);
        return resultMsg;
    }
}