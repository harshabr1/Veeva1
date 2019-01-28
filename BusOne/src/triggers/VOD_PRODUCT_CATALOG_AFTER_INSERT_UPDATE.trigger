trigger VOD_PRODUCT_CATALOG_AFTER_INSERT_UPDATE on Product_vod__c (after insert, after update) {

    // get the product types in the veeva setting
    Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
    Set<String> productTypes = new Set<String> ();
    if (vsc != null && vsc.Sample_Management_Product_Types_vod__c != null) {
       List<String> productTypesTemp = vsc.Sample_Management_Product_Types_vod__c.Split(';;');
       productTypes.addAll(productTypesTemp);
    }  
    List<String> productIds = new List<String> ();
    for (Product_vod__c prod: Trigger.new)  {
        // check if lot catalog need to be created
        productIds .add(prod.Id);        
    }
    
    // now for the product ids and the allowed produuct types check if No_Lot_vod exists already
    List<Lot_Catalog_vod__c> lotCatalogs = new List<Lot_Catalog_vod__c> ([SELECT Id, Name, Product_vod__c FROM Lot_Catalog_vod__c 
                                                                     WHERE Name = 'No_Lot_vod' AND Product_vod__c IN:productIds ]); 
    
    Set<String> productIdsForLot = new Set<String> ();
    
    for(Lot_Catalog_vod__c lot: lotCatalogs) {
        productIdsForLot.add(lot.Product_vod__c);
    }
    
    List<Lot_Catalog_vod__c> insertLotCatalogs = new List<Lot_Catalog_vod__c> ();
    // now for the products inserted or updated check the flag
    for (Product_vod__c prod: Trigger.new) {
        if (prod.Create_Lot_Catalog_vod__c == true) {
            // now if the No_Lot does not exists already and if the type is allowed then created one 
            Boolean doesLotExists = productIdsForLot.contains(prod.Id);
            if (!doesLotExists && productTypes.contains(prod.Product_Type_vod__c)) {
                // now create lot catalog
                Lot_Catalog_vod__c lotCatalog = new Lot_Catalog_vod__c (Name = 'No_Lot_vod', Suppress_Lot_vod__c = true,
                                                                        Product_vod__c = prod.Id, Sample_Description_vod__c =  prod.Description_vod__c,
                                                                        Item_ID_vod__c = prod.External_ID_vod__c , U_M_vod__c = prod.Sample_U_M_vod__c ,
                                                                        Active_vod__c = true);
                insertLotCatalogs.add(lotCatalog);    
            }   
            
        }
        
    }
    
    // now if the list any lot catalogs to insert then insert them
    if (insertLotCatalogs.size() > 0 ) {
        insert insertLotCatalogs;
    }
    
    
       
                                                                     
     
    
     


}