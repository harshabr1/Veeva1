trigger VOD_BEFORE_INSUPD_TOT on Time_Off_Territory_vod__c (before update, before insert) {
            if(VEEVA_PROCESS_FLAGS.getUpdateTOT()== true){
               return;
            }
            List <Id> ownerList = new List<Id> ();
        
            for (Integer o = 0; o < Trigger.new.size(); o++) {
                ownerList.add(Trigger.new[o].OwnerId);      
            }
            Map <String, List <String>> mTerr = new Map <String, List <String>>();
        
            List <UserTerritory> userTerrs = [Select TerritoryId,UserId from UserTerritory where UserId in :ownerList];
        
            List<Id> ids = new List<Id> (); 
        
            for (Integer i = 0; i < userTerrs.size(); i++ ) {
                    ids.add(userTerrs[i].TerritoryId);
            }
            
            Map<Id, Territory> territoryMap = new Map <Id, Territory> ([Select Id,Name from Territory where Id in :ids]);
        
            for (Integer v = 0; v < userTerrs.size(); v++) {
                UserTerritory ut = userTerrs.get(v);
                String UserId = ut.UserId;
                String TerritoryId= ut.TerritoryId;
        
                List <String> sTerr = mTerr.get (UserId);
                
                if (sTerr == null) {
                   sTerr = new List <String> ();
                } 
                Territory terrFromMap = territoryMap.get(TerritoryId);
                 if (terrFromMap != null) {
                    sTerr.add(terrFromMap.Name);
                    mTerr .put(UserId,sTerr);
                 }
            }
        
            for (Integer l = 0; l < Trigger.new.size(); l++) {
        
                String ownerInRow = Trigger.new[l].OwnerId;
                List <String> thisSet = mTerr.get(ownerInRow);
                String terrString = ';';
        
                if (thisSet != null) {
                    for (String terrName : thisSet) {
                        terrString += terrName + ';';
                    }
                }
                Trigger.new[l].Territory_vod__c = terrString ;
                if(Trigger.new[l].Time_vod__c == 'Hourly'){
                    if(Trigger.new[l].Hours_off_vod__c == null)
                        Trigger.new[l].Hours_off_vod__c = '1';  
                    if(Trigger.new[l].Start_Time_vod__c == null)    
                        Trigger.new[l].Start_Time_vod__c = '8:00 AM';                 
                }
            }
        }