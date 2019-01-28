trigger VOD_ACCOUNT_TACTIC_AFTER_INSERT_UPDATE on Account_Tactic_vod__c (after insert, after update) {
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    if (vsc == null || vsc.Account_Plan_Sharing_vod__c == null || vsc.Account_Plan_Sharing_vod__c.intValue() != 1) {
        return;
    }

    Set<Id> planTacticIds = new Set<Id> ();    
    
    for(Account_Tactic_vod__c accountTactic : Trigger.newMap.values()) {        
        planTacticIds.add(accountTactic.Plan_Tactic_vod__c);       
    }   
    
    
    // query plan tactic share    
    Set<SObject> planTacticShareObjects = new Set<SObject> ();
    
    if (VOD_Utils.hasObject('Plan_Tactic_vod__Share')) {
        List<SObject> planTacticShares = Database.query('SELECT Id, ParentId, Parent.Account_Plan_vod__c, AccessLevel, UserOrGroupId FROM Plan_Tactic_vod__Share ' +
                                                     'WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' and ParentId IN :planTacticIds');         
        for (SObject planTacticShare: planTacticShares) {
            planTacticShareObjects.add(planTacticShare);
        } 
    }    
    
    // now we have all details to add in the account tactic share
    List<SObject> accountTacticShareObjects = new List<SObject> ();   
    List<ID> accountTacticIds = new List<ID> ();
    Map<Id, SObject> idShareMap = new Map<Id, Sobject> ();
    for (Account_Tactic_vod__c  accountTacticRecord : Trigger.newMap.values()) {
        String accountPlanId = accountTacticRecord.Account_Plan_vod__c;
        String planTacticId =  accountTacticRecord.Plan_Tactic_vod__c; 
        if (accountPlanId == null || planTacticId == null) {
            continue;
        }       
        for (SObject planTacticShare :planTacticShareObjects) {
            String aPlanId = (String) planTacticShare.getSObject('Parent').get('Account_Plan_vod__c'); 
            String pTacticId = (String) planTacticShare.get('ParentId');
            if (accountPlanId.equals(aPlanId) && planTacticId.equals(pTacticId)) {            
               // make an entry in account tactic share
               if (Schema.getGlobalDescribe().get('Account_Tactic_vod__Share') != null) {
                   String accountTacticId = accountTacticRecord.Id; 
                   accountTacticIds.add(accountTacticId); 
                   idShareMap.put(accountTacticId, planTacticShare);
                   //accountTacticIdTeamMemberMap.put(accountTacticId, actMemeber); 
                   // create share object for the account tactic
                   SObject accountTacticShareObj  = Schema.getGlobalDescribe().get('Account_Tactic_vod__Share').newSObject();            
                   accountTacticShareObj.put('UserOrGroupId', planTacticShare.get('UserOrGroupId')) ;
                   accountTacticShareObj.put('ParentId' , accountTacticId );
                   accountTacticShareObj.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
                   if (planTacticShare.get('AccessLevel') == 'Read') {
                       accountTacticShareObj.put('AccessLevel', 'Read');
                   } else if (planTacticShare.get('AccessLevel') == 'Edit') {
                       accountTacticShareObj.put('AccessLevel', 'Edit');
                   }                   
                   accountTacticShareObjects.add(accountTacticShareObj);         
               } 
            
            }    
        
          }        
     }
  
  
    // and call objective sharing
    // for the call objective sharing query the account tactic object and then include the sharing
    List<SObject> callObjectiveShareObjects = new List<SObject> ();
    List<SObject> callobjectives = Database.query('Select Id, Account_Plan_vod__c, Account_Tactic_vod__c from Call_Objective_vod__c where Account_Tactic_vod__c in :accountTacticIds');
    for (SObject callObjectiveRecord: callobjectives ) {
        String actTactic = (String) callObjectiveRecord.get('Account_Tactic_vod__c');
        String accountPlan = (String) callObjectiveRecord.get('Account_Plan_vod__c');
        if (actTactic == null || accountPlan == null) {
            continue;
        }
        for (Account_Tactic_vod__c  accountTacticRecord : Trigger.newMap.values()) {
            String aPlanId = accountTacticRecord.Account_Plan_vod__c;
            String aTactic = accountTacticRecord.Id;
            if (actTactic.equals(aTactic) && accountPlan.equals(aPlanId)) {
                if (Schema.getGlobalDescribe().get('Call_Objective_vod__Share') != null) {            
                    // create share object for the call objective 
                    SObject shareObj = idShareMap.get(actTactic);
                    String callObjectiveId = (String) callObjectiveRecord.get('Id');
                    SObject callObjectiveShareObj  = Schema.getGlobalDescribe().get('Call_Objective_vod__Share').newSObject();            
                    callObjectiveShareObj.put('UserOrGroupId', shareObj.get('UserOrGroupId')) ;
                    callObjectiveShareObj.put('ParentId' , callObjectiveId);
                    callObjectiveShareObj.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
                    if (shareObj.get('AccessLevel') == 'Read') {
                        callObjectiveShareObj.put('AccessLevel' , 'Read');
                    } else {
                        callObjectiveShareObj.put('AccessLevel' , 'Edit');
                    }          
                    callObjectiveShareObjects.add(callObjectiveShareObj);  
                }         
            }        
        }         
    }
    
    List<SObject> toUpsert = new List<SObject>();    
    
    toUpsert.addAll(accountTacticShareObjects);
    toUpsert.addAll(callObjectiveShareObjects);   
    
     if(!toUpsert.isEmpty())  {
       insert toUpsert;
     }             
  

}