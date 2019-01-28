trigger VEEVA_PRICING_RULE_BEFORE_INS_UPD on Pricing_Rule_vod__c (before insert, before update) {
    if (VOD_ORDER_CAMPAIGN_TRIG.getCampaignTrig() == true)
        return;
    List <String> externalIds = new List<String> ();
    RecordType recTypeListPrice;
    RecordType recTypePayment;
    RecordType recTypeDeliveryPeriod;
    RecordType recTypeFreeGoods;
    RecordType recTypeFreeGoodsPercent;
    RecordType recTypeLimit;
    for (RecordType recType : [Select Id, DeveloperName from RecordType where SobjectType = 'Pricing_Rule_vod__c' and DeveloperName in ('List_Price_Rule_vod', 'Payment_Terms_Rule_vod', 
                'Delivery_Period_vod', 'Free_Goods_Rule_vod', 'Free_Goods_Percentage_Rule_vod', 'Limit_Rule_vod')]) {
        if (recType.DeveloperName == 'List_Price_Rule_vod') {
            recTypeListPrice = recType;
        } else if (recType.DeveloperName == 'Delivery_Period_vod') {
            recTypeDeliveryPeriod = recType;
        } else if(recType.DeveloperName == 'Free_Goods_Rule_vod') {
        	recTypeFreeGoods = recType;
        } else if(recType.DeveloperName == 'Free_Goods_Percentage_Rule_vod') {
          	recTypeFreeGoodsPercent = recType;  
        } else if(recType.DeveloperName == 'Limit_Rule_vod') {
            recTypeLimit = recType;
        } else if(recType.DeveloperName == 'Payment_Terms_Rule_vod') {
            recTypePayment = recType;
        }
    }
    
    Set<Id> campaignIds = new Set<Id>();
    Set<Id> prodIds = new Set<Id>();
    Set<Id> kitParents = new Set<Id>();
        
    for (Pricing_Rule_vod__c pr : Trigger.new) {        
        //order campaign
        if (pr.Order_Campaign_vod__c != null) {
            campaignIds.add(pr.Order_Campaign_vod__c);
        }
        
        //kit parents
        if (pr.Product_vod__c != null) {
            prodIds.add(pr.Product_vod__c);
        }
        if (pr.Comparison_Product_vod__c != null) {
            prodIds.add(pr.Comparison_Product_vod__c);
        }
    }
    
    Map<Id, Order_Campaign_vod__c> campaigns = new Map<Id, Order_Campaign_vod__c>([SELECT Id, Start_Date_vod__c, End_Date_vod__c 
                                                                                   FROM Order_Campaign_vod__c 
                                                                                   WHERE Id IN :campaignIds]);
    for (Product_vod__c kitItem : [SELECT Parent_Product_vod__c
                                   FROM Product_vod__c 
                                   WHERE Product_Type_vod__c = 'Kit Item' 
                                   AND Parent_Product_vod__c IN :prodIds])
    {
        kitParents.add(kitItem.Parent_Product_vod__c);
    }
    
    for (Pricing_Rule_vod__c pr : Trigger.new) {
        if(Trigger.isUpdate){
            /*if(pr.Order_Campaign_vod__c != null){
                Order_Campaign_vod__c theCampaign = campaigns.get(pr.Order_Campaign_vod__c);
                if(theCampaign != null
                   &&(pr.Start_Date_vod__c != theCampaign.Start_Date_vod__c
                      || pr.End_Date_vod__c != theCampaign.End_Date_vod__c)){
                          pr.Id.addError(System.Label.INCONSISTENT_DATE_ERROR, false);
                          return;
                      }
            }*/
        }else if(Trigger.isInsert){
            /*if(pr.Order_Campaign_vod__c != null){
                Order_Campaign_vod__c theCampaign = campaigns.get(pr.Order_Campaign_vod__c);
                if(theCampaign != null){
                    pr.Start_Date_vod__c = theCampaign.Start_Date_vod__c;
                    pr.End_Date_vod__c = theCampaign.End_Date_vod__c;
                }
            }*/

            // Free Goods Percentage rules always have Comparison Type of Quantity
            if(pr.RecordTypeId == recTypeFreeGoodsPercent.Id) {
                pr.Comparison_Type_vod__c = 'Product Quantity';
            }
        }

        if(pr.RecordTypeId == recTypeListPrice.Id) {
            pr.Quantity_Max_vod__c = null;
            pr.Quantity_Min_vod__c = null;
            pr.Comparison_Type_vod__c = null;
        }
        else if(pr.Quantity_Max_vod__c == null && pr.Quantity_Min_vod__c == null){
            pr.Id.addError(System.Label.QUANTITY_ERROR, false);
            return;
        }

        // limits on kit
        Id product = pr.Product_vod__c;
        if (product != null && kitParents.contains(product) && pr.RecordTypeId != recTypeDeliveryPeriod.Id) {   
            if ((pr.Cross_Product_Rule_vod__c && (pr.RecordTypeId != recTypeLimit.Id || pr.Product_Comparison_Type_vod__c != 'Product Quantity')) || pr.RecordTypeId == recTypeListPrice.Id || pr.Comparison_Type_vod__c != 'Product Quantity') {
                pr.Id.addError(System.Label.Kit_Type_Error, false);
                return;
            }
        }

        product = pr.Comparison_Product_vod__c;
        if (product != null && pr.Comparison_Type_vod__c != 'Product Quantity' && kitParents.contains(product)){
            pr.Id.addError(System.Label.Kit_Type_Error, false);
            return;
        }

        SObject prInterface = (SObject)pr;
        String Currcode  = '';

        try {
            Currcode  = (String)prInterface.get('CurrencyIsoCode');
        } catch ( System.SObjectException e) {
        }
        // Create an external ID.
        if(pr.RecordTypeId == recTypeFreeGoodsPercent.Id) {
            pr.External_Id_vod__c = recTypeFreeGoods.Id + '__';
        } else {
            pr.External_Id_vod__c = pr.RecordTypeId + '__';    
        }
        if (pr.RecordTypeId == recTypeDeliveryPeriod.Id) {
            pr.External_Id_vod__c += (pr.Min_Delivery_Time_Frame_vod__c != null);
        } else if (pr.RecordTypeId != recTypePayment.Id) {
            pr.External_Id_vod__c += pr.Comparison_Type_vod__c + '__';
        }
        pr.External_Id_vod__c += Currcode +'__'+
            pr.Product_vod__c + '__' +
            pr.Account_vod__c+ '__' +
            pr.Account_Group_vod__c +'__' +
            pr.Order_Campaign_vod__c +'__'+
            pr.Pricing_Group_vod__c +'__' +
            pr.Comparison_Product_vod__c + '__' +
            pr.Cross_Product_Rule_vod__c;
        //STOP: BEFORE YOU CHANGE HOW THIS EXTERNAL ID WORKS, CONSULT A DEVELOPER (OTHER THAN YOURSELF).
        
        String externalId1 = pr.External_Id_vod__c +  '__' + pr.Delivery_Order_vod__c + '__' + pr.Contract_vod__c;
        String externalId2 = pr.External_Id_vod__c + '__' + pr.Delivery_Order_vod__c + '__' + pr.Chain_Rule_vod__c + '__' + pr.Contract_vod__c;

        pr.External_Id_vod__c += '__' + pr.Contract_vod__c;
        
        if (pr.Delivery_Order_vod__c) {
            pr.External_Id_vod__c += '__' + pr.Delivery_Order_vod__c;
        }
        
        if (pr.Chain_Rule_vod__c) {
            pr.External_Id_vod__c += '__' + pr.Chain_Rule_vod__c;
        }

        if(pr.Price_Book_vod__c != null) {
            pr.External_Id_vod__c += '__' + pr.Price_Book_vod__c;
        }

        externalIds.add(pr.External_Id_vod__c);
        externalIds.add(externalId1);
        externalIds.add(externalId2);
    }
    Map <String, List<VEEVA_PRICE_RULE_CLASS>> priceList = new Map <String, List<VEEVA_PRICE_RULE_CLASS>> ();

    for (Pricing_Rule_vod__c checkPr : [SELECT External_Id_vod__c,
                                        Quantity_Min_vod__c,
                                        Quantity_Max_vod__c,
                                        Product_Minimum_vod__c,
                                        Product_Maximum_vod__c,
                                        Start_Date_vod__c,
                                        End_Date_vod__c,
                                        Chain_Rule_vod__c,
                                        Delivery_Start_Date_vod__c,
                                        Delivery_End_Date_vod__c,
                                        Min_Delivery_Time_Frame_vod__c,
                                        Name,
                                            (SELECT Product_vod__c
                                             FROM Pricing_Subrules_vod__r
                                             ORDER BY Product_vod__c)
                                        FROM Pricing_Rule_vod__c where External_Id_vod__c in :externalIds
                                        AND ID not in :Trigger.new]) {

                                            List <VEEVA_PRICE_RULE_CLASS> myList = priceList.get(checkPr.External_Id_vod__c);
                                            if (myList == null)
                                                myList = new List<VEEVA_PRICE_RULE_CLASS> ();
                                            VEEVA_PRICE_RULE_CLASS vprc = new VEEVA_PRICE_RULE_CLASS (checkPr.External_Id_vod__c,
                                                                                                      checkPr.Quantity_Min_vod__c,
                                                                                                      checkPr.Quantity_Max_vod__c,
                                                                                                      checkPr.Product_Minimum_vod__c,
                                                                                                      checkPr.Product_Maximum_vod__c,
                                                                                                      checkPr.Start_Date_vod__c,
                                                                                                      checkPr.End_Date_vod__c,
                                                                                                      checkPr.Name,
                                                                                                      checkPr.Delivery_Start_Date_vod__c,
                                                                                                      checkPr.Delivery_End_Date_vod__c,
                                                                                                      checkPr.Min_Delivery_Time_Frame_vod__c);
                                            if (checkPr.Chain_Rule_vod__c) {
                                                String subruleProducts = '';
                                                if (checkPr.Pricing_Subrules_vod__r != null) {
                                                    for (Pricing_Subrule_vod__c subrule : checkPr.Pricing_Subrules_vod__r) {
                                                        if (subrule.Product_vod__c != null) {
                                                            subruleProducts += subrule.Product_vod__c;
                                                        } else {
                                                            subruleProducts += 'OrderLevel';
                                                        }
                                                    }
                                                }
                                                vprc.setSubruleProducts(subruleProducts);
                                            }
                                            myList.add(vprc);

                                            priceList.put(checkPr.External_Id_vod__c, myList);

                                        }

    Set<Id> chainIdsToValidate = new Set<Id>();
    for (Pricing_Rule_vod__c pr : Trigger.new) {
        // Fix for getting old pricing rules with old external id formats
        String oldExternalId = VEEVA_PRICE_RULE_CLASS.getBaseExternalId(pr, recTypeFreeGoods, recTypeFreeGoodsPercent,
                                                                                recTypeDeliveryPeriod, recTypePayment);
        
        String oldExternalId1 = oldExternalId +  '__' + pr.Delivery_Order_vod__c + '__' + pr.Contract_vod__c;
        String oldExternalId2 = oldExternalId + '__' + pr.Delivery_Order_vod__c + '__' + pr.Chain_Rule_vod__c + '__' + pr.Contract_vod__c;
        
        List <VEEVA_PRICE_RULE_CLASS> checkList = priceList.get(pr.External_Id_vod__c);
        
        List<VEEVA_PRICE_RULE_CLASS> toAdd1 = priceList.get(oldExternalId1);
        List<VEEVA_PRICE_RULE_CLASS> toAdd2 = priceList.get(oldExternalId2);
        
        if (checkList == null) {
            checkList = toAdd1;
        } else if (toAdd1 != null) {
            checkList.addAll(toAdd1);
        }
        
        if (checkList == null) {
            checkList = toAdd2;
        } else if (toAdd2 != null) {
            checkList.addAll(toAdd2);
        }

        

        // No rows in DB.
        if (checkList == null || checkList.size() == 0)
            continue;

        boolean isDeliveryPeriod = pr.RecordTypeId == recTypeDeliveryPeriod.Id;
        for (VEEVA_PRICE_RULE_CLASS cVprc : checkList) {
            if ((pr.Start_Date_vod__c >= cVprc.Start_date && pr.Start_Date_vod__c <= cVprc.End_date) ||
                (cVprc.Start_date >= pr.Start_Date_vod__c && cVprc.Start_date <= pr.End_Date_vod__c)) {
                    if (isDeliveryPeriod) {
                        if (pr.Min_Delivery_Time_Frame_vod__c != null && cVprc.Min_Delivery_Time_Frame != null) {
                    		pr.Id.addError(System.Label.OVERLAP_ERROR, false);
                        } else if (cVprc.hasOverlappingDeliveryDates(pr)) {
                        	pr.Id.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('OVERLAPPING_DELIVERY_DATES', 'ORDER_MANAGEMENT',
                            	'Another Delivery Period Rule exists with the same or overlapping Delivery Start and End Dates.'), false);
                        }
                        break;
                    }
                    if(cVprc.Min_val == null){ //existing rule has a open qtyMin
                        if(pr.Quantity_Min_vod__c == null || pr.Quantity_Min_vod__c < cVprc.Max_val){
                            if (pr.Chain_Rule_vod__c) {
                                chainIdsToValidate.add(pr.Id);    
                            } else {
                                pr.Id.addError(System.Label.OVERLAP_ERROR, false);
                            }
                            break;
                        }
                    }else if(cVprc.Max_val == null){ //existing has a open qtyMax
                        if(pr.Quantity_Max_vod__c == null || pr.Quantity_Max_vod__c > cVprc.Min_val){
                            if (pr.Chain_Rule_vod__c) {
                                chainIdsToValidate.add(pr.Id);    
                            } else {
                                pr.Id.addError(System.Label.OVERLAP_ERROR, false);
                            }
                            break;
                        }
                    }
                    if(pr.Quantity_Min_vod__c == null){
                        if(cVprc.Min_val < pr.Quantity_Max_vod__c){ //new rule has open qtyMin
                            if (pr.Chain_Rule_vod__c) {
                                chainIdsToValidate.add(pr.Id);    
                            } else {
                                pr.Id.addError(System.Label.OVERLAP_ERROR, false);
                            }
                            break;
                        }
                    }else if(pr.Quantity_Max_vod__c == null){
                        if(cVprc.Max_val > pr.Quantity_Min_vod__c){ //new rule has open qtyMax
                            if (pr.Chain_Rule_vod__c) {
                                chainIdsToValidate.add(pr.Id);    
                            } else {
                                pr.Id.addError(System.Label.OVERLAP_ERROR, false);
                            }
                            break;
                        }
                    }
                    if (pr.Quantity_Min_vod__c > cVprc.Min_val && pr.Quantity_Min_vod__c < cVprc.Max_val) {
                        if (pr.Chain_Rule_vod__c) {
                            chainIdsToValidate.add(pr.Id);    
                        } else {
                            pr.Id.addError(System.Label.OVERLAP_ERROR, false);
                        }
                        break;
                    }
                    if (pr.Quantity_Max_vod__c > cVprc.Min_val && pr.Quantity_Max_vod__c < cVprc.Max_val) {
                        if (pr.Chain_Rule_vod__c) {
                            chainIdsToValidate.add(pr.Id);    
                        } else {
                            pr.Id.addError(System.Label.OVERLAP_ERROR, false);
                        }
                        break;
                    }
                    if (pr.Quantity_Min_vod__c == cVprc.Min_val || pr.Quantity_Max_vod__c == cVprc.Max_val) {
                        if (pr.Chain_Rule_vod__c) {
                            chainIdsToValidate.add(pr.Id);    
                        } else {
                            pr.Id.addError(System.Label.OVERLAP_ERROR, false);
                        }
                        break;
                    }
                }
        }
    }
    if (chainIdsToValidate.size() > 0) {
        for (Pricing_Rule_vod__c chainRule : [
            SELECT Id, External_Id_vod__c, Delivery_Order_vod__c, Contract_vod__c, Price_Book_vod__c,
                    RecordTypeId, Comparison_Type_vod__c, Product_vod__c, Account_vod__c, Account_Group_vod__c,
                    Order_Campaign_vod__c, Pricing_Group_vod__c, Comparison_Product_vod__c, Cross_Product_Rule_vod__c,
                (SELECT Product_vod__c
                 FROM Pricing_Subrules_vod__r
                 ORDER BY Product_vod__c)
            FROM Pricing_Rule_vod__c
            WHERE Id IN :chainIdsToValidate]) {
                String subruleProducts = '';
                if (chainRule.Pricing_Subrules_vod__r != null) {
                    for (Pricing_Subrule_vod__c subrule : chainRule.Pricing_Subrules_vod__r) {
                        subruleProducts += subrule.Product_vod__c;
                    }
                }
                
                String oldExternalId = VEEVA_PRICE_RULE_CLASS.getBaseExternalId(chainRule, recTypeFreeGoods, recTypeFreeGoodsPercent,
                                                                                recTypeDeliveryPeriod, recTypePayment);                
                String oldExternalId2 = oldExternalId + '__' + chainRule.Delivery_Order_vod__c + '__true__' + chainRule.Contract_vod__c;
                
                List <VEEVA_PRICE_RULE_CLASS> checkList = priceList.get(chainRule.External_Id_vod__c);
                List <VEEVA_PRICE_RULE_CLASS> toAdd2 = priceList.get(oldExternalId2);
                
                if (checkList == null) {
                    checkList = toAdd2;
                } else if (toAdd2 != null) {
                    checkList.addAll(toAdd2);
                }
                
                
                if (checkList != null) {
                    for (VEEVA_PRICE_RULE_CLASS cVprc : checkList) {
                        if (subruleProducts.equals(cVprc.subruleProducts)) {
                            Trigger.newMap.get(chainRule.Id).Id.addError(System.Label.OVERLAP_ERROR, false);
                            break;
                        }
                    }
                }                
        }
        
        if (Trigger.isInsert) {
            for (Pricing_Rule_vod__c chainRule : Trigger.new) {
                String subruleProducts = '';
                if (chainRule.Pricing_Subrules_vod__r != null) {
                    for (Pricing_Subrule_vod__c subrule : chainRule.Pricing_Subrules_vod__r) {
                        subruleProducts += subrule.Product_vod__c;
                    }
                }
                
                String oldExternalId = VEEVA_PRICE_RULE_CLASS.getBaseExternalId(chainRule, recTypeFreeGoods, recTypeFreeGoodsPercent,
                                                                                recTypeDeliveryPeriod, recTypePayment);               
                String oldExternalId2 = oldExternalId + '__' + chainRule.Delivery_Order_vod__c + '__true__' + chainRule.Contract_vod__c;
                
                List <VEEVA_PRICE_RULE_CLASS> checkList = priceList.get(chainRule.External_Id_vod__c);                
                List <VEEVA_PRICE_RULE_CLASS> toAdd2 = priceList.get(oldExternalId2);
                
                if (checkList == null) {
                    checkList = toAdd2;
                } else if (toAdd2 != null) {
                    checkList.addAll(toAdd2);
                }
                
                if (checkList != null) {
                    for (VEEVA_PRICE_RULE_CLASS cVprc : checkList) {
                        if (subruleProducts.equals(cVprc.subruleProducts)) {
                            chainRule.Id.addError(System.Label.OVERLAP_ERROR, false);
                            break;
                        }
                    }
                }   
            }
        }
    }
}