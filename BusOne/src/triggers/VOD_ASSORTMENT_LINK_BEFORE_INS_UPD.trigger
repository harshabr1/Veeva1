trigger VOD_ASSORTMENT_LINK_BEFORE_INS_UPD on Assortment_Link_vod__c (before insert, before update) {

    Map<String, Set<String>> assortmentsToCampaigns = new Map<String, Set<String>>();
    Map<String, Assortment_Link_vod__c> comboIdToLinks = new Map<String, Assortment_Link_vod__c>();
    for (Assortment_Link_vod__c link : Trigger.new) {
        if (link.Order_Campaign_vod__c == null) {
            link.addError(VOD_VEEVA_MESSAGE.getMsgWithDefault('PDA_DYNAMIC_CANNOT_BE_EMPTY', 'PDA', 'link cannot be empty'), true);
        } else {
            Set<String> campaigns = assortmentsToCampaigns.get(link.Assortment_vod__c);
            if (campaigns == null) {
                campaigns = new Set<String>();
                assortmentsToCampaigns.put(link.Assortment_vod__c, campaigns);
            }
            campaigns.add(link.Order_Campaign_vod__c);
            comboIdToLinks.put(link.Assortment_vod__c + '_' + link.Order_Campaign_vod__c, link);
        }
    }
    
    Set<Id> triggerLinkIds = new Set<Id>();
    if (Trigger.isUpdate) {
        triggerLinkIds = Trigger.newMap.keySet();
    }
    for (Assortment_Link_vod__c link : [SELECT Assortment_vod__c, Order_Campaign_vod__c 
                                        FROM Assortment_Link_vod__c
                                        WHERE Assortment_vod__c IN :assortmentsToCampaigns.keySet()
                                        AND Id NOT IN :triggerLinkIds]) {
        Set<String> campaigns = assortmentsToCampaigns.get(link.Assortment_vod__c);
        if (campaigns != null && campaigns.contains(link.Order_Campaign_vod__c)) {
            Assortment_Link_vod__c tLink = comboIdToLinks.get(link.Assortment_vod__c + '_' + link.Order_Campaign_vod__c);
            tLink.addError(VOD_VEEVA_MESSAGE.getMsgWithDefault('MIGRATION_STATUS_DUPLICATE_FOUND', 'CLM', 'Duplicate Assortments Found'), true);
        }                                    
    }                                       

}