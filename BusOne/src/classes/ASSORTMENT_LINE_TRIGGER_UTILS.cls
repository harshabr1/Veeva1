public class ASSORTMENT_LINE_TRIGGER_UTILS {

    public static void checkForDuplicateAssortments(List<String> assortIds, List<Id> excludeLineIds, List<Assortment_Line_vod__c> triggerLines) {
        Map<String, String> prodsToNames = new Map<String, String>();
        Map<String, Set<String>> assortsToProducts = new Map<String, Set<String>>();
        for (Assortment_Line_vod__c line : [SELECT Assortment_vod__c, Product_vod__c, Product_vod__r.Name
                                                  FROM Assortment_Line_vod__c 
                                                  WHERE Assortment_vod__c IN :assortIds
                                                  AND Id NOT IN :excludeLineIds
                                                  AND Product_vod__c != null]) {
            Set<String> products = assortsToProducts.get(line.Assortment_vod__c);
            if (products == null) {
                products = new Set<String>();
                assortsToProducts.put(line.Assortment_vod__c, products);
            }
            //test
            products.add(line.Product_vod__c);
            prodsToNames.put(line.Product_vod__c, line.Product_vod__r.Name);
        }
        
        for (Assortment_Line_vod__c line : triggerLines) {
            Set<String> products = assortsToProducts.get(line.Assortment_vod__c);
            if (products != null && products.contains(line.Product_vod__c)) {
                line.Product_vod__c.addError(VOD_VEEVA_MESSAGE.getMsgWithDefault('DUPLICATE_PRODUCTS', 'ORDER_MANAGEMENT', 'Duplicate Products Found') + ': ' + prodsToNames.get(line.Product_vod__c));
            }
        }
    }
    
    public static Map<String, String> getAssortmentErrors(System.DmlException e, List<Assortment_Line_vod__c> newAssortLines, Map<String, List<Assortment_Line_vod__c>> prodsToParentLines) {
    	Map<String, String> brandIdsToErrors = new Map<String, String>();
        Integer numErrors = e.getNumDml();
        for (Integer i = 0; i < numErrors; i++) {
            Integer insInd = e.getDmlIndex(i);
            Assortment_Line_vod__c newLine = newAssortLines[insInd];
            List<Assortment_Line_vod__c> brandLines = prodsToParentLines.get(newLine.Product_vod__c);
            for (Assortment_Line_vod__c brandLine : brandLines) {
                String error = brandIdsToErrors.get(brandLine.Product_vod__c);
                boolean first = false;
                if (error == null) {
                    error = '';
                    first = true;
                }
                brandIdsToErrors.put(brandLine.Product_vod__c, error + (first ? '' : ',\n') + e.getDmlMessage(i));
            }
        }
        return brandIdsToErrors;
    }
    
    public static List<Assortment_Line_vod__c> createAssortmentLineFromProduct(Product_vod__c product, Map<String, List<Assortment_Line_vod__c>> prodIdsToAssorts,
                                                                                Id omAssortProdRt, Id imAssortProdRt) {
        List<Assortment_Line_vod__c> newLines = new List<Assortment_Line_vod__c>();
        List<Assortment_Line_vod__c> brandLines = prodIdsToAssorts.get(product.Parent_Product_vod__c);
        for (Assortment_Line_vod__c brandLine : brandLines) {
            if (isValidProdForAssortment(brandLine, product, omAssortProdRt, imAssortProdRt)) {
                Assortment_Line_vod__c newLine = 
                    new Assortment_Line_vod__c(
                        Assortment_vod__c = brandLine.Assortment_vod__c,
                        Parent_Section_vod__c = brandLine.Parent_Section_vod__c,
                        Sorting_vod__c = brandLine.Sorting_vod__c,
                        Product_vod__c = product.Id,
                        RecordTypeId = brandLine.RecordTypeId
                    );
                newLines.add(newLine);
            }
        }
        return newLines;
    }
    
    private static boolean isValidProdForAssortment(Assortment_Line_vod__c brandLine, Product_vod__c product, Id omAssortProdRt, Id imAssortProdRt) {
        if (brandLine.RecordTypeId == omAssortProdRt) {
            return product.Product_Type_vod__c == 'Order';
        }
        if (brandLine.RecordTypeId == imAssortProdRt) {
            return product.Product_Type_vod__c == 'Inventory Monitoring' || product.Inventory_Monitoring_vod__c;
        }
        return false;
    }

}