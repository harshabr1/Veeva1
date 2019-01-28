global class VOD_AccountAuthorizationWrapper implements Comparable {
    public Account_Authorization_vod__c aaObj;
    public boolean modified;
    public VOD_AccountAuthorizationWrapper (Account_Authorization_vod__c aa, boolean isModified) {
        aaObj = aa;
        modified = isModified;
    }
    
    global Integer compareTo(Object compareTo) {
        VOD_AccountAuthorizationWrapper compareToAA = (VOD_AccountAuthorizationWrapper)compareTo;
        Integer returnValue = 0;
        if (aaObj.Collaborative_Relation_Start_Date_vod__c < compareToAA.aaObj.Collaborative_Relation_Start_Date_vod__c) {
            returnValue = -1;
        }
        else if (aaObj.Collaborative_Relation_Start_Date_vod__c > compareToAA.aaObj.Collaborative_Relation_Start_Date_vod__c) {
            returnValue = 1;
        }
        return returnValue;
    }
}