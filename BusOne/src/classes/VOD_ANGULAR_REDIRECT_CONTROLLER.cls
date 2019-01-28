public with sharing class VOD_ANGULAR_REDIRECT_CONTROLLER {
    
    public String veevaModuleName {get;set;}
    
    // This is a string because apparently apex:attribute "assignTo" doesn't work for maps...
    public String extraParams {get;set;} 
    
    public VOD_ANGULAR_REDIRECT_CONTROLLER(ApexPages.StandardController controller) {
    }

    public VOD_ANGULAR_REDIRECT_CONTROLLER() {
    }
    
    public static String getVodUrl () {
        return VOD_Common.VOD_URL;
    }
    
    public String getSfSession() {
        return UserInfo.getSessionId();
    }
    
    public String getSfEndpoint() {
        return URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/24.0/' + UserInfo.getOrganizationId();
    }
    
    public static String getSfdcUsername() {
        return UserInfo.getUserName();
    }
    
    public String getVeevaMessagesUrl() {
        String veevaMessagesUrl = getVodUrl() + '/app/' + veevaModuleName + '/messages'
                + '?sfSession=' + getSfSession()
                + '&sfEndpoint=' + EncodingUtil.urlEncode(getSfEndpoint(), 'UTF-8')
                + extraParams;
            
        return veevaMessagesUrl;
    }
    
    public String getVeevaPageUrl() {
        String veevaPageUrl = getVodUrl() + '/app/' + veevaModuleName + '/index'
                + '?sfSession=' + getSfSession()
                + '&sfEndpoint=' + EncodingUtil.urlEncode(getSfEndpoint(), 'UTF-8')
                + extraParams;
            
        return veevaPageUrl;
    }
    
    public String getParsedParams() {
        Map<String, String> parsedParams = new Map<String, String>();
        
        for (String param : extraParams.split('&', -1)) {
            String[] splitParam = param.split('=', -1);
            
            if (splitParam.size() == 2) {
                parsedParams.put(splitParam[0], splitParam[1]);                
            }
        }
        
        return JSON.serialize(parsedParams);
    }
}