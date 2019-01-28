trigger VEEVA_BEFORE_SURVEY_QUESTION_UPSERT on Survey_Question_vod__c (before update, before insert) {
    Map<Id,Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Survey_Question_vod__c.getRecordTypeInfosById();
    List<Id> tempList = new List<Id>();
    for(RecordType type : [Select Id, DeveloperName FROM RecordType WHERE SObjectType = 'Survey_Question_vod__c' AND DeveloperName IN ('Description_vod', 'Multiselect_vod', 'Picklist_vod', 'Radio_vod') ORDER BY DeveloperName]) {
        tempList.add(type.Id);
    }   
    Id descriptionTypeId = tempList.get(0);
    Id multiselectTypeId = tempList.get(1);
    Set<Id> picklistTypeIds = new Set<Id>(tempList);

    for(Survey_Question_vod__c surveyQuestion : Trigger.new) {
        if(!picklistTypeIds.contains(surveyQuestion.recordTypeId)) {
            continue;
        }
        if (descriptionTypeId == surveyQuestion.recordTypeId) {
            surveyQuestion.required_vod__c = false;
            continue;
        }
        surveyQuestion.Min_Score_vod__c = 0;
        surveyQuestion.Max_Score_vod__c = 0;

        if(surveyQuestion.Answer_Choice_vod__c == null) {
            continue;
        }

        String[] split = surveyQuestion.Answer_Choice_vod__c.split(';', 0);
        List<Long> weights = new List<Long>();
        for(Integer i = 0; i + 1 < split.size(); i += 2) {
            weights.add(Long.valueOf(split[i+1].trim()));
        }

        List<Long> scores = new List<Long>();
        if(!surveyQuestion.Required_vod__c) {
            scores.add(0);
        }

        if(multiselectTypeId == surveyQuestion.RecordTypeId) {
            Long positiveSum = 0;
            Long negativeSum = 0;

            for(Long weight : weights) {
                if(weight > 0) {
                    positiveSum += weight;
                } else {
                    negativeSum += weight;
                }
            }

            if(positiveSum > 0) {
                scores.add(positiveSum);
            }
            if(negativeSum < 0) {
                scores.add(negativeSum);
            }
        }

        scores.addAll(weights);

        scores.sort();
        surveyQuestion.Min_Score_vod__c = scores.get(0);
        surveyQuestion.Max_Score_vod__c = scores.get(scores.size() - 1);
    }
}