trigger VEEVA_DIRECTORY_BEFORE_INSERT_UPDATE on Directory_vod__c (before insert, before update) {

    if(Trigger.isInsert){
        // set Level_vod
        for (Integer i = 0; i <Trigger.new.size(); i++) {
            Directory_vod__c  dirNew = Trigger.new[i];
            String parentId = dirNew.Parent_Directory_vod__c;
            if(parentId == null || parentId.length() == 0){
                dirNew.Level_vod__c = 1;
            }else{
                Directory_vod__c parentDir = [SELECT Name,Level_vod__c FROM Directory_vod__c WHERE Id = :parentId];
                Decimal parentLevel = parentDir.Level_vod__c;
                dirNew.Level_vod__c = parentLevel + 1;
            }
        }
    }
    
    // check circular hirearchy structure and
    if(Trigger.isUpdate){
    	RecordType clmType = [select Name from RecordType where sobjecttype='Directory_vod__c' and developername='CLM_vod'];
        for (Integer i = 0; i <Trigger.new.size(); i++) {
            Directory_vod__c  dirUpdate = Trigger.new[i];
            Directory_vod__c dirOld = Trigger.old[i];
            Directory_vod__c oldParentDir = null;
            
            Id updatedParentId = dirUpdate.Parent_Directory_vod__c;
            Id oldParentId = dirOld.Parent_Directory_vod__c;
            Decimal oldLevel = dirOld.Level_vod__c;
            Decimal newLevel = 0;
            if(updatedParentId == null){
                newLevel = 1;
            }else if(updatedParentId != oldParentId){
                // find out current height
                
                // reparent
                Directory_vod__c newParentDir = [SELECT Name,Level_vod__c FROM Directory_vod__c WHERE Id = :updatedParentId];
                Decimal newParentLevel = newParentDir.Level_vod__c;
                
                // check new height after reparenting for CLM_vod type
                if(newParentLevel >= oldLevel && dirUpdate.RecordTypeId == clmType.Id){
                    Decimal maxLevel = dirUpdate.Level_vod__c;
                    Set<Id> toCheckIds = new Set<Id>();
                    toCheckIds.add(dirUpdate.Id);
                    while(maxLevel < 4 && toCheckIds.size()>0){
                        Map<Id, Directory_vod__c> subDirs = new Map<Id, Directory_vod__c>([select Id from Directory_vod__c where Parent_Directory_vod__c in :toCheckIds]);
                        toCheckIds.clear();
                        toCheckIds.addAll(subDirs.keySet());
                        if(toCheckIds.size()>0){
                            maxLevel++;
                        }
                    }
                    Decimal currentHeight = maxLevel - dirUpdate.Level_vod__c + 1;
                    
                    if((newParentLevel+currentHeight) > 4){
                        dirUpdate.addError(VOD_GET_ERROR_MSG.getErrorMsg('DIRECTORY_LEVEL_OVER_4', 'Directory'), false);
                        continue;
                    }
                }
                
                // check circular hirearchy
                if(newParentLevel > oldLevel){
                    Set<Id> toCheckIds = new Set<Id>();
                    toCheckIds.add(dirUpdate.Id);
                    for(Integer j = 0; j < newParentLevel - oldLevel; j++){
                        Map<Id, Directory_vod__c> subDirs = new Map<Id, Directory_vod__c>([select Id from Directory_vod__c where Parent_Directory_vod__c in :toCheckIds]);
                        toCheckIds.clear();
                        toCheckIds.addAll(subDirs.keySet());
                    }
                    
                    if(toCheckIds.contains(updatedParentId)){
                        // found a circular, report error
                        dirUpdate.addError(VOD_GET_ERROR_MSG.getErrorMsg('CIRCULAR_DIRECTORY_ERROR', 'Directory'), false);
                        continue;
                    }
                }
                
                newLevel = newParentLevel + 1;
            }
            else {
                oldParentDir = [SELECT Name,Level_vod__c FROM Directory_vod__c WHERE Id = :updatedParentId];
            }
            
            if(newLevel == 0){
                // level is not set by new parent
                newLevel = dirUpdate.Level_vod__c;
            }
            
            // level did change
            if(newLevel != oldLevel){
                // update level of this record and all its child directory
                dirUpdate.Level_vod__c = newLevel;
                
                // parent level should not equal the child level
                if (oldParentDir != null && oldParentDir.Level_vod__c >= dirUpdate.Level_vod__c) {
                    dirUpdate.addError(VOD_GET_ERROR_MSG.getErrorMsg('DIRECTORY_SAME_LEVEL_ERROR', 'Directory'), false);
                }
                
                // update children
                List<Directory_vod__c> subDirs = [select Id from Directory_vod__c where Parent_Directory_vod__c = :dirUpdate.Id];
                for(Directory_vod__c dir : subDirs){
                    dir.Level_vod__c = newLevel + 1;
                }
                
                update(subDirs);
                
            }
        }
    }
}