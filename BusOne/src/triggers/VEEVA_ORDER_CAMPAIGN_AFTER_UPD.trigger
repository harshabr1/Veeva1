trigger VEEVA_ORDER_CAMPAIGN_AFTER_UPD on Order_Campaign_vod__c (after update) {
    try{
        VOD_ORDER_CAMPAIGN_TRIG.setCampaignTrig (true);
        for (Order_Campaign_vod__c oc : Trigger.new) {
            Order_Campaign_vod__c oldc = Trigger.oldMap.get(oc.Id);
            if(oc.Start_Date_vod__c != oldc.Start_Date_vod__c || oc.End_Date_vod__c != oldc.End_Date_vod__c){
                Pricing_Rule_vod__c[] pcs = [select Id, Start_Date_vod__c, End_Date_vod__c from Pricing_Rule_vod__c where Order_Campaign_vod__c = :oc.Id ];
                for (Pricing_Rule_vod__c p : pcs ) {
                    p.Start_Date_vod__c = oc.Start_Date_vod__c;
                    p.End_Date_vod__c = oc.End_Date_vod__c;
                }  
                update pcs;          
            }
        }
    } finally {
        VOD_ORDER_CAMPAIGN_TRIG.setCampaignTrig (false);
    }
}