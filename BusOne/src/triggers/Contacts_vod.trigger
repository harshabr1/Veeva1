trigger Contacts_vod on Contact bulk (before delete,after delete) {
        List<String> idList =  new List<String> ();
    Map <Id,Contact> accMap =  null;
    Set<Id> affilList = new Set<Id> ();
    
                
    if (Trigger.isBefore) {
            accMap = new Map <Id,Contact> ([Select Id, (Select Id from  Call2_vod__r),
                                           (Select Id from  Affiliation_vod__r) 
                                       from Contact where ID in :Trigger.old]);
                if (accMap == null)
                accMap = new Map <Id,Contact> ();
                VEEVA_Contact_vod.contactMap = accMap;
                                
        } else {
            accMap = VEEVA_Contact_vod.contactMap;
                for (Integer k =0; k < Trigger.old.size(); k++) {
                        Contact con = accMap.get(Trigger.old[k].Id);
                        if (Trigger.old[k].MasterRecordId != null) {
                                if (con != null) {
                                        for (Affiliation_vod__c afil : con.Affiliation_vod__r) {
                                                affilList.add(afil.Id);
                                        } 
                                }               
                                continue;
                        }
                        
                        String id = Trigger.old[k].Id;
                idList.add (id);
                Integer i = 0;
                if (con != null)
                        for (Call2_vod__c call : con.Call2_vod__r) {
                                i=1;
                                break;
                                }
                                if ( i == 1){
                                       Trigger.old[k].Id.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_DEL_CONTACT','TriggerError'), false);
                                }
                        }
            
            // condition check here to reduce the number of @future method invocation
            if ('false'.equalsIgnorecase (System.Label.DISABLE_VEEVA_MERGE_vod) && affilList.size() > 0 )
                VEEVA_Merge.ProcessAccountMerge(null, null,affilList, null, null);
                               
            for (Affiliation_vod__c [] toDelete : [Select Id from Affiliation_vod__c where To_Contact_vod__c in :idList ])
                delete toDelete;
    }
        
}