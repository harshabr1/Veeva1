trigger VOD_SAMPLE_LOT_ITEM_BEFORE_UPSERT on Sample_Lot_Item_vod__c (before insert, before update) {

    // for all the sample lot item name get the product name through sample lot
    Set<Id> sampleLotIds = new Set<Id> ();
    for (Integer i = 0; i <Trigger.new.size(); i++) {
        // here get the items needed  
        sampleLotIds.add(Trigger.new[i].Sample_Lot_vod__c);        
    }
    
    // for each sample lot get the owner id and product name
    Map<Id, String> sampleLotProductNamesMap = new Map<Id, String> ();
    Map<Id, String> sampleLotOwnerIDMap = new Map<Id, String> ();
    Map<Id, String> sampleLotIdNameMap = new Map<Id, String> ();
    
    for(Sample_Lot_vod__c  sLot: [SELECT Id, Name, Sample_vod__c, OwnerId FROM Sample_Lot_vod__c  where Id IN : sampleLotIds]){
        sampleLotProductNamesMap.put(sLot.Id, sLot.Sample_vod__c);
        sampleLotOwnerIDMap.put(sLot.Id, sLot.OwnerId);
        sampleLotIdNameMap.put(sLot.Id, sLot.Name);    
    }
    
    // now update the external id
    for (Integer i = 0; i <Trigger.new.size(); i++) {
        Sample_Lot_Item_vod__c sLItem = Trigger.new[i];
        String ownerId = sampleLotOwnerIDMap.get(sLItem.Sample_Lot_vod__c);
        String prodName = sampleLotProductNamesMap.get(sLItem.Sample_Lot_vod__c);
        String sampleLotName = sampleLotIdNameMap.get(sLItem.Sample_Lot_vod__c);
        String externalId =  ownerId + '_' +  prodName + '_' + sampleLotName + '_' + sLItem.Tag_Alert_Number_vod__c;
        System.debug(' the value of external id is ' +  externalId);
        sLItem.Sample_Lot_Item_Id_vod__c = externalId;    
    }
    

}