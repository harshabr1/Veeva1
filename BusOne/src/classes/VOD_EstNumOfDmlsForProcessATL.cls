public class VOD_EstNumOfDmlsForProcessATL {
    public static boolean useAsyncProcessATL(List<Account_Territory_Loader_vod__c> acctLoaders, Set<Id> acctIds, boolean isAlign) {
        System.debug (LoggingLevel.ERROR,acctIds);

        Integer numOfShares = 0;
        Integer maxNumOfAccounts = acctLoaders.size();
        Integer maxNumOfTerritoryPerAccount = 0;

        for (Account_Territory_Loader_vod__c loader: acctLoaders) {
            String terr_vod = loader.Territory_vod__c;
            String terr_add_vod = loader.Territory_To_Add_vod__c;
            String terr_drop_vod = loader.Territory_To_Drop_vod__c;
            Integer numOfTerritories = 0;
            if (isAlign) {
                if ((terr_add_vod == null || terr_add_vod.length() == 0) &&
                    (terr_drop_vod == null || terr_drop_vod.length() == 0)) {
                    continue;
                }
                if (terr_add_vod != null) {
                    numOfTerritories += terr_add_vod.split(';').size();
                }
                if (terr_drop_vod != null) {
                    numOfTerritories += terr_drop_vod.split(';').size();
                }
            } else {
                if (terr_vod == null || terr_vod.length() == 0) {
                    continue;
                }
                numOfTerritories = terr_vod.split(';').size();
            }
            // determine the max number of territories
            if (numOfTerritories  > maxNumOfTerritoryPerAccount)
                maxNumOfTerritoryPerAccount = numOfTerritories;
        }
        
        System.debug (LoggingLevel.ERROR,'maxNumOfTerritoryPerAccount  = ' + maxNumOfTerritoryPerAccount);
        System.debug (LoggingLevel.ERROR,'maxNumOfAccounts = ' + maxNumOfAccounts);
        
        List<AccountShare> shares =  [SELECT Id From AccountShare WHERE AccountId in :acctIds AND RowCause  = 'TerritoryManual'];
        numOfShares = shares.size();
        System.debug (LoggingLevel.ERROR,'Set numOfShares as:' + numOfShares);
        Integer maxNumOfDmls  = maxNumOfAccounts * maxNumOfTerritoryPerAccount + numOfShares;
        System.debug (LoggingLevel.ERROR,'maxNumOfDmls= ' + maxNumOfDmls);

        Boolean useAsync = false;
        if (maxNumOfDmls > 10000) {
             useAsync = true;
        }
        System.debug (LoggingLevel.ERROR,'Set useAsync as:' + useAsync);

        return useAsync;
    }
    
}