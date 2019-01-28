trigger VOD_CALL2_KEY_MESSAGE_BEFORE_TRIGGER on Call2_Key_Message_vod__c (before delete, before insert, before update) {
        
    VOD_ERROR_MSG_BUNDLE bnd = new VOD_ERROR_MSG_BUNDLE ();
    String NO_DEL_SUB = bnd.getErrorMsg('NO_DEL_SUB');
    String NO_UPD_SUB = bnd.getErrorMsg('NO_UPD_SUB');
    List <String> parentCall = new List <String> ();
            
    Call2_Key_Message_vod__c [] cRow = null;
    
    if (Trigger.isDelete) 
        cRow = Trigger.old;
    else
        cRow = Trigger.new;
            
    for (Integer i = 0; i < cRow.size (); i++ ) {
        parentCall.add (cRow[i].Call2_vod__c);          
    }
            
   Map <Id, Call2_vod__c> calls = null; 
    if (VOD_CHILD_SUBMIT.getPerformSubmitCheck() == true)        
        calls =  VOD_CALL2_CHILD_COMMON.getCallMap (parentCall);
        
    for (Integer k = 0; k < cRow.size(); k++) {
        if ((Trigger.isInsert || Trigger.isUpdate) && (cRow[k].Override_Lock_vod__c == true)) {
            cRow[k].Override_Lock_vod__c = false;
            continue;
        }
        if (calls == null)
            continue;
            
        if (VOD_CALL2_CHILD_COMMON.isLocked (cRow[k].Call2_vod__c, calls)) {
            if (Trigger.isDelete) {
                cRow[k].Call2_vod__c.addError(NO_DEL_SUB, false);
            }
            else {
                cRow[k].Call2_vod__c.addError(NO_UPD_SUB, false);
            }
        }
    }
    
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Integer i = 0 ;  i < Trigger.new.size(); i++)  {
            if (Trigger.new[i].Attendee_Type_vod__c != null && Trigger.new[i].Attendee_Type_vod__c.length() > 0 &&  
                Trigger.new[i].Entity_Reference_Id_vod__c != null && Trigger.new[i].Entity_Reference_Id_vod__c.length() > 0) {
                if ('Person_Account_vod' == Trigger.new[i].Attendee_Type_vod__c  || 'Group_Account_vod' == Trigger.new[i].Attendee_Type_vod__c ) {
                Trigger.new[i].Account_vod__c = Trigger.new[i].Entity_Reference_Id_vod__c;             
                Trigger.new[i].Entity_Reference_Id_vod__c = null;
                } else if ('Contact_vod' == Trigger.new[i].Attendee_Type_vod__c) {
                Trigger.new[i].Contact_vod__c = Trigger.new[i].Entity_Reference_Id_vod__c;
                Trigger.new[i].Entity_Reference_Id_vod__c = null; 
              } else if ('User_vod' == Trigger.new[i].Attendee_Type_vod__c) {
                Trigger.new[i].User_vod__c = Trigger.new[i].Entity_Reference_Id_vod__c;
                Trigger.new[i].Entity_Reference_Id_vod__c = null; 
              }
            }
            // Handle change in private sharing of associated Key Message.
            if (Trigger.new[i].Entity_Reference_KM_Id_vod__c != null && Trigger.new[i].Entity_Reference_KM_Id_vod__c.length() > 0) {
                Trigger.new[i].Key_Message_vod__c = Trigger.new[i].Entity_Reference_KM_Id_vod__c;
                Trigger.new[i].Entity_Reference_KM_Id_vod__c = null;
            }
          }
        }
}