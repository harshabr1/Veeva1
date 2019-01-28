trigger VEEVA_MULTICHANNEL_CONSENT_AFTER_INSUPD on Multichannel_Consent_vod__c (after insert, after update) {
    
    if(Trigger.new.size() == 0){
        return;
    }
    
    Set<String> objectFields = Schema.SObjectType.Multichannel_Consent_vod__c.fields.getMap().keySet();
    
    String optInValue = 'Opt_In_vod';
    String optOutValue = 'Opt_Out_vod';
    String optInPendingValue = 'Opt_In_Pending_vod';
    Boolean subChannelVisible = false;
    
    if (objectFields.contains('Sub_Channel_Key_vod__c'.toLowerCase())) {
    	subChannelVisible = true;
    }
    
    Set<ID> accountIds = new Set<ID>();
    for (Multichannel_Consent_vod__c record: Trigger.new) {
    	accountIds.add(record.Account_vod__c);
    }
    
    // Retrieve all consent candidates which might need update
    List<Multichannel_Consent_vod__c> candidates = new List<Multichannel_Consent_vod__c>(); 
    if (subChannelVisible) {
    	candidates = [SELECT Id, Account_vod__c, Opt_Type_vod__c, RecordTypeId, Channel_Value_vod__c, Opt_Expiration_Date_vod__c, Sub_Channel_Key_vod__c, Capture_Datetime_vod__c, Product_vod__c, Detail_Group_vod__c, Content_Type_vod__c FROM Multichannel_Consent_vod__c WHERE (Opt_Expiration_Date_vod__c=Null OR Opt_Expiration_Date_vod__c>TODAY) AND Account_vod__c IN :accountIds ORDER BY Capture_Datetime_vod__c DESC];
    }
    else {
    	candidates = [SELECT Id, Account_vod__c, Opt_Type_vod__c, RecordTypeId, Channel_Value_vod__c, Opt_Expiration_Date_vod__c, Capture_Datetime_vod__c, Product_vod__c, Detail_Group_vod__c, Content_Type_vod__c FROM Multichannel_Consent_vod__c WHERE (Opt_Expiration_Date_vod__c=Null OR Opt_Expiration_Date_vod__c>TODAY) AND Account_vod__c IN :accountIds ORDER BY Capture_Datetime_vod__c DESC];
    }
        
    Map<ID, Multichannel_Consent_vod__c> consentMap = new Map<ID, Multichannel_Consent_vod__c>();
    
    // Find records to be update
    for (Multichannel_Consent_vod__c record: Trigger.new) {
   	
    	String recordTypeId = record.RecordTypeId; 
    	String productId = record.Product_vod__c;
    	String detailGroupId = record.Detail_Group_vod__c;
    	String channel = record.Channel_Value_vod__c;
    	String optType = record.Opt_Type_vod__c;
    	String accountId = record.Account_vod__c;
    	Datetime captureDate = record.Capture_Datetime_vod__c;
    	Datetime expirationDate = record.Opt_Expiration_Date_vod__c;
    	String contentType = record.Content_Type_vod__c;
    	
    	Set<String> updateType = new Set<String>();
    	if  (optType == optInValue) {
    		updateType.add(optOutValue);
    	}
    	else if(optType == optOutValue) {
    	    updateType.add(OptInValue);
    	    updateType.add(OptInPendingValue);
    	}
    	
    	String subChannel = null;
    	if (subChannelVisible) {
    		subChannel = record.Sub_Channel_Key_vod__c;
    	}
    	
    	if ((expirationDate == null || expirationDate >= Date.today()) && !updateType.isEmpty()) {
    		for (Multichannel_Consent_vod__c candidate : candidates) {
    			if (candidate.RecordTypeId == recordTypeId && candidate.Account_vod__c == accountId && candidate.Capture_Datetime_vod__c <= captureDate && updateType.contains(candidate.Opt_Type_vod__c) && candidate.Channel_Value_vod__c == channel) {
    				// product opt
    				if (productId != null || detailGroupId != null) {
    					if (candidate.Product_vod__c == productId && candidate.Detail_Group_vod__c == detailGroupId) {
    						ID mcid = candidate.Id;
    						candidate.Opt_Expiration_Date_vod__c = Date.today().addDays(-1);
    						consentMap.put(mcid, candidate);
    					}
    				}
    				// custom channel opt
    				else if (subChannel != null) {
    					if (candidate.Sub_Channel_Key_vod__c == subChannel)	{
    						ID mcid = candidate.Id;
    						candidate.Opt_Expiration_Date_vod__c = Date.today().addDays(-1);
    						consentMap.put(mcid, candidate);
    					}
    				}
					 // content type opt
					else if(contentType != null){
						if(candidate.Content_Type_vod__c == contentType){
							ID mcid = candidate.Id;
							candidate.Opt_Expiration_Date_vod__c = Date.today().addDays(-1);
							consentMap.put(mcid, candidate);
						}
					}
    				// global 
    				else {
    					ID mcid = candidate.Id;
    					candidate.Opt_Expiration_Date_vod__c = Date.today().addDays(-1);
    					consentMap.put(mcid, candidate);
    				}
    				
    			}
    		}
    	}
    	
    }
    
    List<Multichannel_Consent_vod__c> toUpdate = consentMap.values();
    update toUpdate; 
}