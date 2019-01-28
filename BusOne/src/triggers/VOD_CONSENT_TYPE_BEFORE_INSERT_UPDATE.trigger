trigger VOD_CONSENT_TYPE_BEFORE_INSERT_UPDATE on Consent_Type_vod__c (before insert, before update) {

    // first get the record type
    // get the record type to do validation
    RecordType recType = [SELECT Id,DeveloperName FROM RecordType
                               WHERE SobjectType = 'Consent_Type_vod__c' AND DeveloperName = 'Approved_Email_vod'];
                               
    // fetch the error message
    List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='CONSENT_HEADER_TYPE_AE_PREFERENCE_MISMATCH' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorText;
    if(messages.size() != 0){
        errorText = messages[0].Text_vod__c;
    } else { // default to english hardcoded
        errorText = 'Approved_Email_Consent_Level_vod on Consent_Header_vod does not align with Product_Preference_vod on Content_Type_vod for Approved Email.';    
    }

    List<Message_vod__c> msg1 = [Select Text_vod__c From Message_vod__c WHERE Name='CONFLICTING_CONSENT_EXPIRATION_DURATION' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorText1;
    if(msg1.size() != 0){
        errorText1 = msg1[0].Text_vod__c;
    } else { // default to english hardcoded
        errorText1 = 'Conflicting consent expiration duration found. Consent_Custom_Duration_vod is populated but Consent_Expires_In_vod is not set to Custom_Duration_vod.';
    }

    List<Message_vod__c> msg2 = [Select Text_vod__c From Message_vod__c WHERE Name='NULL_CONSENT_EXPIRATION_DURATION' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorText2;
    if(msg2.size() != 0){
        errorText2 = msg2[0].Text_vod__c;
    } else { // default to english hardcoded
        errorText2 = 'Consent_Custom_Duration_vod cannot be empty when Consent_Expires_In_vod is set to Custom_Duration_vod.';
    }
                               
    // now for the record type check the pick list values
    Set<Id> consentHeaderIds = new Set<Id> ();
    for (Integer i = 0; i <Trigger.new.size(); i++) {
        Consent_Type_vod__c cType = Trigger.new[i]; 
        if (cType.RecordTypeId == recType.Id ) {
            consentHeaderIds.add(cType.Consent_Header_vod__c);
        }                 
    }
    
    Map<Id, String> consentHeaderPickMap = new Map<Id, String> ();
    for(Consent_Header_vod__c ch: [SELECT Id, Approved_Email_Consent_Level_vod__c from  Consent_Header_vod__c  where Id IN : consentHeaderIds]){
        consentHeaderPickMap.put(ch.Id, ch.Approved_Email_Consent_Level_vod__c);  
    }
    
    for (Integer i = 0; i <Trigger.new.size(); i++) {
        Consent_Type_vod__c cType = Trigger.new[i];
        if (cType.RecordTypeId == recType.Id  && consentHeaderPickMap.containsKey(cType.Consent_Header_vod__c)) {
            string pickValue = consentHeaderPickMap.get(cType.Consent_Header_vod__c);
            if (pickValue == 'Product_vod') {
              // now validate the prodcut preference value
              if (cType.Product_Preference_vod__c != 'All_Products_vod' && cType.Product_Preference_vod__c != 'All_Lines_vod' && cType.Product_Preference_vod__c != 'My_Setup_vod' && cType.Product_Preference_vod__c != 'Restrictive_My_Setup_vod') {
                // throw error
                cType.addError(errorText , false);
                break;
              }
            
            } else if (pickValue == 'Content_Type_vod') {
                if (cType.Product_Preference_vod__c != 'All_Lines_vod' && cType.Product_Preference_vod__c != 'All_Content_Types_vod') {
                    // throw error
                    cType.addError(errorText , false);
                    break;
                }           
            
            }
        }

        if (cType.Consent_Expires_In_vod__c != 'Custom_Duration_vod' && cType.Consent_Custom_Duration_vod__c != null) {
            cType.addError(errorText1);
            break;
        }

        if (cType.Consent_Expires_In_vod__c == 'Custom_Duration_vod' && cType.Consent_Custom_Duration_vod__c == null) {
            cType.addError(errorText2);
            break;
        } 
    }
}