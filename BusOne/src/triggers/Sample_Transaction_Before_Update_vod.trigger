trigger Sample_Transaction_Before_Update_vod on Sample_Transaction_vod__c (before update) {
    
    Boolean updateGroup = VOD_SAMPLE_TRANSACTION.getUpdateGroup();
    // used for checking conflict updates among Trigger.new
    Map<String, Sample_Transaction_vod__c> updates = new Map<String, Sample_Transaction_vod__c>();
    // Ids in Trigger.new
    Set<ID> Ids = new Set<ID>();
       
    for (Integer i = 0; i < Trigger.new.size(); i++) { 
        Sample_Transaction_vod__c newTran = Trigger.new[i];
        Sample_Transaction_vod__c oldTran = Trigger.old[i];
         
        if (newTran.Unlock_vod__c == true) { 
            newTran.Unlock_vod__c = false;
            newTran.Status_vod__c = 'Saved_vod';
        } else if (oldTran.Status_vod__c == 'Submitted_vod' && VOD_SAMPLE_RECEIPTS.getReceipt() == false) { 
            newTran.Status_vod__c.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_SAMP_TRAN','TriggerError'), false);
        } 
        
        if (newTran.Status_vod__c == 'Submitted_vod')
            newTran.Submitted_Date_vod__c = System.today();  
        
        if (updateGroup) {
            if (newTran.Group_Transaction_Id_vod__c != null) {  
                // collect information for updating transactions in the same group  
                Ids.add(newTran.Id);            
                if (updates.containsKey(newTran.Group_Transaction_Id_vod__c) == false) 
                    updates.put(newTran.Group_Transaction_Id_vod__c, newTran);
                else if (newTran.Status_vod__c != updates.get(newTran.Group_Transaction_Id_vod__c).Status_vod__c) {
                        updates.remove(newTran.Group_Transaction_Id_vod__c);
                        updates.put(newTran.Group_Transaction_Id_vod__c, newTran);
                }  
            }
        }                           
    }       

    // unlock or submit other transactions in the same group
    if (updates.size() > 0) {
        Set<String> GroupIds = updates.keySet();
        List<Sample_Transaction_vod__c> additionalUpdates = new List<Sample_Transaction_vod__c>();
        List<Sample_Transaction_vod__c> sameGroupTrans = 
                    [select Group_Transaction_Id_vod__c, Unlock_vod__c, Status_vod__c
                                from Sample_Transaction_vod__c
                                where Group_Transaction_Id_vod__c in :GroupIds
                                    and Id not in :Ids]; 
        for (Sample_Transaction_vod__c tran : sameGroupTrans) {
            Sample_Transaction_vod__c updTran = updates.get(tran.Group_Transaction_Id_vod__c);
            if (tran.Status_vod__c != updTran.Status_vod__c) { 
                if (updTran.Status_vod__c == 'Saved_vod')                      
                    tran.Unlock_vod__c = true;
                else 
                    tran.Status_vod__c = updTran.Status_vod__c;
                additionalUpdates.add(tran);
            }
        } 
        if (additionalUpdates.size() > 0) { 
            VOD_SAMPLE_TRANSACTION.setUpdateGroup(false); // prevent recursive updates    
          try {    
            update additionalUpdates;
            } catch (System.DmlException e) {
           		Integer numErrors = e.getNumDml();
            	String error = '';
             	System.debug('Error has occured: ' + numErrors);
	            System.debug('Error has occured: ' + e);
    	        for (Integer i = 0; i < numErrors; i++) {
        	        Id thisId = e.getDmlId(i);
            	    System.debug ('Error info : ' + e.getDmlMessage(i));
                	error += e.getDmlMessage(i) + '\n';
        	        break;
            	}
            	
            	for (Sample_Transaction_vod__c ste :Trigger.new) {
            		ste.Id.addError(error, false);
            	}
          }
            
            VOD_SAMPLE_TRANSACTION.setUpdateGroup(true);
        }
    }
}