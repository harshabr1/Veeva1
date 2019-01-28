trigger VOD_SAMPLE_ORDER_TRANSACTION_AFTER_INSERT on Sample_Order_Transaction_vod__c (after insert) {

    RecordType [] recType  = VOD_SAMPLE_ORDER_TRANSACTION.recType;
    
     String tranRecordId = null; 
        
     for (Integer k = 0; k < recType.size (); k++) {
         if (recType[k].Name == 'Transfer_vod') {
             tranRecordId = recType[k].Id;
         }   
     } 
            
     List <String> ids = new List <String> ();
     List <String> oids = new List <String> ();
            
             
     for (Integer j = 0; j < Trigger.new.size (); j++) {
         if (Trigger.new[j].RecordTypeId == tranRecordId) {
             ids.add (Trigger.new[j].Lot_vod__c);    
             oids.add(Trigger.new[j].Id);
         }
     }
            
     Map <Id, Sample_Lot_vod__c > lots = null;
     if (ids.size () > 0)  {         
         lots = new Map <Id, Sample_Lot_vod__c> 
                ([Select  Active_vod__c, Expiration_Date_vod__c, Name, Sample_Lot_Id_vod__c, Suppress_Lot_vod__c, Sample_vod__c, Product_vod__c, Product_vod__r.Product_Type_vod__c, U_M_vod__c
                from Sample_Lot_vod__c  where Id in :ids]);
     } else {
         lots = new Map <Id, Sample_Lot_vod__c> ();
     }                        
            
     List <Sample_Lot_vod__c> newLots = new List <Sample_Lot_vod__c> ();
     String label  = System.label.USE_MULTI_SAMPLE_vod;             
     Boolean bUseSamp = false;  
     if (label != null && label != 'false') {
         bUseSamp = true;
     }
     
     for (Integer l = 0; l < ids.size (); l++ ) {
         Sample_Lot_vod__c sl = lots.get (ids[l]);
         Sample_Order_Transaction_vod__c stv = Trigger.newMap.get(oids[l]);
         
         String upsertId  = stv.Transfer_To_vod__c;
         if (bUseSamp) {
             upsertId +='_';
             upsertId +=sl.Sample_vod__c.replaceAll(' ', '_');
         }                   
         
         upsertId  +='_';
         upsertId  +=sl.Name;
         
         // get the product type into the upsert id when it comes to No_Lot_vod upsert
         if ('No_Lot_vod'.equals(sl.Name)) {
                    system.debug('the value of the name of sample lot is  inside the if loop' + sl.Name);
                    system.debug(' the value of product type is  ' + sl.Product_vod__r.Product_Type_vod__c);
                    upsertId  +='_';
                    upsertId  += sl.Product_vod__r.Product_Type_vod__c;     
                    system.debug('in the loop upsert id is  ' +  upsertId);          
         }
                
         Sample_Lot_vod__c newLot =  new Sample_Lot_vod__c (
                                     Expiration_Date_vod__c = sl.Expiration_Date_vod__c, 
                                     Name = sl.Name, 
                                     Sample_vod__c = sl.Sample_vod__c, 
                                     Suppress_Lot_vod__c = sl.Suppress_Lot_vod__c, 
                                     Product_vod__c = sl.Product_vod__c, 
                                     U_M_vod__c  = sl.U_M_vod__c,
                                     Sample_Lot_Id_vod__c = upsertId,
                                     OwnerId  = stv.Transfer_To_vod__c );
                    
         if (VOD_SAMPLE_RECEIPTS.ENABLE_RECEIPT_ACTIVATION() != true)
             newLot.Active_vod__c = true; 
             newLots.add (newLot);
         }
         
         if (newLots.size ()> 0)
             upsert newLots Sample_Lot_Id_vod__c;
                         
         List <Sample_Receipt_vod__c > addTrans = new    List <Sample_Receipt_vod__c > ();
         Map <Id, Sample_Order_Transaction_vod__c> trans = null;
         for (Integer i = 0; i < Trigger.new.size (); i++) {
             Sample_Order_Transaction_vod__c st =  Trigger.new[i]; 
             if (st.RecordTypeId == tranRecordId) {
                 if (trans == null) { 
                     trans =   new Map <Id, Sample_Order_Transaction_vod__c> 
                               ([Select Transferred_From_vod__r.Name
                                from Sample_Order_Transaction_vod__c where Id in :Trigger.new]);
                 }
                    
                 Sample_Order_Transaction_vod__c fetchName = trans.get(st.Id);
            
                 Sample_Receipt_vod__c  sr = new Sample_Receipt_vod__c ( Comments_vod__c = st.Comments_vod__c, 
                                             Quantity_vod__c = st.Quantity_vod__c,  
                                             Ref_Order_Transaction_Id_vod__c = st.Id,                                            
                                             Sample_vod__c = st.Sample_vod__c, 
                                             Shipment_Id_vod__c = st.Shipment_Id_vod__c != null ? st.Shipment_Id_vod__c : 
                                             (st.Group_Transaction_Id_vod__c != null ? st.Group_Transaction_Id_vod__c : st.Name),
                                             Transferred_Date_vod__c = st.Transferred_Date_vod__c, 
                                             Transferred_From_vod__c = st.Transferred_From_vod__c, 
                                             Transferred_From_Name_vod__c = fetchName.Transferred_From_vod__r.Name,
                                             U_M_vod__c = st.U_M_vod__c);
                                             
                // add the cuastom text only
                if (st.Custom_Text_vod__c != null) {
                    sr.Custom_Text_vod__c  = st.Custom_Text_vod__c;                
                }
                // no tag alert or cold chain for BRC
                sr.Tag_Alert_Number_vod__c = null;
                sr.Cold_chain_Status_vod__c = null;
                
                                                    
                                                     
               for (Integer li = 0; li < newLots.size(); li++) {
                        
                   Sample_Lot_vod__c lookLots = lots.get (st.Lot_vod__c);
                         
                   String getLot  = st.Transfer_To_vod__c;
                   if (bUseSamp) {
                       getLot  +='_';
                       getLot += lookLots.Sample_vod__c.replaceAll(' ', '_');
                   }
                   getLot  +='_';
                   getLot  +=lookLots.Name;
                   
                   // add the product type to the external id for the no lot vods
                   if ('No_Lot_vod'.equals(lookLots.Name)) {
                        system.debug('the value of the name of sample lot is  inside the if loop' + lookLots.Name);
                        system.debug(' the value of product type is  ' + lookLots.Product_vod__r.Product_Type_vod__c);
                        getLot  +='_';
                        getLot  += lookLots.Product_vod__r.Product_Type_vod__c;     
                        system.debug('in the loop getLot value is  ' +  getLot);          
                   }
                   if (newLots[li].Sample_Lot_Id_vod__c == getLot )  {
                       sr.Lot_vod__c = newLots[li].Id;
                       sr.Lot_Name_vod__c = newLots[li].Name;
                       break;
                   }
               } 
               addTrans.add (sr);
           }
      }
      
      if (addTrans.size () > 0)
          insert addTrans;       
           

}