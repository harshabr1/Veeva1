trigger Account_Plan_vod on Account_Plan_vod__c bulk (before delete) {
            List <Call2_vod__c > headers =
                           new List <Call2_vod__c > ();
                           
                            headers = [Select Id, Account_Plan_vod__c  from Call2_vod__c where Account_Plan_vod__c in :Trigger.old];
        
            for (Integer i = 0; i < headers.size();i++) {
                
                Trigger.oldMap.get(headers[i].Account_Plan_vod__c).addError (VOD_GET_ERROR_MSG.getErrorMsg('DEL_PROD_STRAT','TriggerError'), false);
                
                
            }
        
        
        }