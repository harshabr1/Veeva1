trigger VOD_PRICING_SUBRULE_BEFORE_INS_UPD_DEL on Pricing_Subrule_vod__c (before insert, before update, before delete) {

    List<Pricing_Subrule_vod__c> triggeredSubrules = null;
    Set<Id> relevantPricingRuleIds = new Set<Id>();
    Map<Id, Set<String>> pricingRuleExternalIds = new Map<Id, Set<String>>();

    Map<Id, Id> pricingRuleProductIds = new Map<Id, Id>();
    Map<Id, Date> pricingRuleToStartDate = new Map<Id, Date>();
    Map<Id, Date> pricingRuleToEndDate = new Map<Id, Date>();
    Map<Id, Decimal> pricingRuleToMinQty = new Map<Id, Decimal>();
    Map<Id, Decimal> pricingRuleToMaxQty = new Map<Id, Decimal>();
    Map<Id, List<Pricing_Subrule_vod__c>> pricingRuleToSubRules = new Map<Id, List<Pricing_Subrule_vod__c>>();
    Map<String, Set<Id>> pricingRuleExtIdToRules = new Map<String, Set<Id>>();

    // If this is a Delete call, then use the Old values
    if(Trigger.isDelete) {
        triggeredSubrules = Trigger.old;
    } else {
        triggeredSubrules = Trigger.new;
        
        Set<Id> prodIds = new Set<Id>();
        Set<Id> kitParents = new Set<Id>();
        
        for (Pricing_Subrule_vod__c pr : Trigger.new) {        
            //kit parents
            if (pr.Product_vod__c != null) {
                prodIds.add(pr.Product_vod__c);
            }
        }
        
        for (Product_vod__c kitItem : [SELECT Parent_Product_vod__c
                                       FROM Product_vod__c 
                                       WHERE Product_Type_vod__c = 'Kit Item' 
                                       AND Parent_Product_vod__c IN :prodIds])
        {
            kitParents.add(kitItem.Parent_Product_vod__c);
        }
        
        // limits on kit
        for (Pricing_Subrule_vod__c pr : Trigger.new) {
            Id product = pr.Product_vod__c;
            if (product != null && kitParents.contains(product) && pr.Comparison_Type_vod__c != 'Quantity_vod') {
                pr.Id.addError(System.Label.Kit_Type_Error, false);
                return;
            }
        }
    }

    // If the list is empty, return
    if(triggeredSubrules == null || triggeredSubrules.size() == 0) {
        return;
    }

    // Add the Parent Chain Rule Ids to a set
    for(Pricing_Subrule_vod__c subRule : triggeredSubrules) {
        relevantPricingRuleIds.add(subRule.Pricing_Rule_vod__c);
    }
    
    //logic to account for external ids formatted in the old way
    RecordType recTypePayment;
    RecordType recTypeDeliveryPeriod;
    RecordType recTypeFreeGoods;
    RecordType recTypeFreeGoodsPercent;
    
    for (RecordType recType : [Select Id, DeveloperName from RecordType where SobjectType = 'Pricing_Rule_vod__c' and DeveloperName in ('Payment_Terms_Rule_vod', 
                'Delivery_Period_vod', 'Free_Goods_Rule_vod', 'Free_Goods_Percentage_Rule_vod')]) {
        if (recType.DeveloperName == 'Delivery_Period_vod') {
            recTypeDeliveryPeriod = recType;
        } else if(recType.DeveloperName == 'Free_Goods_Rule_vod') {
            recTypeFreeGoods = recType;
        } else if(recType.DeveloperName == 'Free_Goods_Percentage_Rule_vod') {
            recTypeFreeGoodsPercent = recType;  
        } else if(recType.DeveloperName == 'Payment_Terms_Rule_vod') {
            recTypePayment = recType;
        }
    }

    // Query for the External Id of each Parent Chain Rule and create a Map of Pricing Rule Id -> External Id
    // Create a Map of Pricing Rule Id -> Product Id
    for(Pricing_Rule_vod__c chainRule :
        [SELECT Id, Product_vod__c, External_Id_vod__c, Quantity_Min_vod__c, Quantity_Max_vod__c, Start_Date_vod__c,
         	End_Date_vod__c, Delivery_Order_vod__c, RecordTypeId, Min_Delivery_Time_Frame_vod__c, Comparison_Type_vod__c, 
         	Contract_vod__c, Account_vod__c, Account_Group_vod__c, Order_Campaign_vod__c, Pricing_Group_vod__c,
         	Comparison_Product_vod__c, Cross_Product_Rule_vod__c, Price_Book_vod__c
        FROM Pricing_Rule_vod__c
        WHERE Id IN :relevantPricingRuleIds]) {
            
        Set<String> ruleExternalIds = pricingRuleExternalIds.get(chainRule.Id);
        if (ruleExternalIds == null) {
            ruleExternalIds = new Set<String>();
            pricingRuleExternalIds.put(chainRule.Id, ruleExternalIds);
        }
        ruleExternalIds.add(chainRule.External_Id_vod__c);
        
        String oldExternalId = VEEVA_PRICE_RULE_CLASS.getBaseExternalId(chainRule, recTypeFreeGoods, recTypeFreeGoodsPercent,
                                                                        recTypeDeliveryPeriod, recTypePayment);               
        String oldExternalId1 = oldExternalId + '__' + chainRule.Delivery_Order_vod__c + '__' + chainRule.Contract_vod__c;
        String oldExternalId2 = oldExternalId + '__' + chainRule.Delivery_Order_vod__c + '__true__' + chainRule.Contract_vod__c;
        String oldExternalId3 = oldExternalId1 + '__true';
        
        ruleExternalIds.add(oldExternalId1);
        ruleExternalIds.add(oldExternalId2);
        ruleExternalIds.add(oldExternalId3);
            
        pricingRuleProductIds.put(chainRule.Id, chainRule.Product_vod__c);
        pricingRuleToStartDate.put(chainRule.Id, chainRule.Start_Date_vod__c);
        pricingRuleToEndDate.put(chainRule.Id, chainRule.End_Date_vod__c);
        pricingRuleToMinQty.put(chainRule.Id, chainRule.Quantity_Min_vod__c);
        pricingRuleToMaxQty.put(chainRule.Id, chainRule.Quantity_Max_vod__c);
    }

    // Create a Map of Pricing Rule -> Sub Rules
    // Create a Map of External Id -> Pricing Rule Id
    // Create a Map of Pricing Rule -> Product Id
    Set<String> unrolledExternalIds = new Set<String>();
    for (Set<String> ruleExternalIds : pricingRuleExternalIds.values()) {
        unrolledExternalIds.addAll(ruleExternalIds);
    }
    for(Pricing_Subrule_vod__c subRule :
        [SELECT Id, Pricing_Rule_vod__c, Product_vod__c, Comparison_Type_vod__c,
            Min_Quantity_vod__c, Max_Quantity_vod__c, Pricing_Rule_vod__r.External_Id_vod__c,
            Pricing_Rule_vod__r.Product_vod__c, Pricing_Rule_vod__r.Quantity_Min_vod__c,
            Pricing_Rule_vod__r.Quantity_Max_vod__c, Pricing_Rule_vod__r.Start_Date_vod__c, 
         	Pricing_Rule_vod__r.End_Date_vod__c, Pricing_Rule_vod__r.Delivery_Order_vod__c,
         	Pricing_Rule_vod__r.RecordTypeId, Pricing_Rule_vod__r.Min_Delivery_Time_Frame_vod__c,
         	Pricing_Rule_vod__r.Comparison_Type_vod__c, Pricing_Rule_vod__r.Contract_vod__c,
         	Pricing_Rule_vod__r.Account_vod__c, Pricing_Rule_vod__r.Account_Group_vod__c,
         	Pricing_Rule_vod__r.Order_Campaign_vod__c, Pricing_Rule_vod__r.Pricing_Group_vod__c,
         	Pricing_Rule_vod__r.Comparison_Product_vod__c, Pricing_Rule_vod__r.Cross_Product_Rule_vod__c,
         	Pricing_Rule_vod__r.Price_Book_vod__c
        FROM Pricing_Subrule_vod__c
        WHERE Pricing_Rule_vod__r.External_Id_vod__c IN :unrolledExternalIds]) {

        List<Pricing_Subrule_vod__c> subRuleList = pricingRuleToSubRules.get(subRule.Pricing_Rule_vod__c);
        if(subRuleList == null) {
            subRuleList = new List<Pricing_Subrule_vod__c>();
        }
        subRuleList.add(subRule);
        pricingRuleToSubRules.put(subRule.Pricing_Rule_vod__c, subRuleList);

        Set<Id> pricingRules = pricingRuleExtIdToRules.get(subRule.Pricing_Rule_vod__r.External_Id_vod__c);
        if(pricingRules == null) {
            pricingRules = new Set<Id>();
        }
        pricingRules.add(subRule.Pricing_Rule_vod__c);
        pricingRuleExtIdToRules.put(subRule.Pricing_Rule_vod__r.External_Id_vod__c, pricingRules);
            
        String oldExternalId = VEEVA_PRICE_RULE_CLASS.getBaseExternalId(subRule.Pricing_Rule_vod__r, recTypeFreeGoods, recTypeFreeGoodsPercent,
                                                                            recTypeDeliveryPeriod, recTypePayment);                       
        String oldExternalId1 = oldExternalId + '__' + subRule.Pricing_Rule_vod__r.Delivery_Order_vod__c + '__' + subrule.Pricing_Rule_vod__r.Contract_vod__c;
        String oldExternalId2 = oldExternalId + '__' + subRule.Pricing_Rule_vod__r.Delivery_Order_vod__c + '__true__' + subrule.Pricing_Rule_vod__r.Contract_vod__c;
        String oldExternalId3 = oldExternalId1 + '__true';
            
        Set<Id> pricingRules1 = pricingRuleExtIdToRules.get(oldExternalId1);
        if(pricingRules1 == null) {
            pricingRules1 = new Set<Id>();
        }
        pricingRules1.add(subRule.Pricing_Rule_vod__c);
        pricingRuleExtIdToRules.put(oldExternalId1, pricingRules1);
            
        Set<Id> pricingRules2 = pricingRuleExtIdToRules.get(oldExternalId2);
        if(pricingRules2 == null) {
            pricingRules2 = new Set<Id>();
        }
        pricingRules2.add(subRule.Pricing_Rule_vod__c);
        pricingRuleExtIdToRules.put(oldExternalId2, pricingRules2);
            
        Set<Id> pricingRules3 = pricingRuleExtIdToRules.get(oldExternalId3);
        if(pricingRules3 == null) {
            pricingRules3 = new Set<Id>();
        }
        pricingRules3.add(subRule.Pricing_Rule_vod__c);
        pricingRuleExtIdToRules.put(oldExternalId3, pricingRules3);

        pricingRuleProductIds.put(subRule.Pricing_Rule_vod__c, subRule.Pricing_Rule_vod__r.Product_vod__c);
        pricingRuleToStartDate.put(subRule.Pricing_Rule_vod__c, subRule.Pricing_Rule_vod__r.Start_Date_vod__c);
        pricingRuleToEndDate.put(subRule.Pricing_Rule_vod__c, subRule.Pricing_Rule_vod__r.End_Date_vod__c);
        pricingRuleToMinQty.put(subRule.Pricing_Rule_vod__c, subRule.Pricing_Rule_vod__r.Quantity_Min_vod__c);
        pricingRuleToMaxQty.put(subRule.Pricing_Rule_vod__c, subRule.Pricing_Rule_vod__r.Quantity_Max_vod__c);
    }

    //System.debug('triggeredSubrules: ' + triggeredSubrules);
    //System.debug('relevantPricingRuleIds: ' + relevantPricingRuleIds);
    //System.debug('pricingRuleExternalIds: ' + pricingRuleExternalIds);
    //System.debug('pricingRuleProductIds: ' + pricingRuleProductIds);
    //System.debug('pricingRuleToSubRules: ' + pricingRuleToSubRules);
    //System.debug('pricingRuleExtIdToRules: ' + pricingRuleExtIdToRules);

    for(Pricing_Subrule_vod__c subRule : triggeredSubrules) {
        List<Pricing_Subrule_vod__c> subRulesList = pricingRuleToSubRules.get(subRule.Pricing_Rule_vod__c);
        if(subRulesList == null) {
            subRulesList = new List<Pricing_Subrule_vod__c>();
        }

        //System.debug('subRulesList: ' + subRulesList);

        Set<String> parentRuleExternalIds = pricingRuleExternalIds.get(subRule.Pricing_Rule_vod__c);
        if(parentRuleExternalIds.size() <= 0) {
            continue;
        }

        // Get all the Subrules of the Parent of THIS Subrule
        Set<Id> similarPricingRules = new Set<Id>();
        
        for (String externalId : parentRuleExternalIds) {
            Set<Id> rules = pricingRuleExtIdToRules.get(externalId);
            if (rules != null) {
            	similarPricingRules.addAll(rules);
            }
        }
        
        if (similarPricingRules.size() == 0) {
            continue;
        }

        //System.debug('similarPricingRules: ' + similarPricingRules);

        // Create a new Map of Internal ID -> Subrule
        // Internal ID is '<Comparison Type>:<Product>'
        Map<String, Pricing_Subrule_vod__c> interalIdToSubrules = new Map<String, Pricing_Subrule_vod__c>();
        for(Pricing_Subrule_vod__c rule : subRulesList) {
            if((Trigger.isDelete || Trigger.isUpdate) && rule.Id == subRule.Id) {
                continue;
            }
            interalIdToSubrules.put(rule.Comparison_Type_vod__c + ':' + rule.Product_vod__c, rule);
        }

        // If this is not a Delete call, then either add THIS Subrule to the map above, or if there is a similar Subrule, add an Error
        if(!Trigger.isDelete) {
            Pricing_Subrule_vod__c existingRule = interalIdToSubrules.get(subRule.Comparison_Type_vod__c + ':' + subRule.Product_vod__c);
            if(existingRule == null) {
                interalIdToSubrules.put(subRule.Comparison_Type_vod__c + ':' + subRule.Product_vod__c, subRule);
            } else {
                subRule.Id.addError(System.Label.OVERLAP_ERROR, false);
                continue;
            }
        }

        //System.debug('interalIdToSubrules: ' + interalIdToSubrules);

        Date parentStart = pricingRuleToStartDate.get(subRule.Pricing_Rule_vod__c);
        Date parentEnd = pricingRuleToEndDate.get(subRule.Pricing_Rule_vod__c);        
        Decimal parentMin = pricingRuleToMinQty.get(subRule.Pricing_Rule_vod__c);
        Decimal parentMax = pricingRuleToMaxQty.get(subRule.Pricing_Rule_vod__c);

        //System.debug('parentMin: ' + parentMin);
        //System.debug('parentMax: ' + parentMax);

        for(Id similarPricingRuleId : similarPricingRules) {
            // Don't compare the Parent Rule to the Parent Rule
            if(subRule.Pricing_Rule_vod__c == similarPricingRuleId) {
                continue;
            }

            // If the Parent Rule's Product doesn't match THIS Subrule's Parent Rule Product, then continue since they are not similar rules
            if(pricingRuleProductIds.get(subRule.Pricing_Rule_vod__c) != pricingRuleProductIds.get(similarPricingRuleId)) {
                //System.debug('no match');
                continue;
            }

            //System.debug('similarPricingRuleId: ' + similarPricingRuleId);

            List<Pricing_Subrule_vod__c> similarSubrules = pricingRuleToSubRules.get(similarPricingRuleId);
            if(similarSubrules == null) {
                continue;
            }

            //System.debug('similarSubRules: ' + similarSubrules);

            // If the two Parent Rules don't have the same number of Subrules, then continue
            if(similarSubrules.size() != interalIdToSubrules.size()) {
                continue;
            }

            Date similarStart = pricingRuleToStartDate.get(similarPricingRuleId);
            Date similarEnd = pricingRuleToEndDate.get(similarPricingRuleId);
            Decimal similarMin = pricingRuleToMinQty.get(similarPricingRuleId);
            Decimal similarMax = pricingRuleToMaxQty.get(similarPricingRuleId);

            // If the Parent Rules are not overlapping then continue
            if(!VOD_PRICING_UTILS.datesOverlap(parentStart, parentEnd, similarStart, similarEnd) ||
               !VOD_PRICING_UTILS.isOverlapping(parentMin, parentMax, similarMin, similarMax)) {
                continue;
            }

            // Counter for similar rules. If all the rules are similar then add an error
            Integer similarRules = 0;

            for(Pricing_Subrule_vod__c similarSubrule : similarSubrules) {

                // Create an Internal ID
                String similarRuleInternalId = similarSubrule.Comparison_Type_vod__c + ':' + similarSubrule.Product_vod__c;

                // Get the matching Subrule
                Pricing_Subrule_vod__c foundExistingSubrule = interalIdToSubrules.get(similarRuleInternalId);

                // If the Internal ID exists in the Map, then we have found a similar rule
                // Verify that the ranges are not overlapping
                if(foundExistingSubrule != null &&
                        VOD_PRICING_UTILS.isOverlapping(foundExistingSubrule.Min_Quantity_vod__c,
                                foundExistingSubrule.Max_Quantity_vod__c,
                                similarSubrule.Min_Quantity_vod__c,
                                similarSubrule.Max_Quantity_vod__c)) {
                    similarRules++;
                }
            }
            if(similarRules == interalIdToSubrules.size()) {
                subRule.Id.addError(System.Label.OVERLAP_ERROR, false);
                continue;
            }
        }
    }
}