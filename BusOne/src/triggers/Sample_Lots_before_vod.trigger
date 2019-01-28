trigger Sample_Lots_before_vod on Sample_Lot_vod__c (before delete, before insert, before update) {
            
        // becuase we are using the new product look up irrespective of insert or update get the product look ups.
        
        // get the product ids so we can look up the product name
        List<String> productIds = new List<String> ();
        Set<String> productTypes = new Set<String> ();
        String errorMsg = VOD_GET_ERROR_MSG.getErrorMsg('NO_CREATE_NO_LOT_VOD','TriggerError');
        Map<Id, Product_vod__c> productsMap = new Map<Id, Product_vod__c> (); 
        
        if (Trigger.isUpdate || Trigger.isInsert) {
            For (Sample_Lot_vod__c sampleLot : Trigger.new) {        
                productIds.add(sampleLot.Product_vod__c);           
            }
            
            // now query the product catalog table to get the name and the product types of the prodcuts in lot catalog
            productsMap = new Map<Id, Product_vod__c> ([SELECT Id, Name, Product_Type_vod__c FROM Product_vod__c 
                                                                     WHERE Id IN:productIds]); 
            // check all the types in the veeva settings    
            Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
        
            if (vsc != null && vsc.Sample_Management_Product_Types_vod__c != null) {
                List<String> productTypesTemp = vsc.Sample_Management_Product_Types_vod__c.Split(';;');
                productTypes.addAll(productTypesTemp);
            }
        
        }
         
        
        if (Trigger.isDelete) {
            Map <Id, Sample_Lot_vod__c>  sampLots = 
                new Map<Id, Sample_Lot_vod__c>  ([SELECT Id, 
                    (Select Id from Sample_Transaction_vod__r) 
                        FROM 
                        Sample_Lot_vod__c where Id in : Trigger.old]);
                                                                                                
            for (Integer i = 0; i < Trigger.old.size (); i++) {         
                Sample_Lot_vod__c  thisLot = sampLots.get (Trigger.old[i].Id);          
                Boolean found = false;
                for (Sample_Transaction_vod__c sampTran : thisLot.Sample_Transaction_vod__r) {
                    found = true;
                    break;
                }
                if ( found == true ) 
                    Trigger.old[i].Id.addError (VOD_GET_ERROR_MSG.getErrorMsg('NO_DEL_SAMPLOT_W_TRAN','TriggerError'), false);
            }                                 
        }       
        else if (Trigger.isUpdate) 
        {               
            VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();               
            for (Integer i  = 0; i < Trigger.new.size(); i++) {
                if (Trigger.new[i].Name != Trigger.old[i].Name) {
                            Trigger.new[i].Name.addError (bundle.getErrorMsg('NO_UPDATE_FIELD'), false);
                }
                if (Trigger.new[i].OwnerId != Trigger.old[i].OwnerId) {
                    Trigger.new[i].OwnerId.addError (bundle.getErrorMsg('NO_UPDATE_FIELD'), false);
                }
                if (Trigger.new[i].Sample_vod__c != Trigger.old[i].Sample_vod__c) {
                    Trigger.new[i].Sample_vod__c = Trigger.old[i].Sample_vod__c;
                }
                
                if (Trigger.new[i].Product_vod__c != Trigger.old[i].Product_vod__c) {
                    Trigger.new[i].Product_vod__c = Trigger.old[i].Product_vod__c;
                    // also if the product has changed update the sample
                    if (productsMap.get(Trigger.new[i].Product_vod__c) != null) {
                        Product_vod__c prod = productsMap.get(Trigger.new[i].Product_vod__c);
                        Trigger.new[i].Sample_vod__c = prod.Name;  
                    }
                   
                }
                
                if (Trigger.new[i].Sample_Lot_Id_vod__c != Trigger.old[i].Sample_Lot_Id_vod__c) {
                    Trigger.new[i].Sample_Lot_Id_vod__c.addError (bundle.getErrorMsg('NO_UPDATE_FIELD'), false);
                }       
            } 
        } 
        else // Insert
        {  
            String label  = System.label.USE_MULTI_SAMPLE_vod;             
            Boolean bUseSamp = false;  
            if (label != null && label != 'false') {
                bUseSamp = true;
            }
            
            // now for the insert condition check the supress lot vod to see if virtual inventory is set or not
            String productType = '';
            String productName = ''; 
            
            for (Sample_Lot_vod__c sampleLot : Trigger.new) {
            
                // check if the product lok up has value if yes then get the product name and the product type
                if ((sampleLot.Product_vod__c != null) && (productsMap.get(sampleLot.Product_vod__c) != null )) { 
                    Product_vod__c prod = productsMap.get(sampleLot.Product_vod__c);               
                    productName = prod.Name;
                    productType = prod.Product_type_vod__c;               
                }                                 
                String ownerid = sampleLot.OwnerId;
                String name = sampleLot.Name; 
                // now check if the supress lot vod is true
                if (sampleLot.Suppress_Lot_vod__c == true && sampleLot.Product_vod__c != null) {
                     if (productTypes.contains(productType)) {
                         sampleLot.Sample_vod__c = productName;                
                         sampleLot.Sample_Lot_Id_vod__c = ownerid + '_' + productName.replaceAll(' ', '_') + '_' + name + '_' + productType;            
                     } else { // error out trying to create No_Lot_vod for the product not listed
                          sampleLot.addError(errorMsg, false);
                     }                
                } else {
                    if (bUseSamp) {
                        // now check if sample or product was used for regular sample
                        if (sampleLot.Sample_vod__c != null) { 
                            sampleLot.Sample_Lot_Id_vod__c =  ownerid + '_' + sampleLot.Sample_vod__c.replaceAll(' ', '_') + '_' + name; 
                        } else {
                            sampleLot.Sample_Lot_Id_vod__c = ownerid + '_' + productName.replaceAll(' ', '_') + '_' + name; 
                            sampleLot.Sample_vod__c = productName;
                        }        
                        
                     } else {
                         sampleLot.Sample_Lot_Id_vod__c = ownerid + '_' + name; 
                     }               
               }             
           }           
        }                            
    }