public class VOD_ACCOUNT_TRIG{
        	static Boolean inAccountTrig = false;
        	static Map <Id,Account> accMap;
        	static List <Affiliation_vod__c> affList;
            public static Boolean accountMergeSampleLimit = false;

            public static void setDeleteMap (Map <Id,Account> pMap) {
            	accMap = pMap;
            	
            }
            
            public static Map <Id,Account> getDeleteMap () {
            	return accMap;
            }
            
            public static void setAffList (List <Affiliation_vod__c> pMap) {
            	affList = pMap;
            }
        		
        	public static List <Affiliation_vod__c> getAffList () {
        		return affList;
        	}
        		
        	public static void setAccountTrig (Boolean p_inAccountTrig) {
        		inAccountTrig = p_inAccountTrig;
        	}
        	
        
           public static Boolean getAccountTrig ()	{
           		return inAccountTrig;
           }
        }