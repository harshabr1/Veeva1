trigger Veeva_Analytics_Markets_Before_Delete_vod on Analytics_Markets_vod__c (before delete) {

    VOD_ERROR_MSG_BUNDLE bundle  = new VOD_ERROR_MSG_BUNDLE ();
     
    for (Analytics_File_Market_Map_vod__c afmm : [Select Id, Market_vod__c from Analytics_File_Market_Map_vod__c where Market_vod__c in :Trigger.old]) {
        if (afmm.Market_vod__c != null) {
            Analytics_Markets_vod__c errorObj  = Trigger.oldMap.get(afmm.Market_vod__c );
            if (errorObj != null) {
                errorObj.addError (bundle.getErrorMsg('NO_DEL_ANA_MARKET'), false);
            }
        }
    }

    
}