public class VOD_VEEVA_MESSAGE {

	private static final String DELIMETER = ';;';

	// TODO: Test me.
	
	public static Map<String, String> getVeevaMessages(List<String> keys) {
		String userLang = UserInfo.getLanguage();
		
		List<String> whereClauses = new List<String>();
		for (String key : keys) {
			String[] splitKey = key.split(DELIMETER, 2);
			
			String pCategory = splitKey[0];
			String pKey = splitKey[1];

			// We want "(Name = :pKey AND Language_vod__c = :userLang AND Category_vod__c = :pCategory
			// 			 AND Active_vod__c = true)			
			String whereClause = '(Name=' + pKey
					 + ' AND Language_vod__c=' + userLang
				 	 + ' AND Category_vod__c=' + pCategory
				 	  + ' AND Active_vod__c=true)';
				 	  
			whereClauses.add(whereClause);
		}
		
		
		List<Message_vod__c> messages = new List<Message_vod__c>();
		try {
			messages = Database.query('SELECT Category_vod__c, Name, Text_vod__c '  
					+ ' FROM Message_vod__c WHERE ' + String.join(whereClauses, ' OR ')); 
		} catch (System.QueryException ignored) {
		}
		
		Map<String, String> veevaMessages = new Map<String, String>();
		for (Message_vod__c messsage : messages) {
			//String pCategory = message.Category_vod__c;
			
			//veevaMessages.put(message.Category_vod__c + DELIMETER + message.Name, message.Text_vod__c);
		}
		
		return veevaMessages;
	}
	

    public static String getMsgWithDefault(String pKey, String pCategory, String defaultMessage) {
        String errorMessage = getMsg(pKey, pCategory);
        
        // Return the default if we can't find the message.
        if (String.isEmpty(errorMessage)) {
            return defaultMessage;
        }
        
        return errorMessage;
    }

    private static String getMsg(String pKey, String pCategory) {

        String userLang = UserInfo.getLanguage();
        Message_vod__c msg = null;
        try {
            msg = [Select Text_vod__c From Message_vod__c
                        WHERE NAME = :pKey
                        AND Language_vod__c = :userLang
                        AND Category_vod__c = :pCategory
                        AND Active_vod__c = true LIMIT 1];
        } catch (System.QueryException e) {
        }


        if (msg == null) {
        try {
            msg = [Select Text_vod__c From Message_vod__c
                        WHERE NAME = :pKey
                        AND Language_vod__c = 'en_US'
                        AND Category_vod__c = :pCategory
                        AND Active_vod__c = true LIMIT 1];
        }  catch (System.QueryException e) {
        }

        }
        String value ='';
        if (msg != null) {
            value = msg.Text_vod__c;
        }
        return value;

    }
}