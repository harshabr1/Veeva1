global class VEEVA_RUN_ANALYTICS_FILES_CLEAN_UP implements Schedulable {
    global void execute(SchedulableContext sc) {
        runAnalyticsFileCleanUp();
    }
    
    public static void runAnalyticsFileCleanUp() {
    
        Boolean deleted = false;  
        date d = system.today().addDays(-30);
        System.debug(d); 
        String sessionID = UserInfo.getSessionId(); 
        System.debug('Session Id: '+ sessionID);
        String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/Soap/u/24.0/' + UserInfo.getOrganizationId();
        System.debug('Server URL: '+ sfdcBaseURL);
        List<Analytics_Files_vod__c> af = [SELECT Data_Map_Template_Id_vod__c,File_Name_vod__c,Id,Market_vod__c,Status_vod__c,Type_vod__c FROM Analytics_Files_vod__c WHERE Status_vod__c='Archived_vod' AND Date_Processed_vod__c < :d];
        System.debug('SELECT Data_Map_Template_Id_vod__c,File_Name_vod__c,Id,Market_vod__c,Status_vod__c,Type_vod__c FROM Analytics_Files_vod__c WHERE Status_vod__c=\'Archived_vod\' AND Date_Processed_vod__c < ' + d); 
        if(af.size()>0){
            String tableNames='';
            for(Analytics_Files_vod__c a:af) {
               String tableName='';
               String market ='';
               if(a.Market_vod__c != null){
                 market = a.Market_vod__c;
                 System.debug('market is: ' + market); 
               }
               tableName = a.Id + ':' + 'ST_' + a.Data_Map_Template_Id_vod__c + '_' + market + '_archived';
               tableNames += (tableNames==''?'':';')+tableName; 
            }

            Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
            String url = settings.Veeva_Server_vod__c + '/' + settings.Veeva_Version_vod__c;
            System.debug(LoggingLevel.INFO,url); 
            String orgId = [select Id from organization limit 1].Id;
             
            
            //Prepare http req
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url+'/analytic/service/analyticloader/tables');
            req.setHeader('sfSession', sessionID);
            req.setHeader('sfEndpoint', sfdcBaseURL);
            req.setMethod('POST');  
            req.setTimeout(2000); 
            //req.setCompressed(true); 
            Map<String,object> mapEmp = new Map<String,object>();
            mapEmp.put('orgId', orgId);
            mapEmp.put('tbs', tableNames);
            String JSONString = JSON.serialize(mapEmp); 
            req.setBody(JSONString);
            System.debug(LoggingLevel.INFO,JSONString);
            System.debug(LoggingLevel.INFO,req.getHeader('sfSession'));
            System.debug(LoggingLevel.INFO,req.getHeader('sfEndpoint'));
            
            Http http = new Http();
            HttpResponse res = new HttpResponse();
            try{
                res = http.send(req);
                System.debug(LoggingLevel.INFO,res.toString());
                System.debug(LoggingLevel.INFO,'STATUS:'+res.getStatus());
                System.debug(LoggingLevel.INFO,'STATUS_CODE:'+res.getStatusCode());
                System.debug(LoggingLevel.INFO,res.getBody());
                if(res.getStatusCode() == 200) {
                    delete af;
                    deleted=true;
                }
             } catch(System.CalloutException e) {
                //Exception handling goes here....
                System.debug(LoggingLevel.ERROR,'Callout error: '+ e);
                System.debug(LoggingLevel.ERROR,res.toString());
                deleted =false; 
             }
         
            
       }
    }
}