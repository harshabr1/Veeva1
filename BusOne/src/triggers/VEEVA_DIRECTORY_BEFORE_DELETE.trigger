trigger VEEVA_DIRECTORY_BEFORE_DELETE on Directory_vod__c (before delete) {
    
    for (Integer i = 0; i <Trigger.old.size(); i++) {
        Directory_vod__c deletingDir = Trigger.old[i];
        Id toDeleteId = deletingDir.Id;
        boolean selfReferred = deletingDir.Id == deletingDir.Parent_Directory_vod__c;
        
        // if it's referred
        List<Directory_vod__c> subDirs = [select Id from Directory_vod__c where Parent_Directory_vod__c = :toDeleteId];
        if(subDirs != null && subDirs.size() > 0){
            // error and stop the delete
            if(subDirs.size() != 1 || !selfReferred){ 
                deletingDir.addError(VOD_GET_ERROR_MSG.getErrorMsg('DELETE_DIRECTORY_ERROR', 'Directory'));
            }
        }
    }
}