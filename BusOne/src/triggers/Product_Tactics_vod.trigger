trigger  Product_Tactics_vod on Product_Tactic_vod__c bulk (before delete) {
        	
        	
        		
        	List <Call2_Discussion_vod__c > dets =
        				   new List <Call2_Discussion_vod__c > ();
        				   
        				    dets = [Select Id, Product_Tactic_vod__c  from Call2_Discussion_vod__c where Product_Tactic_vod__c  in :Trigger.old];
        
        	for (Integer i = 0; i < dets.size();i++) {
        		
        		Trigger.oldMap.get(dets[i].Product_Tactic_vod__c).addError (VOD_GET_ERROR_MSG.getErrorMsg('DEL_PROD_STRAT','TriggerError'), false);
        		
        		
        	}
        
        
        }