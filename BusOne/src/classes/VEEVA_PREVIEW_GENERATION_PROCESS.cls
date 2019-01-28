global class VEEVA_PREVIEW_GENERATION_PROCESS {
	@future(callout=true)
    public static void generatePreview(String auth, String sfSession, String sfEndpoint, String commaSepCatalogIds) {
        
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String baseUrl = settings.Veeva_Server_vod__c + '/' + settings.Veeva_Version_vod__c + '/api/v1/';
        String queryParamBaseUrl = baseUrl;
		baseUrl += 'em.print/async/generate/previewFromTrigger?baseUrl=' + queryParamBaseUrl + '&catalogIds=' + commaSepCatalogIds;
        
        //System.debug('Auth: ' + auth);
        //System.debug('sfSession: ' + sfSession);
        //System.debug('sfEndpoint: ' + sfEndpoint);
        //System.debug('BaseURL: ' + baseUrl);
        //System.debug('commaSepCatalogIds: ' + commaSepCatalogIds);
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl);
        req.setMethod('GET');
		req.setHeader('Authorization', auth);
        req.setHeader('sfSession', sfSession);
        req.setHeader('sfEndpoint', sfEndpoint);
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        
        HttpResponse res = http.send(req);
        System.debug('Response: ' + res.toString());
        
    }
}