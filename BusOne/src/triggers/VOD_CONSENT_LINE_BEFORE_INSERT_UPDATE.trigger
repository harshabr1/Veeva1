trigger VOD_CONSENT_LINE_BEFORE_INSERT_UPDATE on Consent_Line_vod__c (before insert, before update) {
    // get the record type to do validation
    RecordType recType = [SELECT Id,DeveloperName FROM RecordType
                               WHERE SobjectType = 'Consent_Line_vod__c' AND DeveloperName = 'Content_Type_vod'];
    // fetch the error message
    
    List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='NULL_CONTENT_TYPE_CONSENT_LINE' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorText;
    if(messages.size() != 0){
        errorText = messages[0].Text_vod__c;
    } else { // default to english hardcoded
        errorText = 'Content_Type_vod lookup needs to be populated for Consent_Line_vod record of recordtype Content_Type_vod.';    
    }
    
    // get the approved email record type of the consent type of the consent line
    RecordType recTypeCType = [SELECT Id,DeveloperName FROM RecordType
                               WHERE SobjectType = 'Consent_Type_vod__c' AND DeveloperName = 'Approved_Email_vod'];
     Set<Id> consentTypeIds = new Set<Id>();   
                               
    for (Integer i = 0; i <Trigger.new.size(); i++) {
        Consent_Line_vod__c cl = Trigger.new[i];
        if (cl.RecordTypeId == recType.Id && cl.Content_Type_vod__c == null) {
            cl.addError(errorText , false); 
            break;       
        } 
        consentTypeIds.add(cl.Consent_Type_vod__c);      
    }
    
    // now fetch all the consent types with approved email record type
    Map<Id, Set<String>> typeIdCLineRecTypesMap = new Map<Id, Set<String>> ();
    Set<Id> errorConsentTypeIds = new Set<Id> ();
    System.debug(' the set of consent type ids are ' + consentTypeIds);    
    
    
    for(Consent_Line_vod__c  cLine: [SELECT Id, RecordTypeId, Consent_Type_vod__c, Consent_Type_vod__r.RecordTypeId FROM Consent_Line_vod__c  where Consent_Type_vod__r.RecordType.Name= 'Approved_Email_vod' AND Consent_Type_vod__c IN : consentTypeIds]){
        System.debug(' inside the for loop to check error messages ');
        Set<String> consentLineRecTypes;
        if (typeIdCLineRecTypesMap.containsKey(cLine.Consent_Type_vod__c)) {
            consentLineRecTypes= typeIdCLineRecTypesMap.get(cLine.Consent_Type_vod__c);            
            system.debug(' for the consent type ' +  cLine.Consent_Type_vod__c  + 'the value of consent line record type is' + cLine.RecordTypeId); 
            if (!consentLineRecTypes.contains(cLine.RecordTypeId)) {
                // means this is a different record type throw error
                errorConsentTypeIds.add(cLine.Consent_Type_vod__c);
                System.debug(' found the consent type id for which the error need to be thrown');
            }
            // keep adding the same record type
            consentLineRecTypes.add(cLine.RecordTypeId);
            typeIdCLineRecTypesMap.put(cLine.Consent_Type_vod__c, consentLineRecTypes);     
                       
        } else {
            consentLineRecTypes = new Set<String> ();  
            // first time no need to check for error
            consentLineRecTypes.add(cLine.RecordTypeId);  
            typeIdCLineRecTypesMap.put(cLine.Consent_Type_vod__c, consentLineRecTypes);
        } 
    }
    
    if (typeIdCLineRecTypesMap.size() > 0) {
        for (Consent_Line_vod__c cLine: Trigger.new) {
            if (typeIdCLineRecTypesMap.containsKey(cLine.Consent_Type_vod__c)) {
                Set<String> consentLineRecTypes= typeIdCLineRecTypesMap.get(cLine.Consent_Type_vod__c);
                if (!consentLineRecTypes.contains(cLine.RecordTypeId)) {
                    // means this is a different record type throw error
                    errorConsentTypeIds.add(cLine.Consent_Type_vod__c);
                    System.debug(' found the consent type id for which the error need to be thrown');
                }
            }
        }
    }

    // value of error consent type ids
    system.debug(' the value of consent type ids that need to be thrown error ' + errorConsentTypeIds);   
    
    // now through error at the right consent line
    if (errorConsentTypeIds.size() > 0 ) {
        // fetch the error message
        List<Message_vod__c> recordTypeErrors = [Select Text_vod__c From Message_vod__c WHERE Name='CONSENT_LINE_DIFFERENT_RECORDTYPE_ERROR' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
        String recTypeErrorMsg;
        if(recordTypeErrors.size() != 0) {
            recTypeErrorMsg = recordTypeErrors[0].Text_vod__c;
        } else { // default to english hardcoded
            recTypeErrorMsg = 'Child Consent_Line_vod records can be either Product_vod or Content_Type_vod recordtypes but not both.';    
        }
    
        
        for (Integer i = 0; i <Trigger.new.size(); i++) {
            Consent_Line_vod__c cl = Trigger.new[i];
            System.debug(' final for loop to through error');
            if (errorConsentTypeIds.contains(cl.Consent_Type_vod__c)) {
                System.debug(' found the error  for consent type' + cl.Consent_Type_vod__c);
                cl.addError(recTypeErrorMsg, false);
                break;
            }        
        }
    }
}