trigger VOD_SAMPLE_ORDER_TRANSACTION_AFTER_INSERT_UPDATE on Sample_Order_Transaction_vod__c (after insert, after update) {

     Set<String> sOrderIds = new Set<String> ();
     Set<String> lotIds = new Set<String> ();
     for (Integer j = 0; j < Trigger.new.size (); j++) {
         sOrderIds.add(Trigger.new[j].Id); 
         if (Trigger.new[j].Lot_vod__c != null) {   
             lotIds.add(Trigger.new[j].Lot_vod__c); 
         }    
     }     
     
     Map<String, Double> lotAllocationQuantityMap = new Map<String, Double> ();
     List<Sample_Lot_vod__c > updateSampleLots = new List<Sample_Lot_vod__c > ();
     for (Integer j = 0; j < Trigger.new.size (); j++) {
         // for all sample order transactions find the allocated quantity         
         if (Trigger.new[j].Lot_vod__c != null) {
             Double allocationQuantity = 0;
             for(String lotId: lotIds) {
                 if (Trigger.new[j].Lot_vod__c.equals(lotId)) {
                     // check if the entry exists
                     //Set<String> lotIdSet = 
                     allocationQuantity = Trigger.new[j].Allocation_Impact_Quantity_vod__c;
                     if (lotAllocationQuantityMap.containsKey(lotId)) {
                        allocationQuantity += lotAllocationQuantityMap.get(lotId); 
                        lotAllocationQuantityMap.put(lotId, allocationQuantity);
                     } else { // first time entry
                         lotAllocationQuantityMap.put(lotId, allocationQuantity);
                     }
                 }
              }         
         }     
     }
     
     // now merely update the sample lots
     // now fetch the sample lots for the sample order ids
     
     if (lotIds.size () > 0)  {         
         List<Sample_Lot_vod__c> sampleLots = new List<Sample_Lot_vod__c> 
                ([Select Id, Name, Allocated_Quantity_vod__c from Sample_Lot_vod__c  where Id in :lotIds]);
                
         if (lotAllocationQuantityMap.size() > 0 && sampleLots.size() > 0 ) {
             for(Sample_Lot_vod__c sampleLot: sampleLots) {
                 if (lotAllocationQuantityMap.containsKey(sampleLot.Id)) {
                     if (sampleLot.Allocated_Quantity_vod__c == null) {
                         sampleLot.Allocated_Quantity_vod__c = 0;
                     }
                     sampleLot.Allocated_Quantity_vod__c += lotAllocationQuantityMap.get(sampleLot.Id);
                     system.debug(' the value of allocated quantity is ' + lotAllocationQuantityMap.get(sampleLot.Id));
                     updateSampleLots.add(sampleLot);
                 }              
             }     
         }
     } 
     
     // now update sample lots if any
     if (updateSampleLots.size() > 0 ) {
         system.debug('inside the update from sample order transaction updating sample lots' + updateSampleLots);
         update updateSampleLots;
     }

     
     


}