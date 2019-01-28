// THIS CLASS MUST BE DEPLOYED WITH API 27 OR HIGHER
global abstract class BATCH_SURVEY_PUBLISH_ABSTRACT implements Database.Batchable<sObject> {

    // All classes extending this class must have a no-args constructor.
    // Reflection will be used to select an implementation of BATCH_SURVEY_PUBLISH_ABSTRACT
    // based on the String Custom Setting, SURVEY_PUBLISH_APEX.

    /**
     * This method is guaranteed to be called after the veevaSetter methods. This method, in
     * combination with the veevaSetterMethod below, is intended to serve as a replacement
     * for parameterized constructors.
     */
    global abstract void init();

    /**
     * This method are not available for customization. It is guaranteed to be called after
     * the no-args constructor and before the init() method.
     * No business logic will be called in this method: its only purpose is to initialize
     * protected member variables, which implementations of BATCH_SURVEY_PUBLISH_ABSTRACT
     * may find useful.
     */
    public void veevaSetterMethod(String surveyId, List<String> surveyTerritoryIds, boolean newTargetsOnly) {
        this.surveyId = surveyId;
        this.surveyTerritoryIds.addAll(surveyTerritoryIds);
        this.newTargetsOnly = newTargetsOnly;
    }

    // The protected members of this class are free to use in any subclass of
    // BATCH_SURVEY_PUBLISH_ABSTRACT. They are guaranteed to be set and available for use the
    // init() call and afterwards.

    // The ID of the Survey being published
    protected ID surveyId;

    // A Set of all territory IDs that are included under the territory node specified by the
    // Survey's Territory_vod field, including that territory itself.
    protected Set<String> surveyTerritoryIds = new Set<String>();

    // If user doesn't have unlock permission on survey, the publishing batch will only run for new targets with "Developement_vod"
    protected Boolean newTargetsOnly;
}