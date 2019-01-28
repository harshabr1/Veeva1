trigger VOD_ACCOUNT_TO_TERRITORY_AFTER_TRIGGER on Account_Territory_Loader_vod__c (after insert,after update) {

     //  System.debug('VOD_ACCOUNT_TO_TERRITORY_AFTER_TRIGGER starts');
    
     for (Integer i = 0 ;  i < Trigger.new.size(); i++)  {
            //  System.debug('i: "' + i +'"');

        if(Trigger.isUpdate) {
          //  System.debug('Account_vod__c in After processing  "' + Trigger.old[i].Account_vod__c + '"');

          //  System.debug('Old Territory to Add After processing  "' + Trigger.old[i].Territory_To_Add_vod__c + '"');
          //  System.debug('Old Territory List After processing    "' + Trigger.old[i].Territory_vod__c + '"');
          //  System.debug('Old Territory to Drop After processing "' + Trigger.old[i].Territory_To_Drop_vod__c + '"');
        }
    
       //  System.debug('New Territory to Add After processing  "' + Trigger.new[i].Territory_To_Add_vod__c + '"');
       //  System.debug('New Territory List After processing    "' + Trigger.new[i].Territory_vod__c + '"');
       //  System.debug('New Territory to Drop After processing "' + Trigger.new[i].Territory_To_Drop_vod__c + '"');
     }

    Territory_Settings_vod__c territorySetting = Territory_Settings_vod__c.getInstance();
    Boolean extendATLMode = false;
    if (territorySetting != null) {
        if ((Integer)territorySetting.ATL_Mode_vod__c == 1) {
            extendATLMode = true;
        }
    }
    
    //  System.debug('extendATLMode= ' + extendATLMode);

    Set<Id> acctIds = new Set<Id> ();
    List<Account_Territory_Loader_vod__c> accountTerritoryLoaders = new List<Account_Territory_Loader_vod__c>();
    boolean useAsync = false;

    Account_Territory_Loader_vod__c accountTerritoryLoader;
    
    Set<String> territory_vods_before_changes = new Set<String>();
    Set<String> territory_vods_after_changes = new Set<String>();
	Set<String> territory_vods_add_existing_ters = new Set<String>();
    
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        if (Trigger.new[i].Account_vod__c == null)
            continue;

        acctIds.add(Trigger.new[i].Account_vod__c);

        // CRM-107448 - Patch fix to maintain v27 behavior to skip
        // CRM-107945 - Removed the extendATLMode check so following code will be executed for Territory_Settings_vod__c.ATL_Mode_vod__c = 0/1
        String terr_vod = Trigger.new[i].Territory_vod__c;
        if (!extendATLMode) {
        	if (terr_vod == null || terr_vod.length() == 0) {
           		continue;
        	}
        }

        accountTerritoryLoader = new Account_Territory_Loader_vod__c(
            Id = Trigger.new[i].Id,
            Account_vod__c = Trigger.new[i].Account_vod__c,
            Territory_To_Drop_vod__c = null,
            Territory_vod__c = Trigger.new[i].Territory_vod__c,
            Territory_To_Add_vod__c = null);

        territory_vods_before_changes.clear();
        territory_vods_after_changes.clear();
        territory_vods_add_existing_ters.clear();
        
        String[] territories_before = new String[]{};
            //  System.debug('new territories_before='+territories_before);

        if(extendATLMode) {
            if(Trigger.isUpdate && Trigger.old[i].Territory_vod__c != null) {
                territories_before = Trigger.old[i].Territory_vod__c.split(';');
            }
            
            //  System.debug('territories_before='+territories_before);
            for(Integer terrIdx = 0; terrIdx < territories_before.size(); terrIdx++) {
                if(territories_before[terrIdx] != null && territories_before[terrIdx].length() > 0) {
                    territory_vods_before_changes.add(territories_before[terrIdx]);
                }
            }
            //  System.debug('territory_vods_before_changes='+territory_vods_before_changes);

            String[] territories_after = Trigger.new[i].Territory_vod__c != null
                ? Trigger.new[i].Territory_vod__c .split(';') : new String[]{};
            //  System.debug('territories_after='+territories_after);
            for(Integer terrIdx = 0; terrIdx < territories_after.size(); terrIdx++) {
                if(territories_after[terrIdx] != null && territories_after[terrIdx].length() > 0) {
                    territory_vods_after_changes.add(territories_after[terrIdx]);
                }
            }
            //  System.debug('territory_vods_after_changes='+territory_vods_after_changes);

            Set<String> territory_drop_vod = new Set<String>();
            territory_drop_vod.addAll(territory_vods_before_changes);
            //  System.debug('territory_drop_vod='+territory_drop_vod);
            territory_drop_vod.removeAll(territory_vods_after_changes);
            //  System.debug('territory_drop_vod result='+territory_drop_vod);

            Set<String> territory_add_vod = new Set<String>();
            territory_add_vod.addAll(territory_vods_after_changes);
            //  System.debug('territory_add_vod='+territory_add_vod);
            territory_add_vod.removeAll(territory_vods_before_changes);
            //  System.debug('territory_add_vod result='+territory_add_vod);

            String existingTerToAdd = VOD_ACCOUNT_TO_TERRITORY_HEADER_CLASS.getExistingTerritories(Trigger.new[i].Id);
            System.debug('The existing Territory Value from header class:' + existingTerToAdd);
			
            if (String.isNotBlank(existingTerToAdd)) {
                String[] territories_AddExistingTer = existingTerToAdd .split(';');
                
           		 for(Integer terrIdx = 0; terrIdx < territories_AddExistingTer.size(); terrIdx++) {
               		 if(territories_AddExistingTer[terrIdx] != null && territories_AddExistingTer[terrIdx].length() > 0) {
                   		 territory_vods_add_existing_ters.add(territories_AddExistingTer[terrIdx]);
                	}
           		 }
                 territory_add_vod.addAll(territory_vods_add_existing_ters);               
            }
            String tmpTerritory;
            if(territory_drop_vod.size() > 0) {
                tmpTerritory = ';';
                for(String territory : territory_drop_vod) {
                    tmpTerritory += territory + ';';
                }
                //  System.debug('tmpTerritory for drop='+tmpTerritory);
                accountTerritoryLoader.Territory_To_Drop_vod__c = tmpTerritory;
                //  System.debug('accountTerritoryLoader.Territory_To_Drop_vod__c='+accountTerritoryLoader.Territory_To_Drop_vod__c);
            }
            
            if(territory_add_vod.size() > 0) {
                tmpTerritory = ';';
                for(String territory : territory_add_vod) {
                    tmpTerritory += territory + ';';
                }
                //  System.debug('tmpTerritory for add='+tmpTerritory);
                accountTerritoryLoader.Territory_To_Add_vod__c = tmpTerritory;
                //  System.debug('accountTerritoryLoader.Territory_To_Add_vod__c='+accountTerritoryLoader.Territory_To_Add_vod__c);
            }
            if (!useAsync) {
                if((territory_add_vod.size() + territory_drop_vod.size()) > 100)
                {
                    useAsync = true;
                }
            }  
        } else {
            // extendATLMode is false 
            if (!useAsync) {
                if(territory_vods_after_changes.size() > 100)
                {
                    useAsync = true;
                }
            }
        }
        
        accountTerritoryLoaders.add(accountTerritoryLoader);
        //  System.debug('New Territory to Add After 2nd processing  "' + accountTerritoryLoader.Territory_To_Add_vod__c + '"');
        //  System.debug('New Territory List After 2nd processing    "' + accountTerritoryLoader.Territory_vod__c + '"');
        //  System.debug('New Territory to Drop After 2nd processing "' + accountTerritoryLoader.Territory_To_Drop_vod__c + '"');
    }

    //  System.debug('acctIds='+acctIds);
    // clear the map in VOD_ACCOUNT_TO_TERRITORY_HEADER_CLASS class
	VOD_ACCOUNT_TO_TERRITORY_HEADER_CLASS.clearMap();
    // If we dont have any changes stop here and return;
    if (acctIds.size() == 0)
        return;
        
    if (!useAsync) {
        //  System.debug('Before VOD_EstNumOfDmlsForProcessATL.useAsyncProcessATL');
        //  System.debug('accountTerritoryLoaders:' + accountTerritoryLoaders);
        //  System.debug('acctIds:' + acctIds);
        //  System.debug('extendATLMode:' + extendATLMode);
        useAsync = VOD_EstNumOfDmlsForProcessATL.useAsyncProcessATL(accountTerritoryLoaders, acctIds, extendATLMode);
    }

    if (useAsync == false || system.isBatch() || system.isFuture()) {
        VOD_ProcessATL.processATL(accountTerritoryLoaders, acctIds, extendATLMode);
    }
    else {
        String xmldoc = VOD_ProcessATL_Asyn.write(accountTerritoryLoaders);
        VOD_ProcessATL_Asyn.processATL(xmldoc, acctIds, extendATLMode);
    }

    //  System.debug('VOD_ACCOUNT_TO_TERRITORY_AFTER_TRIGGER ends');
}