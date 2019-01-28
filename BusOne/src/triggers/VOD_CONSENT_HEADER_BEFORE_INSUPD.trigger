trigger VOD_CONSENT_HEADER_BEFORE_INSUPD on Consent_Header_vod__c (before insert, before update) {

    //Set<String> newRecordsUniqueKeys = new Set<String> ();
    Set<String> recordTypeIds = new Set<String> ();
    for(Consent_Header_vod__c ch :Trigger.New) {     
        recordTypeIds.add(ch.recordTypeId);          
    }
    
    // now query the consent header object for the record type ids in the set
    Set<String> existingRecordsUniqueKeys = new Set<String> ();
    Set<Id> consentHeaderActiveUniqueIds = new Set<Id>();
    Map<Id, Set<String>> typeIdCHPickListMap = new Map<Id, Set<String>> ();  
    Map<Id, Set<String>> typeIdCHCountryPickListMap = new Map<Id, Set<String>>();
    
    
    for (Consent_Header_vod__c chdr : [SELECT Id, RecordTypeId, Country_vod__c, Language_vod__c, Approved_Email_Consent_Level_vod__c
                                   FROM Consent_Header_vod__c
                                   WHERE Status_vod__c = 'Active_vod' and RecordtypeId IN :recordTypeIds]) {
        String uniqueKey = chdr.recordTypeId + '_' + chdr.Country_vod__c + '_' + chdr.Language_vod__c;
        existingRecordsUniqueKeys.add(uniqueKey);
	consentHeaderActiveUniqueIds.add(chdr.Id);
        if (chdr.Approved_Email_Consent_Level_vod__c == 'Product_vod' || chdr.Approved_Email_Consent_Level_vod__c == 'Content_Type_vod') {
            String uniquePickValue = chdr.recordTypeId + '_' + chdr.Country_vod__c + '_' + chdr.Approved_Email_Consent_Level_vod__c; 
            system.debug(' the value of unique pick value is ' + uniquePickValue); 
            Set<String> countryAEPickValueUnique;
            Set<String> countryAEValues;
            if (typeIdCHPickListMap.containsKey(chdr.recordTypeId)) {
                countryAEPickValueUnique= typeIdCHPickListMap.get(chdr.recordTypeId);
                countryAEPickValueUnique.add(uniquePickValue );
                typeIdCHPickListMap.put(chdr.recordTypeId, countryAEPickValueUnique);
                countryAEValues = typeIdCHCountryPickListMap.get(chdr.recordTypeId);
                countryAEValues.add(chdr.Country_vod__c);
                typeIdCHCountryPickListMap.put(chdr.recordTypeId, countryAEValues);
            } else {
                countryAEPickValueUnique= new Set<String> ();

                // first time no need to check for error
                countryAEPickValueUnique.add(uniquePickValue);  
                typeIdCHPickListMap.put(chdr.recordTypeId, countryAEPickValueUnique);

                countryAEValues = new Set<String>();
                countryAEValues.add(chdr.Country_vod__c);
                typeIdCHCountryPickListMap.put(chdr.recordTypeId, countryAEValues);
            }            
            system.debug(' the unique pick list value added in the array is ' + uniquePickValue);
        }      
        
    }
    
    // fetch the error message to be thrown
    List<Message_vod__c> messageList = [Select Text_vod__c From Message_vod__c WHERE Name='ACTIVE_HEADER_UPDATE' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorTxt;
    if(messageList.size() != 0){
        errorTxt = messageList[0].Text_vod__c;
    } else { // default to english hardcoded
        errorTxt = 'No records can be created, updated or deleted when Consent Header record is active.';
    }

    List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='CONSENT_HEADER_UNIQUE_ERROR' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorText;
    if(messages.size() != 0){
        errorText = messages[0].Text_vod__c;
    } else { // default to english hardcoded
        errorText = 'Only one active record per country per language per recordtype';
    }
    
    // get next error message
    List<Message_vod__c> messagesPick = [Select Text_vod__c From Message_vod__c WHERE Name='DIFFERENT_AE_CONSENT_LEVEL' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorTextPick;
    if(messagesPick.size() != 0){
        errorTextPick = messagesPick[0].Text_vod__c;
    } else { // default to english hardcoded
        errorTextPick = 'Approved_Email_Consent_Level has been set differently for Consent_Header_vod of same country.';    
    }
    
    for(Consent_Header_vod__c ch :Trigger.New) {
        String uniqueKey = ch.recordTypeId + '_' + ch.Country_vod__c + '_' + ch.Language_vod__c;
        System.debug(' the unique key is ' + uniqueKey);
        if (ch.Status_vod__c == 'Active_vod') {
            if (consentHeaderActiveUniqueIds.contains(ch.Id)) {
                ch.addError(errorTxt, false);
                break;
            } else if (existingRecordsUniqueKeys.contains(uniqueKey)) {
                ch.addError(errorText , false);
                break;
            }
        }
        
        // also check if there is any error to be thrown for pick list value        
        String uniquePickValueErr = ch.recordTypeId + '_' + ch.Country_vod__c + '_' + ch.Approved_Email_Consent_Level_vod__c; 
        system.debug('current insertion record'+ uniquePickValueErr);
        if (ch.Status_vod__c == 'Active_vod' && typeIdCHPickListMap.containsKey(ch.RecordTypeId)) { 
            Set<String> pickValueUnique = typeIdCHPickListMap.get(ch.RecordTypeId);
            Set<String> countrySet = typeIdCHCountryPickListMap.get(ch.RecordTypeId);
            if (countrySet.contains(ch.Country_vod__c) && !pickValueUnique.contains(uniquePickValueErr)) {
                ch.addError(errorTextPick, false); 
                break;
            }              
        }
        
        // now if error was not thrown update the Inactive date time field
        if (ch.Status_vod__c == 'Inactive_vod') {
            ch.Inactive_Datetime_vod__c = System.now();            
        }  else { // clear the inactive date time field
            ch.Inactive_Datetime_vod__c = NULL;
        } 
    
    }

}