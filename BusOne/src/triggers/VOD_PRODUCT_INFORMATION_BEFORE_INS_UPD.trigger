trigger VOD_PRODUCT_INFORMATION_BEFORE_INS_UPD on Product_Information_vod__c (before insert, before update) {
    Map<String, Product_Information_vod__c> acctProdCombos = new Map<String, Product_Information_vod__c>();
    List<Id> accountIds = new List<Id>();
    List<Id> productIds = new List<Id>();
    for (Product_Information_vod__c prodInfo : Trigger.new) {
        accountIds.add(prodInfo.Account_vod__c);
        productIds.add(prodInfo.Product_vod__c);
        String combo = prodInfo.Account_vod__c + '' + prodInfo.Product_vod__c;
        acctProdCombos.put(combo, prodInfo);
    }
    
    String query = 'SELECT Account_vod__c, Product_vod__c ' + 
                   'FROM Product_Information_vod__c ' +
                   'WHERE Account_vod__c IN :accountIds ' + 
                   'AND Product_vod__c IN :productIds';
    if (Trigger.isUpdate) {
        Set<Id> idSet = Trigger.newMap.keySet();
        query += ' AND Id NOT IN :idSet';
    }
    
    List<Product_Information_vod__c> existingProdInfos = Database.query(query);
    for (Product_Information_vod__c existingInfo : existingProdInfos) {
        String existCombo = existingInfo.Account_vod__c + '' + existingInfo.Product_vod__c;
        Product_Information_vod__c newProdInfo = acctProdCombos.get(existCombo);
        if (newProdInfo != null) {
            newProdInfo.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('PRODUCT_INFO_DUP_RECORD_ERROR', 
                                        'ORDER_MANAGEMENT', 'A record with the same Account and Product combination already exists.'));
        }
    }
}