public class VEEVA_SURVEY_UTILS {
    private VEEVA_SURVEY_UTILS() {}

    public static Set<Id> getSurveyIds(List<Survey_Target_vod__c> targets) {
        Set<Id> surveyIds = new Set<Id>();
        for(Survey_Target_vod__c target: targets) {
            surveyIds.add(target.Survey_vod__c);
        }
        return surveyIds;
    }

    public static Map<Id, Survey_vod__c> createIdToSurveyMap(List<Survey_vod__c> surveys) {
        Map<Id, Survey_vod__c> surveyMap = new Map<Id, Survey_vod__c>();
        for(Survey_vod__c survey : surveys) {
            surveyMap.put(survey.Id, survey);
        }
        return surveyMap;
    }

    public static Map<Id, List<VEEVA_SURVEY_UTILS.Segment>> createSurveyIdToSegmentsMap(Map<Id, Survey_vod__c> surveyMap) {
        Map<Id, List<VEEVA_SURVEY_UTILS.Segment>> surveyIdToSegments = new Map<Id, List<VEEVA_SURVEY_UTILS.Segment>>();
        for(Id surveyId : surveyMap.keySet()) {
            surveyIdToSegments.put(surveyId, getSegments(surveyMap.get(surveyId).Segment_vod__c));
        }
        return surveyIdToSegments;
    }

    public static List<Segment> getSegments(String segmentsString) {
        List<Segment> segmentList = new List<Segment>();
        if(segmentsString != null) {
            String[] split = segmentsString.split(';', 0);
            for(Integer i = 0; i + 2 < split.size(); i += 3) {
                segmentList.add(new Segment(split[i], split[i + 1], split[i + 2]));
            }
        }
        return segmentList;
    }

    public class Segment {
        public Segment(String name, String minScoreString, String maxScoreString) {
            this(name, Long.valueOf(minScoreString), Long.valueOf(maxScoreString));
        }
        public Segment(String name, Long minScore, Long maxScore) {
            this.name = name;
            this.minScore = minScore;
            this.maxScore = maxScore;
        }

        public String getName() {
            return name;
        }
        public Long getMinScore() {
            return minScore;
        }
        public Long getMaxScore() {
            return maxScore;
        }

        public boolean containsScore(Decimal score) {
            return minScore <= score && score <= maxScore;
        }

        private final String name;
        private final Long minScore;
        private final Long maxScore;
    }
}