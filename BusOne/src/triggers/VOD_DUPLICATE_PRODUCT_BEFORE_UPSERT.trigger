trigger VOD_DUPLICATE_PRODUCT_BEFORE_UPSERT on Assortment_Line_vod__c (before insert, before update) {       
    List<String> assortIds = new List<String>();
    List<Id> excludeLineIds = new List<Id>();
    //list of assortment lines because a product can be used for OM and IM assortments (and other assortments we may end up adding)
    Map<String, List<Assortment_Line_vod__c>> prodIdsToAssorts = new Map<String, List<Assortment_Line_vod__c>>();   
    
    for (Assortment_Line_vod__c line : Trigger.new) {
        assortIds.add(line.Assortment_vod__c);
        if (line.Id != null) {
            excludeLineIds.add(line.Id);
        }
        if (line.Product_vod__c != null) {
            List<Assortment_Line_vod__c> lines = prodIdsToAssorts.get(line.Product_vod__c);
            if (lines == null) {
                lines = new List<Assortment_Line_vod__c>();
                prodIdsToAssorts.put(line.Product_vod__c, lines);
            }
            lines.add(line);
        }
    }
    
    ASSORTMENT_LINE_TRIGGER_UTILS.checkForDuplicateAssortments(assortIds, excludeLineIds, Trigger.new);
    
    if (prodIdsToAssorts.size() > 0) {
        Id omAssortProdRt = [SELECT Id FROM RecordType where DeveloperName = 'OM_Assortment_Product_vod'].Id;
        Id imAssortProdRt = [SELECT Id FROM RecordType where DeveloperName = 'IM_Assortment_Product_vod'].Id;
        List<Assortment_Line_vod__c> newAssortLines = new List<Assortment_Line_vod__c>();
        Map<String, List<Assortment_Line_vod__c>> prodsToParentLines = new Map<String, List<Assortment_Line_vod__c>>();
        for (Product_vod__c prod : [SELECT Id, Parent_Product_vod__c, Product_Type_vod__c, Inventory_Monitoring_vod__c
                                    FROM Product_vod__c
                                    WHERE Parent_Product_vod__c IN :prodIdsToAssorts.keySet()
                                    AND Parent_Product_vod__r.Product_Type_vod__c = 'Detail'
                                    AND (Product_Type_vod__c IN ('Order', 'Inventory Monitoring') OR Inventory_Monitoring_vod__c = true)]) {
            List<Assortment_Line_vod__c> brandLines = prodIdsToAssorts.get(prod.Parent_Product_vod__c);
            List<Assortment_Line_vod__c> newLines = ASSORTMENT_LINE_TRIGGER_UTILS.createAssortmentLineFromProduct(prod, prodIdsToAssorts, omAssortProdRt, imAssortProdRt);
            newAssortLines.addAll(newLines);
            prodsToParentLines.put(prod.Id, brandLines);
        }
        
        try {
            insert newAssortLines;
        } catch (System.DmlException e) {
            Map<String, String> brandIdsToErrors = ASSORTMENT_LINE_TRIGGER_UTILS.getAssortmentErrors(e, newAssortLines, prodsToParentLines);
            
            for (String brandId: brandIdsToErrors.keySet()) {
                List<Assortment_Line_vod__c> lines = prodIdsToAssorts.get(brandId);
                for (Assortment_Line_vod__c line : lines) {
                    line.addError(brandIdsToErrors.get(brandId));
                }
            }
        }
    }
}