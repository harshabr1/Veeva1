public with sharing class VOD_MEDIA_FILES_CONTROLLER {
    private final Clm_Presentation_vod__c presentation;
    
    public VOD_MEDIA_FILES_CONTROLLER(ApexPages.StandardController controller) {
        List<String> fields = new List<String>();
        fields.add('Name');
        controller.addFields(fields);
        
        this.presentation = (Clm_Presentation_vod__c) controller.getRecord();
    }

    public VOD_MEDIA_FILES_CONTROLLER() {
    }

    public static String getTitle() {
        return 'Veeva CRM Online';
    }

    public static String getVodUrl() {
        return VOD_Common.VOD_URL;
    }
    
    public String getExtraParams() {
        return '&id=' + presentation.Id + '&name=' + getPresentationName();
    }
      
    public static String getPresentationLabel() {
        return Clm_Presentation_vod__c.sObjectType.getDescribe().getLabel();
    }
    
    public String getPresentationName() {
        return presentation.Name;
    }
    
    public String getPresentationUrl() {
        return URL.getSalesforceBaseUrl().toExternalForm() + '/' + presentation.id;
    }
    
    public String getBackToLabel() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('BackTo', 'Analytics', 'Back to') + ' ' + presentation.Name;
    }
}