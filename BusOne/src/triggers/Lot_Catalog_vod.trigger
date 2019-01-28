trigger Lot_Catalog_vod on Lot_Catalog_vod__c (before insert, before update) {
    String label  = System.label.USE_MULTI_SAMPLE_vod;             
    Boolean bUseSamp = false;  
    if (label != null && label != 'false') {
        bUseSamp = true;
    }
    // check all the types in the veeva settings
    
    Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
    Set<String> productTypes = new Set<String> ();
    if (vsc != null && vsc.Sample_Management_Product_Types_vod__c != null) {
       List<String> productTypesTemp = vsc.Sample_Management_Product_Types_vod__c.Split(';;');
       productTypes.addAll(productTypesTemp);
    } 
    
    // get the product ids so we can look up the product name
    List<String> productIds = new List<String> ();
    For (Lot_Catalog_vod__c lot : Trigger.new) {        
        productIds.add(lot.Product_vod__c);           
        
    }
    // now query the product catalog table to get the name and the product types of the prodcuts in lot catalog
    Map<Id, Product_vod__c> productsMap = new Map<Id, Product_vod__c> ([SELECT Id, Name, Product_Type_vod__c FROM Product_vod__c 
                                                                     WHERE Id IN:productIds]);  
    
    
    String productType = '';
    String prodName = '';
    String errorMsg = VOD_GET_ERROR_MSG.getErrorMsg('NO_CREATE_NO_LOT_VOD','TriggerError');
    
    For (Lot_Catalog_vod__c lot : Trigger.new) {
        
        // if the product look up is not null then get the product name
        if ((lot.Product_vod__c != null) && (productsMap.get(lot.Product_vod__c) != null )) { 
            Product_vod__c prod = productsMap.get(lot.Product_vod__c);               
            prodName = prod.Name;
            productType = prod.Product_type_vod__c;               
        }      
       
       if (lot.Suppress_Lot_vod__c == true && lot.Product_vod__c != null) { // now use the product name
           // include the product type in the external id          
           
           // No lot vod will be created only if the product type is listed in the veeva setting
           if (productTypes.contains(productType)) {
               lot.Sample_vod__c = prodName;                
               lot.Lot_Catalog_External_Id_vod__c = prodName.replaceAll(' ', '_') + '_' + lot.Name + '_' + productType;            
           } else { // error out trying to create No_Lot_vod for the product not listed
               lot.addError(errorMsg, false);
           }
           
       } else { // keep things as it is when Supress_vod__c is false          
           if (bUseSamp == true){  
               // if sample has value then use it for the external id otherwise use product name
               if (lot.Sample_vod__c != null) {             
                   lot.Lot_Catalog_External_Id_vod__c = lot.Sample_vod__c.replaceAll(' ', '_') + '_' + lot.Name; 
               } else {
                   system.debug(' user did not pick sample instead picked the product catalog so copy condition' );
                   system.debug(' the value of product name is  ' + prodName);
                   lot.Lot_Catalog_External_Id_vod__c = prodName.replaceAll(' ', '_') + '_' + lot.Name; 
                   lot.Sample_vod__c = prodName;
               }
           } 
           else { 
                lot.Lot_Catalog_External_Id_vod__c = lot.Name;
           }
        }  
    }    
                    
}