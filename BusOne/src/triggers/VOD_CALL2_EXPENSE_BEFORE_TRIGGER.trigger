trigger VOD_CALL2_EXPENSE_BEFORE_TRIGGER on Call2_Expense_vod__c (before delete, before insert, before update) {
    List <String> parentCall = new List <String> ();
    
    VOD_ERROR_MSG_BUNDLE bnd = new VOD_ERROR_MSG_BUNDLE ();
    String NO_DEL_SUB = bnd.getErrorMsg('NO_DEL_SUB');
    String NO_UPD_SUB = bnd.getErrorMsg('NO_UPD_SUB');
            
    Call2_Expense_vod__c [] cRow = null;
    
    if (Trigger.isDelete) 
        cRow = Trigger.old;
    else
        cRow = Trigger.new;

    for (Integer i = 0; i < cRow.size (); i++ ) {
        parentCall.add (cRow[i].Call2_vod__c);          
    }

    Map <Id, Call2_vod__c> calls =  VOD_CALL2_CHILD_COMMON.getCallMap (parentCall);
    for (Integer k = 0; k < cRow.size(); k++) {
    	  	if (Trigger.isInsert || Trigger.isUpdate) {
    		if (cRow[k].Attendee_Type_vod__c != null && cRow[k].Attendee_Type_vod__c.length() > 0 &&  
    		    cRow[k].Entity_Reference_Id_vod__c != null && cRow[k].Entity_Reference_Id_vod__c.length() > 0) {
    		    if ('Person_Account_vod' == cRow[k].Attendee_Type_vod__c  || 'Group_Account_vod' == cRow[k].Attendee_Type_vod__c ) {
    				cRow[k].Account_vod__c = cRow[k].Entity_Reference_Id_vod__c;
    				cRow[k].Entity_Reference_Id_vod__c = null; 	 			    	
    		    } else if ('Contact_vod' == cRow[k].Attendee_Type_vod__c) {
    				cRow[k].Contact_vod__c = cRow[k].Entity_Reference_Id_vod__c;
    				cRow[k].Entity_Reference_Id_vod__c = null; 	 
    			} else if ('User_vod' == cRow[k].Attendee_Type_vod__c) {
    				cRow[k].User_vod__c = cRow[k].Entity_Reference_Id_vod__c;
    				cRow[k].Entity_Reference_Id_vod__c = null; 	 
    			}
  		    	
    		}
    	}
        if ((Trigger.isInsert || Trigger.isUpdate) && (cRow[k].Override_Lock_vod__c == true)) {
            cRow[k].Override_Lock_vod__c = false;
            continue;
        }            

        if (VOD_CALL2_CHILD_COMMON.isLocked (cRow[k].Call2_vod__c, calls)) {
            if (Trigger.isDelete) {
                cRow[k].Call2_vod__c.addError(NO_DEL_SUB, false);
            }
            else {
                cRow[k].Call2_vod__c.addError(NO_UPD_SUB, false);
            }
        }
    }
}