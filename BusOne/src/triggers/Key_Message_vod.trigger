trigger Key_Message_vod  on Key_Message_vod__c bulk (before delete) {
        	
        			
        	String ErrorMsg = VOD_GET_ERROR_MSG.getErrorMsg('DEL_KEY_MSG','TriggerError');
        		
        	List <Call2_Key_Message_vod__c > msgs =
        				   new List <Call2_Key_Message_vod__c > ();
        				   
        				    msgs = [Select Id,Key_Message_vod__c  from Call2_Key_Message_vod__c where  Key_Message_vod__c in :Trigger.old];
        
        	for (Integer i = 0; i < msgs.size();i++) {
        		
        		Trigger.oldMap.get(msgs[i].Key_Message_vod__c).addError (ErrorMsg, false);
        		
        		
        	}
        
        
        }