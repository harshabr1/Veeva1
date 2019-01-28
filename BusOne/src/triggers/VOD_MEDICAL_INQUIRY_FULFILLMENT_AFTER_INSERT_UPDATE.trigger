trigger VOD_MEDICAL_INQUIRY_FULFILLMENT_AFTER_INSERT_UPDATE on Medical_Inquiry_Fulfillment_vod__c (after insert, after update) {
    
    Set<Id> MIFIds = new Set<Id>();
    Map<Id, String> updateStatusMap = new Map<Id, String>();
    Map<Id, String> updateUserMap = new Map<Id, String>();
    List<Medical_Inquiry_Fulfillment_vod__c> updMIFList = new List<Medical_Inquiry_Fulfillment_vod__c> ();
    
    if (Trigger.isUpdate) {
        for(Medical_Inquiry_Fulfillment_vod__c  newMIF: Trigger.new) {
            Medical_Inquiry_Fulfillment_vod__c oldMIF = Trigger.oldMap.get(newMIF.Id);
            // if status is changed update the medical inquiry status
            if(oldMIF.Status_vod__c != newMIF.Status_vod__c ) {
                MIFIds.add(oldMIF.Medical_Inquiry_vod__c); 
                updateStatusMap.put(oldMIF.Medical_Inquiry_vod__c, newMIF.Status_vod__c);       
            }
            Medical_Inquiry_Fulfillment_vod__c updMIF = null; 
            if(oldMIF.Assigned_To_vod__c != newMIF.Assigned_To_vod__c) {             
                updMIF = new Medical_Inquiry_Fulfillment_vod__c();
                updMIF.Id = newMIF.Id;
                updMIF.Status_vod__c = 'Assigned_vod';   
                updMIF.Assigned_To_vod__c  = newMIF.Assigned_To_vod__c;
                updMIF.OwnerId = newMIF.Assigned_To_vod__c;                   
            }
            if(oldMIF.OwnerId != newMIF.OwnerId) {
                if (updMIF == null) {
                    updMIF = new Medical_Inquiry_Fulfillment_vod__c();
                }             
                updMIF.Id = newMIF.Id;
                updMIF.Status_vod__c = 'Assigned_vod';   
                updMIF.Assigned_To_vod__c  = newMIF.OwnerId;
                updMIF.OwnerId = newMIF.OwnerId;  
                //updMIFList.add(updMIF);         
            }
            if (updMIF != null) { 
                updMIFList.add(updMIF); 
            }        
         }
         // update the MIF records
         if (updMIFList.size() > 0) {
             update updMIFList;     
         }
     } else { // if this is insert lets just update the fulfillment status of medical inquiry
         for(Medical_Inquiry_Fulfillment_vod__c  newMIF: Trigger.new) {
             updateStatusMap.put(newMIF.Medical_Inquiry_vod__c, newMIF.Status_vod__c); 
             MIFIds.add(newMIF.Medical_Inquiry_vod__c);       
         } 
     }
     
     
          
     // now get the medical inquiry related to the MIF records
     List<Medical_Inquiry_vod__c> medInqRecords = new List<Medical_Inquiry_vod__c>([SELECT Id, Fulfillment_Status_vod__c, Fulfillment_Created_vod__c FROM Medical_Inquiry_vod__c WHERE Id IN :MIFIds]);
     if (!medInqRecords.isEmpty()) {
         for (Medical_Inquiry_vod__c record : medInqRecords) {
             record.Override_Lock_vod__c = true;
             record.Fulfillment_Status_vod__c = updateStatusMap.get(record.Id);
             record.Fulfillment_Created_vod__c = true;
         }
         update medInqRecords;
     }  
     
    

}