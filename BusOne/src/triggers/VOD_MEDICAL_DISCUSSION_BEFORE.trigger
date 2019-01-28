trigger VOD_MEDICAL_DISCUSSION_BEFORE on Medical_Discussion_vod__c (before delete, before insert, before update) {
    // fetch the appropriate error message based on delete or update    
    String errorText;
    if (Trigger.isDelete) {
        List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='MEDICAL_DISCUSSION_NO_DELETE_SUBMITTED' AND Category_vod__c='CallReport' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
        if(messages.size() != 0){
            errorText = messages[0].Text_vod__c;
        } else { // default to english hardcoded
            errorText = 'You may not delete a submitted Medical Discussion.';    
        }
    } else {
        List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='MEDICAL_DISCUSSION_NO_UPDATE_SUBMITTED' AND Category_vod__c='CallReport' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
        if(messages.size() != 0){
            errorText = messages[0].Text_vod__c;
        } else { // default to english hardcoded
            errorText = 'You may not update a submitted Medical Discussion.';    
        }    
    
    }
    
    List <String> parentCall = new List <String> ();
    Medical_Discussion_vod__c [] cRow = null;
            
    if (Trigger.isDelete) {
        cRow = Trigger.old;
     } else {
        cRow = Trigger.new;
     }

    for (Integer i = 0; i < cRow.size (); i++ ) {
        parentCall.add (cRow[i].Interaction_vod__c);          
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
                } else if ('Event_vod' == cRow[k].Attendee_Type_vod__c) {
                    cRow[k].Medical_Event_vod__c = cRow[k].Entity_Reference_Id_vod__c;
                    cRow[k].Entity_Reference_Id_vod__c = null;    
                }       
            }
        }
        
        if ((Trigger.isInsert || Trigger.isUpdate) && (cRow[k].Override_Lock_vod__c == true)) {
            cRow[k].Override_Lock_vod__c = false;
            continue;
        }

        if (VOD_CALL2_CHILD_COMMON.isLocked (cRow[k].Interaction_vod__c, calls)) {
            // error text is fetched based on if the trigger is delete or update already
            cRow[k].Interaction_vod__c.addError(errorText, false);            
        }
    }
    
    
}