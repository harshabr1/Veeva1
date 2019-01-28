trigger Affiliation_vod_before on Affiliation_vod__c bulk (before insert, before update) {

    // Block any new Affiliations that attempt to affiliate rejected shadow Accounts.
    VOD_SHADOW_ACCOUNT.rejectInvalidAccounts(
            Trigger.new, new List<String> {'From_Account_vod__c', 'To_Account_vod__c'});

	if (VOD_AFFILIATIONS.getMerge() == true) {
		 for (Integer i = 0; i < Trigger.new.size();i++) {
        // Set the External ID 
        
        Trigger.new[i].External_Id_vod__c =  Trigger.new[i].From_Account_vod__c + ':' + 
                                             Trigger.new[i].From_Contact_vod__c + ':' + 
                                             Trigger.new[i].To_Account_vod__c + ':'  +
                                             Trigger.new[i].To_Contact_vod__c + ':'   +
                                             Trigger.new[i].Role_vod__c;
		 }
		 return;
	}
     
    VOD_ERROR_MSG_BUNDLE errBundle = new VOD_ERROR_MSG_BUNDLE ();
    if (Trigger.new.size () > 30) {
        for (Affiliation_vod__c error : Trigger.new) {
            error.Id.addError(errBundle.getErrorMsg('LIMIT_AFFIL_MSG'), false);
        }   
        return; 
    }
    
    Set <String> keySet = new Set <String> ();
    List<Boolean> disableTrigger = VOD_AFFILIATIONS.getDisableTrigger();   
    disableTrigger.clear();
    for (Integer i = 0; i < Trigger.new.size();i++) {
        // Set the External ID 
        
        Trigger.new[i].External_Id_vod__c =  Trigger.new[i].From_Account_vod__c + ':' + 
                                             Trigger.new[i].From_Contact_vod__c + ':' + 
                                             Trigger.new[i].To_Account_vod__c + ':'  +
                                             Trigger.new[i].To_Contact_vod__c + ':'   +
                                             Trigger.new[i].Role_vod__c;
        
        if(Trigger.new[i].Disable_Trigger_vod__c == null)
            disableTrigger.add(false);
        else if(Trigger.new[i].Disable_Trigger_vod__c == true) {
            disableTrigger.add(true);
            Trigger.new[i].Disable_Trigger_vod__c = false;
        }
        else {
            disableTrigger.add(false);
        }
        
        if ( Trigger.new[i].To_Account_vod__c != null && Trigger.new[i].To_Contact_vod__c != null)  {
            Trigger.new[i].Id.addError(errBundle.getErrorMsg('ONLY_ONE_TO'), false);
                    
        }
        if ( Trigger.new[i].From_Account_vod__c != null && Trigger.new[i].From_Contact_vod__c != null) {
            Trigger.new[i].Id.addError(errBundle.getErrorMsg('ONLY_ONE_FROM'), false);
        }
        if ( Trigger.new[i].To_Account_vod__c == null && Trigger.new[i].To_Contact_vod__c == null) {
            Trigger.new[i].Id.addError(errBundle.getErrorMsg('MUST_HAVE_TO'), false);
        }
        if ( Trigger.new[i].From_Account_vod__c == null && Trigger.new[i].From_Contact_vod__c == null) {
            Trigger.new[i].Id.addError(errBundle.getErrorMsg('MUST_HAVE_FROM'), false);
        }
        
        if (Trigger.isUpdate) {
            if (Trigger.new[i].From_Account_vod__c != Trigger.old[i].From_Account_vod__c ||
                Trigger.new[i].To_Account_vod__c != Trigger.old[i].To_Account_vod__c ||
                Trigger.new[i].From_Contact_vod__c != Trigger.old[i].From_Contact_vod__c ||
                Trigger.new[i].To_Contact_vod__c != Trigger.old[i].To_Contact_vod__c ) {
                    
                Trigger.new[i].Id.addError(errBundle.getErrorMsg('AFFIL_NO_UPD_ENT'), false);
                
            }
        }
    }
   
    VOD_AFFILIATIONS.setDisableTrigger(disableTrigger);
}