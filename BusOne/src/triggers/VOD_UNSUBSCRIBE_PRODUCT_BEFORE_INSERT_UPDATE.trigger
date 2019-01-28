trigger VOD_UNSUBSCRIBE_PRODUCT_BEFORE_INSERT_UPDATE on Unsubscribe_Product_vod__c (before insert, before update) {

    // get the record type to do validation
    RecordType recTypeCT = [SELECT Id, DeveloperName FROM RecordType
                               WHERE SobjectType = 'Unsubscribe_Product_vod__c' AND DeveloperName = 'Approved_Email_Content_Type_Unsubscribe_vod'];
                               
    RecordType recTypeUnsubscribe = [SELECT Id, DeveloperName FROM RecordType
                               WHERE SobjectType = 'Unsubscribe_Product_vod__c' AND DeveloperName = 'Approved_Email_Unsubscribe_vod'];                                                 
    // fetch the error message    
    List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='NULL_CONTENT_TYPE_UNSUBSCRIBE_PRODUCTS' AND Category_vod__c='ApprovedEmail' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorText;
    if(messages.size() != 0){
        errorText = messages[0].Text_vod__c;
    } else { // default to english hardcoded
        errorText = 'Content_Type_vod lookup needs to be populated for Unsubscribe_Product_vod record of recordtype Content_Type_vod.';    
    }
    
    // get the un subscribe look up value
    Set<Id> unsubscribeIds = new Set<Id>();
    Set<Id> unsubscribeProductsIds = new Set<Id> ();
        
    // through error if the content type is empty for a particular record type
    for (Integer i = 0; i <Trigger.new.size(); i++) {
        Unsubscribe_Product_vod__c  uProd = Trigger.new[i];
        if (uProd.RecordTypeId == recTypeCT.Id && uProd.Content_Type_vod__c == null) {
            uProd.addError(errorText , false); 
            break;       
        }
        unsubscribeIds.add(uProd.Unsubscribe_vod__c);           
    }   
    Map<Id, String> unsubscribeIdCSLevelMap = new Map<Id, String>();
    for(Unsubscribe_vod__c unsubscribe:  [SELECT Id, Consent_Level_vod__c from Unsubscribe_vod__c where Id IN: unsubscribeIds]) {
        if (!unsubscribeIdCSLevelMap.containsKey(unsubscribe.Id)) {
            unsubscribeIdCSLevelMap.put(unsubscribe.Id, unsubscribe.Consent_Level_vod__c);
        }
    }
    
    
    // get all the
    Map<Id, Set<String>> unsubscribeIDRecTypesMap = new Map<Id, Set<String>> ();
    // for each unsubscribe id get the pick list value 
    Map<Id, String> unsubscribeConsentPickMap = new Map<Id, String> ();    
    Set<Id> errorParentIds = new Set<Id> ();
    
    for(Unsubscribe_Product_vod__c uProd: [SELECT Id, Unsubscribe_vod__c, Unsubscribe_vod__r.Consent_Level_vod__c, RecordTypeId FROM Unsubscribe_Product_vod__c where Unsubscribe_vod__c IN : unsubscribeIds]) {
        Set<String> unsubscribeProdRecTypes;
        system.debug('inside the first for loop ');
        System.debug(' the value of rec type for unsubcribe id is ' + uProd.Unsubscribe_vod__c + ' the value of record type is '  + uProd.RecordTypeId);      
        if (unsubscribeIDRecTypesMap.containsKey(uProd.Unsubscribe_vod__c)) {
            unsubscribeProdRecTypes = unsubscribeIDRecTypesMap.get(uProd.Unsubscribe_vod__c);
            /*if (!unsubscribeProdRecTypes.contains(uProd.RecordTypeId)) {
                errorParentIds.add(uProd.Unsubscribe_vod__c);
            } */  
            unsubscribeProdRecTypes.add(uProd.RecordTypeId);
            unsubscribeIDRecTypesMap.put(uProd.Unsubscribe_vod__c, unsubscribeProdRecTypes);                
        } else { // first time entry 
            system.debug('first time entry ');      
            unsubscribeProdRecTypes = new Set<String> ();
            unsubscribeProdRecTypes.add(uProd.RecordTypeId);
            unsubscribeIDRecTypesMap.put(uProd.Unsubscribe_vod__c, unsubscribeProdRecTypes); 
            system.debug('added value key is ' + uProd.Unsubscribe_vod__c + ' the value set is ' + unsubscribeProdRecTypes);
        }
         
        System.debug(' the value of pick list in unsubscribe level is ' + uProd.Unsubscribe_vod__r.Consent_Level_vod__c);
        unsubscribeConsentPickMap.put(uProd.Unsubscribe_vod__c, uProd.Unsubscribe_vod__r.Consent_Level_vod__c);  
        
    }
    
    // throw error if all siblings record type don't match
    List<Message_vod__c> messagesRecType = [Select Text_vod__c From Message_vod__c WHERE Name='MISCONFIG_UNSUBSCRIBE_PRODUCT_RECORDTYPE' AND Category_vod__c='ApprovedEmail' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorTextRecType;
    if(messagesRecType.size() != 0){
        errorTextRecType = messagesRecType[0].Text_vod__c;
    } else { // default to english hardcoded
        errorTextRecType = 'Sibling Unsubscribe_Product_vod records cannot be of different recordtypes. Check recordtype other Unsubscribe_Product_vod records for parent Unsubscribe_vod record.';    
    }
    
    // error for different consent level
    List<Message_vod__c> messagesConsentLevel = [Select Text_vod__c From Message_vod__c WHERE Name='MISMATCH_PRODUCT_CONSENT_LEVEL_UNSUBSCRIBE' AND Category_vod__c='ApprovedEmail' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorTextConsentLevel;
    if(messagesConsentLevel.size() != 0){
        errorTextConsentLevel= messagesConsentLevel[0].Text_vod__c;
    } else { // default to english hardcoded
        errorTextConsentLevel= 'Parent Unsubscribe_vod record has Consent_Level_vod set to Product_vod. Child Unsubscribe_vod needs to be of recordtype Approved_Email_Unsubscribe_vod';    
    }
    
    List<Message_vod__c> messagesConsentCTLevel = [Select Text_vod__c From Message_vod__c WHERE Name='MISMATCH_CONTENT_TYPE_CONSENT_LEVEL_UNSUBSCRIBE' AND Category_vod__c='ApprovedEmail' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorTextConsentCTLevel;
    if(messagesConsentCTLevel.size() != 0){
        errorTextConsentCTLevel= messagesConsentCTLevel[0].Text_vod__c;
    } else { // default to english hardcoded
        errorTextConsentCTLevel= 'Parent Unsubscribe_vod record has Consent_Level_vod set to Content_Type_vod. Child Unsubscribe_vod needs to be of recordtype Approved_Email_Content_Type_Unsubscribe_vod';    
    }
    
    // fetch the record type for unsubscribe product
    
    for (Integer i = 0; i <Trigger.new.size(); i++) {
        Unsubscribe_Product_vod__c  uProd = Trigger.new[i];
        // if already there were discrepancy for a particular record type we can not save the recordS
        // check with Nishant before enabling this due to regression fears
        /*if (errorParentIds.contains(uProd.Unsubscribe_vod__c)) {
            uProd.addError(errorTextRecType , false);    
        } */
        system.debug(' inside the record type error thrown loop');
        system.debug(' the value of rec type set for  ' + uProd.Unsubscribe_vod__c);
        system.debug(' the current check is for rec type is   ' + uProd.RecordTypeId); 
        if (unsubscribeIDRecTypesMap.containsKey(uProd.Unsubscribe_vod__c)) {
            // now check if record type conflicts
            Set<String> childRcTypes = unsubscribeIDRecTypesMap.get(uProd.Unsubscribe_vod__c);
            if (!childRcTypes.contains(uProd.RecordTypeId)) {
                uProd.addError(errorTextRecType , false);  
                break;    
            }          
        
        }
        
        // check the validation of record type and the parent's pick list value
        if (unsubscribeIdCSLevelMap.containsKey(uProd.Unsubscribe_vod__c)) {
            String pickValue = unsubscribeIdCSLevelMap.get(uProd.Unsubscribe_vod__c);
            // now check the record type
            system.debug('pickValue ' + pickValue + ' uProd.RecordTypeId= ' + uProd.RecordTypeId + ' recTypeUnsubscribe.Id= ' + recTypeUnsubscribe.Id);
            if (pickValue == 'Product_vod' && uProd.RecordTypeId != recTypeUnsubscribe.Id) {
                uProd.addError(errorTextConsentLevel, false);    
                break;     
            } 
            system.debug('pickValue ' + pickValue + ' uProd.RecordTypeId= ' + uProd.RecordTypeId + ' recTypeCT.Id= ' + recTypeCT.Id);
            if (pickValue == 'Content_Type_vod' && uProd.RecordTypeId != recTypeCT.Id) {
                uProd.addError(errorTextConsentCTLevel, false);  
                break;          
            }       
        
        }   
    }
}