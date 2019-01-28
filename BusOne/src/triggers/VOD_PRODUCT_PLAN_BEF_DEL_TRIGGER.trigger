trigger VOD_PRODUCT_PLAN_BEF_DEL_TRIGGER on Product_Plan_vod__c (before delete) {
            
            String delErrMsg = VOD_GET_ERROR_MSG.getErrorMsg('DEL_PROD_PLAN_REF_ERROR', 'ProductPlan');
            List <Product_Strategy_vod__c> stList 
                = [Select Id, Name, Product_Plan_vod__c From Product_Strategy_vod__c 
                Where Product_Plan_vod__c in :Trigger.old];
               
              
        
            for (Product_Strategy_vod__c strat : stList) {
            
                Product_Plan_vod__c plan  = Trigger.oldMap.get (strat.Product_Plan_vod__c);
            
                if (plan != null) {
                    plan.addError (String.format(delErrMsg, new String[] {plan.Name, strat.Name, strat.Id}), false);
                }
        
            }
        
        }