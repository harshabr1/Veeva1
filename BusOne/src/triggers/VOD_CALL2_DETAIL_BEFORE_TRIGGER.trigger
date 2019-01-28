trigger VOD_CALL2_DETAIL_BEFORE_TRIGGER on Call2_Detail_vod__c (before delete, before insert, before update) {
            
    List <String> parentCall = new List <String> ();
    VOD_ERROR_MSG_BUNDLE bnd = new VOD_ERROR_MSG_BUNDLE();
    String NO_DEL_SUB = bnd.getErrorMsg('NO_DEL_SUB');
    String NO_UPD_SUB = bnd.getErrorMsg('NO_UPD_SUB');
    Call2_Detail_vod__c [] cDetail = null;
            
    if (Trigger.isDelete) 
        cDetail = Trigger.old;
    else
        cDetail = Trigger.new;
	
	Integer detailPriority = null;
    for (Integer i = 0; i < cDetail.size (); i++ ) {
	   if ( !Trigger.isDelete ) {
	      //Need to cast to integer first to exclude the decimal point from the string result
	      detailPriority = (Integer)cDetail[i].Detail_Priority_vod__c;
          cDetail[i].Detail_Priority_Text_vod__c = string.valueof(detailPriority);
        }
        parentCall.add (cDetail[i].Call2_vod__c);           
    }
    
    Map <Id, Call2_vod__c> calls = null; 
    if (VOD_CHILD_SUBMIT.getPerformSubmitCheck() == true)        
    	calls =  VOD_CALL2_CHILD_COMMON.getCallMap (parentCall);
    for (Integer k = 0; k < cDetail.size(); k++) {
        if ((Trigger.isInsert || Trigger.isUpdate) && (cDetail[k].Override_Lock_vod__c == true)) {
            cDetail[k].Override_Lock_vod__c = false;
            continue;
        }
        if (calls == null)
        	continue;
        	            
        if (VOD_CALL2_CHILD_COMMON.isLocked (cDetail[k].Call2_vod__c, calls)) {
            if (Trigger.isDelete) {
                cDetail[k].Call2_vod__c.addError(NO_DEL_SUB, false);
            }
            else {
                cDetail[k].Call2_vod__c.addError(NO_UPD_SUB, false);
            }
        }
    }
}