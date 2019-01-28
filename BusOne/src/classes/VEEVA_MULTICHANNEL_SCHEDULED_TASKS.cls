global class VEEVA_MULTICHANNEL_SCHEDULED_TASKS implements Schedulable {
    global void execute(SchedulableContext sc) {
        runScheduledTasks();
    }

    @future(callout=true)
    public static void runScheduledTasks() {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String url = settings.Multichannel_Server_vod__c + '/' + settings.Multichannel_Context_Root_vod__c;
    
        String orgId = [select Id from organization limit 1].Id;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        String fullUrl = url+'/api/v1/mcservice/maintenance/?orgId='+orgId; 

        req.setEndpoint(fullUrl);
        //It depends on 4 values: Header parameter "sfToken", Header parameter "sfOrg", username and password
        String password = String.valueOf(Math.random());
        String userName = String.valueOf(datetime.now().getTime());
        req.setHeader('sfToken',generateSignature(orgId, password, userName));
        req.setHeader('sfOrg',orgId);
        //set username/password
        Blob headerValue = Blob.valueOf(userName + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('');        
        HttpResponse res = h.send(req);

    }
    
    private static String generateSignature(String orgId, String password, String user ) {
        String salt = orgId+password+user;
        String secretKey = orgId.substring(1,orgId.length()-1);        
        String signature = generateHmacSHA256Signature(salt, secretKey);
        return signature;       
    }
 
    private static String generateHmacSHA256Signature(String saltValue, String secretKeyValue) {
        String algorithmName = 'HmacSHA256';
        Blob hmacData = Crypto.generateMac(algorithmName, Blob.valueOf(saltValue), Blob.valueOf(secretKeyValue));
        return EncodingUtil.base64Encode(hmacData);
    }
}