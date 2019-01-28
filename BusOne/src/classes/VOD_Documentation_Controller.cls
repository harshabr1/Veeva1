public with sharing class VOD_Documentation_Controller {
    /**
     * Determines the appropriate URL for documentation redirect.
     * Bases decision on org's base Veeva server URL. If the org is
     * Directed at the production servers, then documentation is retrieved from there as well.
     */
    public String getDocUrl() {
        String baseUrl = VOD_Common.VOD_SERVER_URL;

        Boolean isValidDomain = false;
        List<String> validDomains = new List<String> {'.veevacrmdev.com', '.veevacrmstage.com', '.veevacrm.com'};
        for(Integer i = 0; i < validDomains.size(); i++) {
            if(baseUrl.indexOf(validDomains.get(i)) >= 0) {
                isValidDomain = true;
                break;
            }
        }

        if (Pattern.matches('https://(vs|na)\\d+[.]vod309[.]com', baseUrl) || isValidDomain) {
            baseUrl = 'https://crmhelp.veeva.com';
        } else if ('https://qa.vod309.com'.equals(baseUrl) || baseUrl.indexOf('.veevacrmqa.com') >= 0) {
            baseUrl = 'https://crmhelp-qa.veeva.com';
        }
        return baseUrl + '/doc/';           
    }
}