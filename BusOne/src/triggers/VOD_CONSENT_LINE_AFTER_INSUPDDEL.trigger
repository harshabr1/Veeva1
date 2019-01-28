trigger VOD_CONSENT_LINE_AFTER_INSUPDDEL on Consent_Line_vod__c (after insert, after update, after delete) {
    Boolean errorFound = false;
    List<Consent_Line_vod__c> cls = new List<Consent_Line_vod__c> (); 
    Set<String> contextTypeIds = new Set<String>();   
    if (Trigger.isInsert || Trigger.isUpdate) {    
        cls = Trigger.New;
        for(Consent_Line_vod__c cl : Trigger.New) {
               contextTypeIds.add(cl .Consent_Type_vod__c);
        }
          
    } else if (Trigger.isDelete) {
        cls = Trigger.Old; 
        for(Consent_Line_vod__c cl : Trigger.Old) {
               contextTypeIds.add(cl.Consent_Type_vod__c);
        }   
    
    }
    
    for(Consent_Header_vod__c chr : [SELECT Id, Status_vod__c FROM Consent_Header_vod__c Where Id IN (select Consent_Header_vod__c from Consent_Type_vod__c where ID IN: contextTypeIds)]){        
        if (chr.Status_vod__c == 'Active_vod') {
            errorFound = true;     
            break;        
        }
    }     
    
    if (errorFound) {
         // fetch the error message to be thrown
        List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='ACTIVE_HEADER_UPDATE' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
        String errorText;
        if(messages.size() != 0){
            errorText = messages[0].Text_vod__c;
        } else { // default to english hardcoded
            errorText = 'No records can be created, updated or deleted when Consent Header record is active.';    
        }
        
        
        for(Consent_Line_vod__c cl : cls) {
            cl.addError(errorText, false);        
        }   

    }
    
    
}