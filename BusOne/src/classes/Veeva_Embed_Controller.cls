public with sharing class Veeva_Embed_Controller {

    public String veevaModuleName {get;set;}

    public String veevaPageName {get;set;}

    public String veevaObjectType {get;set;}

    public String veevaParams {get; set;}

    public String recordType18Digit {get; set;}

    public Veeva_Embed_Controller (ApexPages.StandardController controller) {
    }

    public Veeva_Embed_Controller () {
    }

    public static String getVodUrl () {
        // "Dev Mode": developers should be able to point any page to "localhost"
        // or any other CRM Server they choose.
        String devModeUrl = getQueryParam('url');
        if (devModeUrl != null) {
            String version = getQueryParam('version');

            // Default to "main" if the dev didn't specify a query parameter.
            if (version == null) {
                version = 'main';
            }

            return devModeUrl + '/' + version;
        }

        return VOD_Common.VOD_URL;
    }

    public static String getMiniString() {
        // By default, use minified files in production.
        boolean useMinFiles = true;

        // When the developer turns on "Dev Mode", turn off minified files by default.
        if (getQueryParam('url') != null) {
            useMinFiles = false;

            // If the developer turns on "Dev Mode", he should be able to minify the files again.
            if (getQueryParam('min') == '1') {
                useMinFiles = true;
            }
        }

        return useMinFiles ? '.min' : null;
    }

    /**
     * Tiny helper method to grab the current VF page's query params.
     */
    private static String getQueryParam(String key) {
        return ApexPages.currentPage().getParameters().get(key);
    }

    public String getSfSession() {
        return UserInfo.getSessionId();
    }

    public String getSfEndpoint() {
        return URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/24.0/' + UserInfo.getOrganizationId();
    }

    public static String getSfdcAuth() {
        Blob authHeader = Blob.valueOf(UserInfo.getUserName() + ':*');
        return 'Basic ' + EncodingUtil.base64Encode(authHeader);
    }

    public String getVeevaPageUrl() {
        String veevaPageUrl = getVodUrl() + '/app/' + veevaModuleName + '/' + veevaPageName;
            if (veevaParams != null) {
            veevaPageUrl += '?' + veevaParams;
        }
        return veevaPageUrl;
    }
}