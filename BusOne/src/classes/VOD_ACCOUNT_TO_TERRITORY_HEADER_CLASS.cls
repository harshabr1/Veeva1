/***************************************************************************************************
 * This class is used to hold Territory data ( Territory entries of Territory_Add_vod__c 
 *  which already exists in Territory_vod__c)
 * from VOD_ACCOUNT_TO_TERRITORY_BEFORE_TRIGGER to be used in VOD_ACCOUNT_TO_TERRITORY_AFTER_TRIGGER
 ***************************************************************************************************/
 
public class VOD_ACCOUNT_TO_TERRITORY_HEADER_CLASS {
    private static Map<String,String> existingTerritoriesByAtlId = new Map<String,String>();    
    
    public static void setExistingTerritories(String atlId, String territories) {        
        existingTerritoriesByAtlId.put(atlId,territories);
        // System.debug('Setting This Ter to the Header class:ATLID :' + atlId + 'Territories:' + territories);
    }

    public static String getExistingTerritories(String atlId) {        
        String terrString = existingTerritoriesByAtlId.get(atlId);
        // System.debug('Retrieved Ter from the Header class for atlId:' + atlId + '- Territory:' + terrString);
        if (String.isBlank(terrString))
	        	terrString ='';

        return terrString;
    }
    
    public static void clearMap() {
    	existingTerritoriesByAtlId.clear();
    }
   
}