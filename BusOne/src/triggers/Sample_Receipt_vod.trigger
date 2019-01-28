trigger Sample_Receipt_vod on Sample_Receipt_vod__c (after update) {
    RecordType  recType  = [ Select Id from RecordType where SobjectType = 'Sample_Transaction_vod__c'  and  Name ='Receipt_vod' ];
    RecordType  recTypeSO  = [ Select Id from RecordType where SobjectType = 'Sample_Order_Transaction_vod__c'  and  Name ='Receipt_vod' ];
    
    List <Sample_Transaction_vod__c> transList = new    List <Sample_Transaction_vod__c> ();
    List <Sample_Transaction_vod__c> insTransList = new     List <Sample_Transaction_vod__c> ();
    
    List <Sample_Order_Transaction_vod__c> transSOList =  new  List <Sample_Order_Transaction_vod__c> ();
    List <Sample_Order_Transaction_vod__c> insTransSOList = new List <Sample_Order_Transaction_vod__c> ();
    
    List <Sample_Receipt_vod__c> recpList = new     List <Sample_Receipt_vod__c> ();
    List <Sample_Lot_vod__c> updSampLotList = new   List <Sample_Lot_vod__c> ();
    Set <Id> updSampLotSet = new   Set<Id> ();
    
    VOD_SAMPLE_RECEIPTS.setReceipt (true);  
    
    // access the product type relation ship
    Map<Id, Sample_Receipt_vod__c > srsMap 
                    = new Map<Id, Sample_Receipt_vod__c >([SELECT Id , Lot_vod__r.Name,
                                Lot_vod__r.Product_vod__c, Lot_vod__r.Sample_Lot_Id_vod__c ,
                                Lot_vod__r.Product_vod__r.Product_Type_vod__c 
                                FROM Sample_Receipt_vod__c WHERE Id IN :Trigger.New]);
  
    
    // add logic to update tag alerts
    Map<String, String> tagAlertItems = new Map<String, String> ();
    
    for (Integer i = 0; i < Trigger.new.size (); i++) {
        Sample_Receipt_vod__c sr = Trigger.new[i];        
        
        System.debug('entered the for loop of sample receipts');  
        System.debug('the value of confirmed quantity is   ' + sr.Confirmed_Quantity_vod__c);   
        System.debug('the value of received vod  is   ' + sr.Received_vod__c);        
        if (!sr.Received_vod__c) {
            continue;               
        } 
        
        // get the product type to determine whether to create or update sample transaction or sample order transaction
        Boolean isBRC = false;
        Sample_Receipt_vod__c  srForType = srsMap.get(Trigger.new[i].Id);
        system.debug(' before if condition product through  ' + srForType.Lot_vod__r.Product_vod__c);       
        system.debug(' before if condition value of ext id ' + srForType.Lot_vod__r.Sample_Lot_Id_vod__c);
        if (srForType.Lot_vod__r.Product_vod__c != null && 'No_Lot_vod'.equals(srForType.Lot_vod__r.Name)) {
            // check the type
            system.debug('inside the if loop sr.Lot_vod__r.Product_vod__c is not null ');
            system.debug(' value of product type: ' + srForType.Lot_vod__r.Product_vod__r.Product_Type_vod__c);
            String extId = srForType.Lot_vod__r.Sample_Lot_Id_vod__c;
            if('BRC'.equals(srForType.Lot_vod__r.Product_vod__r.Product_Type_vod__c)) {
                isBRC = true;
            }   
        }
        
        system.debug(' the product type of the receipt is ' + isBRC);
        
        if (!isBRC) {
            Sample_Transaction_vod__c updtran = 
                   new Sample_Transaction_vod__c (ID = sr.Ref_Transaction_Id_vod__c,
                                              Receipt_Comments_vod__c = sr.Receipt_Comments_vod__c,
                                              Received_vod__c = sr.Received_vod__c,
                                              Confirmed_Quantity_vod__c = sr.Confirmed_Quantity_vod__c);
                                              
            Sample_Transaction_vod__c insTran = new Sample_Transaction_vod__c ( 
                                                        RecordTypeId = recType.Id,
                                                        Comments_vod__c =   sr.Comments_vod__c, 
                                                        Confirmed_Quantity_vod__c   =   sr.Confirmed_Quantity_vod__c, 
                                                        Lot_Name_vod__c =   sr.Lot_Name_vod__c, 
                                                        Lot_vod__c  =   sr.Lot_vod__c, 
                                                        Quantity_vod__c =   sr.Quantity_vod__c, 
                                                        Receipt_Comments_vod__c =   sr.Receipt_Comments_vod__c, 
                                                        Sample_vod__c   =   sr.Sample_vod__c, 
                                                        Shipment_Id_vod__c  =   sr.Shipment_Id_vod__c, 
                                                        Status_vod__c = 'Submitted_vod',
                                                        Submitted_Date_vod__c = System.today(),
                                                        Transferred_Date_vod__c =   sr.Transferred_Date_vod__c, 
                                                        Transferred_From_Name_vod__c    =   sr.Transferred_From_Name_vod__c, 
                                                        Transferred_From_vod__c =   sr.Transferred_From_vod__c, 
                                                        U_M_vod__c  =   sr.U_M_vod__c );
                                                        
            if (insTran.Shipment_Id_vod__c != null) {
                insTran.Group_Transaction_Id_vod__c =  insTran.Shipment_Id_vod__c + '(RT)'; 
            }
            
            // for the sample transaction check the sample receipts values and stamp accordingly
            if (sr.Tag_Alert_Number_vod__c != null) {
                insTran.Tag_Alert_Number_vod__c  = sr.Tag_Alert_Number_vod__c;
            }
            
            if (sr.Cold_Chain_Status_vod__c != null) {
                insTran.Cold_Chain_Status_vod__c = sr.Cold_Chain_Status_vod__c;
            }
            
            if (sr.Custom_Text_vod__c!= null) {
                insTran.Custom_Text_vod__c = sr.Custom_Text_vod__c;
            }           
            
            
            // add the sample lot Ids in the set
            if(!updSampLotSet.contains(sr.Lot_vod__c)) {
                updSampLotSet.add(sr.Lot_vod__c);
                Sample_Lot_vod__c updSampLot = new Sample_Lot_vod__c ( Id = sr.Lot_vod__c,
                                                                    Active_vod__c = true);                                                                      
                updSampLotList.add(updSampLot);
                // if the sample receipt had the tag alert numer then add them
                if (sr.Tag_Alert_Number_vod__c != null) {
                    tagAlertItems.put(sr.Lot_vod__c, sr.Tag_Alert_Number_vod__c);                
                }
            }                                                   
                                                        
    
            if (sr.Ref_Transaction_Id_vod__c != null) {
                transList.add (updtran);
                insTran.Ref_Transaction_Id_vod__c   =   sr.Ref_Transaction_Id_vod__c;   
            }
            insTransList.add (insTran);
        
            recpList.add (sr);
        
        } else {
             Sample_Order_Transaction_vod__c updSOrdertran = 
                   new Sample_Order_Transaction_vod__c (ID = sr.Ref_Order_Transaction_Id_vod__c,
                                              Receipt_Comments_vod__c = sr.Receipt_Comments_vod__c,
                                              Received_vod__c = sr.Received_vod__c,
                                              Confirmed_Quantity_vod__c = sr.Confirmed_Quantity_vod__c);
                                              
             Sample_Order_Transaction_vod__c insSOrderTran = new Sample_Order_Transaction_vod__c ( 
                                                        RecordTypeId = recTypeSO.Id,
                                                        Comments_vod__c =   sr.Comments_vod__c, 
                                                        Confirmed_Quantity_vod__c   =   sr.Confirmed_Quantity_vod__c,                                                         
                                                        Lot_vod__c  =   sr.Lot_vod__c, 
                                                        Quantity_vod__c =   sr.Quantity_vod__c, 
                                                        Receipt_Comments_vod__c =   sr.Receipt_Comments_vod__c, 
                                                        Sample_vod__c   =   sr.Sample_vod__c, 
                                                        Shipment_Id_vod__c  =   sr.Shipment_Id_vod__c, 
                                                        Status_vod__c = 'Submitted_vod',
                                                        Submitted_Date_vod__c = System.today(),
                                                        Transferred_Date_vod__c =   sr.Transferred_Date_vod__c, 
                                                        Transferred_From_Name_vod__c    =   sr.Transferred_From_Name_vod__c, 
                                                        Transferred_From_vod__c =   sr.Transferred_From_vod__c, 
                                                        U_M_vod__c  =   sr.U_M_vod__c );
                                                        
             if (insSOrderTran.Shipment_Id_vod__c != null) {
                insSOrderTran.Group_Transaction_Id_vod__c =  insSOrderTran.Shipment_Id_vod__c + '(RT)'; 
             }  
             
             // for BRC stamp only the custom text
             if (sr.Custom_Text_vod__c!= null) {
                insSOrderTran.Custom_Text_vod__c = sr.Custom_Text_vod__c;
             } 
             
              // add the sample lot Ids in the set
             if(!updSampLotSet.contains(sr.Lot_vod__c)) {
                updSampLotSet.add(sr.Lot_vod__c);
                Sample_Lot_vod__c updSampLot = new Sample_Lot_vod__c ( Id = sr.Lot_vod__c,
                                                                    Active_vod__c = true);                                                                      
                updSampLotList.add(updSampLot);
             }
             
             if (sr.Ref_Transaction_Id_vod__c != null) {
                transSOList.add (updSOrdertran);
                insSOrderTran.Ref_Order_Transaction_Id_vod__c =   sr.Ref_Order_Transaction_Id_vod__c;   
             }
             
             insTransSOList.add (insSOrderTran);
        
             recpList.add (sr);      
        }     
    
    }
    
    System.debug(' after the for loop the list for sample received is   ' + recpList); 
    System.debug(' after the for loop the list for sample lot is    ' + updSampLotList.size ()); 
    System.debug(' after the for loop the list for update sample transaction is   ' + transList.size ()); 
    System.debug(' after the for loop the list for insert sample transaction is   ' + insTransList.size()); 
    
    
    Set<Id> sampleLotsId = new Set<Id> ();
    if (updSampLotList.size () > 0) {
        update updSampLotList;
        // here query the sample lots to upsert sample lot items accordingly
        
                
    }
     
    List <Sample_Lot_Item_vod__c> newLotItems = new List <Sample_Lot_Item_vod__c> ();
    if (updSampLotSet.size() > 0) {    
        for (Sample_Lot_vod__c sLot: [SELECT Id, Name, OwnerId, Sample_vod__c FROM Sample_Lot_vod__c WHERE Active_vod__c = true and Id IN :updSampLotSet]) {
             if (!tagAlertItems.containsKey(sLot.Id)) {
                      continue;
             }
             String tagAlertNumber = tagAlertItems.get(sLot.Id);
             String lotItemExternalId =  sLot.ownerId + '_' +  sLot.Sample_vod__c + '_' + sLot.Name + '_' + tagAlertNumber;
             Sample_Lot_Item_vod__c newLotItem =  new Sample_Lot_Item_vod__c (
                            Sample_Lot_vod__c =  sLot.Id,
                            Sample_Lot_Item_Id_vod__c = lotItemExternalId ,
                            Active_vod__c = true,
                            Tag_Alert_Number_vod__c = tagAlertNumber);
             newLotItems.add(newLotItem);                                   
        }
    }
    
    if (newLotItems.size ()> 0) {
        system.debug(' inside the size of the lot items  ' + newLotItems.size ());
        upsert newLotItems Sample_Lot_Item_Id_vod__c ;
        system.debug(' upsert successful for sample lot items');
    }
    
    if (transList.size () > 0) {
        update transList;
    }
     
    if (insTransList.size() > 0) {
        insert insTransList;
    }
    
    if (transSOList.size () > 0) {
        update transSOList;
    }
     
    if (insTransSOList.size() > 0) {
        insert insTransSOList;
    }
    
        
}