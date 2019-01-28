trigger Product_Trigger_vod on Product_vod__c bulk (before delete) {
            
            VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
            Map <Id, Product_vod__c> prods = new Map <Id,Product_vod__c> (
                [Select Id, 
                        (Select Id, Name From Call_Detail_vod__r LIMIT 1), 
                        (Select Id From Call_Discussion_vod__r LIMIT 1), 
                        (Select Id From Call_Key_Messages_vod__r LIMIT 1), 
                        (Select Id From Call_Sample_vod__r LIMIT 1)
                        from Product_vod__c Where Id in :Trigger.old]
                );
                
        
            for (Integer i = 0; i < Trigger.old.size(); i++) {
                
                Product_vod__c prod = prods.get (Trigger.old[i].Id);
                Boolean details = false;
                Boolean discussions = false;
                Boolean callMessages = false;
                Boolean samples = false;
        
                if (prod != null) {
                    for (Call2_Detail_vod__c dets : prod.Call_Detail_vod__r) {
                        details = true;
                        break;
                    }
                    
                    for (Call2_Discussion_vod__c disc : prod.Call_Discussion_vod__r) {
                        discussions = true;
                        break;
                    }
                    
                    for (Call2_Key_Message_vod__c keys : prod.Call_Key_Messages_vod__r) {
                        callMessages = true;
                        break;
                    }
                    for (Call2_Sample_vod__c samps : prod.Call_Sample_vod__r) {
                        samples = true;
                        break;
                    }
                    
                    
                    if (details == true || discussions == true || callMessages == true || samples == true) {
                        Trigger.old[i].addError(bundle.getErrorMsg('DEL_PRODUCT'), false);
                    }
                    
                }       
                
            }
        }