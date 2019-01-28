trigger VEEVA_SENT_EMAIL_BEFORE_INSERT on Sent_Email_vod__c (before insert) {
    VEEVA_ApprovedDocumentAccessChecker checker = new VEEVA_ApprovedDocumentAccessChecker();
    VEEVA_KeyMessageAccessChecker keyMsgChecker = new VEEVA_KeyMessageAccessChecker();
    
    Map<String, Boolean> keyMsgAccessMap = keyMsgChecker.getUserAccessToKeyMessageForAE();
    Boolean allowMapKeyMsg = keyMsgAccessMap.get('Approved_Document_vod__c') && keyMsgAccessMap.get('Sent_Email_vod__c');
    Set<Id> docIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();
    Set<Id> toUserIds = new Set<Id>(); // for EM, we can send email to Users
    Set<Id> userIds = new Set<Id>();
    
    //go through the emails and pull out the values we need
    for (Sent_Email_vod__c se : trigger.new){
        docIds.add(se.Approved_Email_Template_vod__c);  
        accountIds.add(se.Account_vod__c);
        toUserIds.add(se.User_vod__c);
        userIds.add(se.OwnerId);
    }
    
    Map<Id, Boolean> accessMap = checker.userHasAccessToApprovedDocuments(docIds);
    Map<Id, Boolean> accountAccessMap = checker.userHasAccessToAccounts(accountIds);
    Map<Id, Boolean> userAccessMap = checker.userHasAccessToUsers(toUserIds);
   
   
    //can we set the territory?   
    boolean setTerritory = false;
    Map<Id, UserTerritory> userTerritoryMap = null; 
    Map<Id, Territory> territoryMap = null;
    Map<Id, Group> groupMap = null; 
    List<AccountShare> accountShareList = null;
    //if we can set the territory then get the needed territory related values 
    if(Schema.sObjectType.Sent_Email_vod__c.fields.Territory_vod__c.isCreateable()){
        setTerritory = true;
        userTerritoryMap = new Map<Id,UserTerritory>([SELECT Id, UserId, TerritoryId FROM UserTerritory WHERE UserId IN :userIds]);
        List<Id> territoryIds = new List<Id>();
        for(UserTerritory ut : userTerritoryMap.values()){
            territoryIds.add(ut.TerritoryId);            
        }
        territoryMap = new Map<Id,Territory>([SELECT Name, Id FROM Territory WHERE Id IN :territoryIds]);
        groupMap = new Map<Id, Group>([SELECT Id, relatedId FROM Group where relatedId IN :territoryMap.keySet()]);
        accountShareList = [SELECT UserOrGroupId, AccountId FROM AccountShare WHERE UserOrGroupId IN :groupMap.keySet() AND AccountId IN :accountIds];
    }      

    // get all the templates
    Map<Id, Approved_Document_vod__c> documentMap = new Map<Id, Approved_Document_vod__c>([SELECT Id, Key_Message_vod__c, Key_Message_vod__r.Name FROM Approved_Document_vod__c WHERE Id =: docIds]);
    // get all the key messages in the templates
    Map<Id, Key_Message_vod__c> keyMsgMap = new Map<Id, Key_Message_vod__c>();
    for(Approved_Document_vod__c doc : documentMap.values()) {
        keyMsgMap.put(doc.Key_Message_vod__c, doc.Key_Message_vod__r);
    }

    // get the record type id for Event Management SE
    List<RecordType> rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Sent_Email_vod__c' AND DeveloperName = 'Events_Management_vod'];
    Id emRecordTypeId = (rt.size() == 1)? rt.get(0).Id : null;

    //go through emails and set new values
    for (Sent_Email_vod__c se : trigger.new){
        Id templateID = se.Approved_Email_Template_vod__c; 
        //if the template is not accessible
        if(accessMap.get(templateID) == false){
            se.Failure_Msg_vod__c= 'Failed to send because template with the ID '+se.Approved_Email_Template_vod__c + ' could not be accessed';
            se.Approved_Email_Template_vod__c = null;
            se.Status_vod__c = 'Failed_vod';
        }
	// Update key message if available in template
        if (allowMapKeyMsg) {
            Approved_Document_vod__c template = documentMap.get(templateID);
            if (template.Key_Message_vod__c != NULL) {
                // Check FLS for key message
                Id keyMsgId = template.Key_Message_vod__c;
                Key_Message_vod__c keyMsg = keyMsgMap.get(keyMsgId);
                if (keyMsg != null) {
                    se.Key_Message_vod__c = keyMsgId;
                }
            }
        }

        Id accountID = se.Account_vod__c;
        Id toUserID = se.User_vod__c;
        if(emRecordTypeId != null && se.RecordTypeId == emRecordTypeId) {
            // for EM we can send email to both User and Account
            if(accountID != null && accountAccessMap.get(accountID) == false) {
                se.Failure_Msg_vod__c= 'Failed to send because Account with the ID ' + accountID  + ' could not be accessed';
                se.Account_vod__c = null;
                se.Status_vod__c = 'Failed_vod';
            } else if (toUserID != null && userAccessMap.get(toUserID) == false) {
                se.Failure_Msg_vod__c= 'Failed to send because User with the ID ' + toUserID  + ' could not be accessed';
                se.User_vod__c = null;
                se.Status_vod__c = 'Failed_vod';
            } else if(accountID != null && toUserID != null) {
                se.Failure_Msg_vod__c= 'Failed to send because of missing Account or User lookup';
                se.Status_vod__c = 'Failed_vod';
            }
        } else if(accountAccessMap.get(accountID) == false) {
            //if the account is not accessible
            se.Failure_Msg_vod__c= 'Failed to send because Account with the ID ' + accountID  + ' could not be accessed';
            se.Account_vod__c = null;
            se.Status_vod__c = 'Failed_vod';
        }
        
        //if we can set the territory and there is no territory already
        if(setTerritory && se.Territory_vod__c == Null){
            String userOrGroupId = null;
            //find the AccountShare object for this email's account
            for(AccountShare acctShare: accountShareList){
                if(accountID.equals(acctShare.AccountId)){
                    userOrGroupId = acctShare.UserOrGroupId;
                    break;
                }
            }
            //if we have a group ID then get the territory for that group
            if(userOrGroupId != null){
                for(Group g: groupMap.values()){
                    if(userOrGroupId.equals(g.Id)){
                        String terrId = g.relatedId;
                        String terrName = TerritoryMap.get(terrId).Name;
                        se.Territory_vod__c = terrName;
                        break;
                    }      
                } 
            }
            //otherwise just get the territory for this user
            else{
                for(UserTerritory userTerr : UserTerritoryMap.values()){
                    Territory terr = territoryMap.get(userTerr.TerritoryId );
                    if(se.OwnerId.equals(userTerr.UserId) && terr != null){
                        String terrName = terr.Name;
                        se.Territory_vod__c = terrName;
                        break;                        
                    }
                }          
            }
        }
    }  
   
}