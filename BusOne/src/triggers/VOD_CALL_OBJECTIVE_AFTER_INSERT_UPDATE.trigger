trigger VOD_CALL_OBJECTIVE_AFTER_INSERT_UPDATE on Call_Objective_vod__c (after insert, after update) {
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    if (vsc == null || vsc.Account_Plan_Sharing_vod__c == null || vsc.Account_Plan_Sharing_vod__c.intValue() != 1 || 
            !VOD_Utils.hasObject('Account_Tactic_vod__Share') || !VOD_Utils.hasObject('Call_Objective_vod__Share')) {
        return;
    }

    Set<Id> accountTacticIds = new Set<Id> ();     
    for (Call_Objective_vod__c callObjective: Trigger.newMap.values()) {
        if (callObjective.Account_Tactic_vod__c != null) {
            accountTacticIds.add(callObjective.Account_Tactic_vod__c);           
        }
    }
             
    // find all the account tactic shares available and then use it for call objective sharing 
    List<SObject> objectiveShares = new List<SObject>();     

    List<SObject> accountTacticShares = Database.query('SELECT Id, ParentId, Parent.Account_Plan_vod__c,  UserOrGroupId, AccessLevel FROM Account_Tactic_vod__Share ' +
                                                 'WHERE AccessLevel != null AND RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' and ParentId IN :accountTacticIds');         
    for(Call_Objective_vod__c callObjRecord : Trigger.newMap.values()) {
        for (SObject accountTacticShare : accountTacticShares) {
            String aPlanId = callObjRecord.Account_Plan_vod__c; 
            String aTactic = (String)accountTacticShare.get('ParentId');
            if (aTactic == null ) {
                continue;
            }
            if (aTactic.equals(callObjRecord.Account_Tactic_vod__c) && (aPlanId == null || aPlanId.equals(accountTacticShare.getSObject('Parent').get('Account_Plan_vod__c')))) {         
                // create share object for the call objective 
                String callObjectiveId = callObjRecord.Id;
                SObject callObjectiveShareObj  = Schema.getGlobalDescribe().get('Call_Objective_vod__Share').newSObject();            
                callObjectiveShareObj.put('UserOrGroupId', accountTacticShare.get('UserOrGroupId')) ;
                callObjectiveShareObj.put('ParentId' , callObjectiveId);
                callObjectiveShareObj.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
                if (accountTacticShare.get('AccessLevel') == 'Read' ) { 
                    callObjectiveShareObj.put('AccessLevel' , 'Read');
                } else {
                    callObjectiveShareObj.put('AccessLevel' , 'Edit');
                }                       
                objectiveShares.add(callObjectiveShareObj);      
            }    
        } 
    }
    
    if (objectiveShares.size() > 0) {
        insert objectiveShares;
    }            
}