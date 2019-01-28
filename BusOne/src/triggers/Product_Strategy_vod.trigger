trigger Product_Strategy_vod  on Product_Strategy_vod__c bulk (before delete) {

            List <Call2_Discussion_vod__c > dets = new List <Call2_Discussion_vod__c > ();

            dets = [Select Id, Product_Strategy_vod__c  from Call2_Discussion_vod__c where Product_Strategy_vod__c in :Trigger.old];

            // fetch the error outside the for loop
            String errorMsg = VOD_GET_ERROR_MSG.getErrorMsg('DEL_PROD_STRAT','TriggerError');
            System.debug ('Fetched Error message ' + errorMsg );
        
            for (Integer i = 0; i < dets.size();i++) {
                Trigger.oldMap.get(dets[i].Product_Strategy_vod__c).addError(errorMsg, false);
            }
 }