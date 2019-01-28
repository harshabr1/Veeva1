public with sharing class Future_Territory_Alignment_vod {

    private String feedbackUrl;
    private boolean noFeedback;
    
    public Future_Territory_Alignment_vod() {
        Territory_Settings_vod__c territorySetting = Territory_Settings_vod__c.getInstance();
        noFeedback = territorySetting.Align_Server_vod__c == null || territorySetting.Align_Version_vod__c == null;
        if(!noFeedback) { 
            String baseUrl = 'https://{0}/{1}/sfdc/territoryFeedback.xhtml?crmUserId={2}&sfSession={3}&sfEndpoint={4}';
            String userId = getUserID();
            String sfSession = getSfSession();
            String sfEndpoint = getSfEndpoint();
            feedbackUrl = String.format(baseUrl,
            new List<String>{territorySetting.Align_Server_vod__c, territorySetting.Align_Version_vod__c, userId, sfSession, sfEndpoint});
        }
    }
    
    public String getFeedbackUrl() {
       return feedbackUrl;
    }
    
    private String getSfSession() {
       return UserInfo.getSessionId();
    }

    private String getUserID() {
        return UserInfo.getUserId();
    }

    private String getSfEndpoint() {
       return URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/24.0/' + UserInfo.getOrganizationId();
    }
    
    public boolean getNoFeedback() {
       return noFeedback;
    }
    
    public String getErrorMessage() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('FEEDBACK_UNAVAILABLE', 'ALIGN', 'This CRM instance is not set up for feedback');
    }
}