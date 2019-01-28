global class VEEVA_RUN_CONCUR_SYNC_PROCESS implements Schedulable {
    global void execute(SchedulableContext sc) {
        runActivitySync();
    }

    @future(callout=true)
    public static void runActivitySync() {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String url = settings.Veeva_Server_vod__c + '/' + settings.Veeva_Version_vod__c;
                
        String orgId = [select Id from organization limit 1].Id;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(url+'?oType=concursync&orgId='+orgId);
        HttpResponse res = h.send(req);
    }
}