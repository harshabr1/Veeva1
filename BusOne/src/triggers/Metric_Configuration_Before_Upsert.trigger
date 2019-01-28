trigger Metric_Configuration_Before_Upsert on Metric_Configuration_vod__c (before insert, before update) {
    for (Metric_Configuration_vod__c metricConfig : Trigger.new) {
        if ((metricConfig.Available_Values_vod__c != null || metricConfig.Product_vod__c != null) && !(metricConfig.Metric_Type_vod__c == 'Text_vod' || metricConfig.Metric_Type_vod__c == 'Box_vod')) {
            metricConfig.addError(VOD_GET_ERROR_MSG.getErrorMsg('INVALID_METRIC_TYPE', 'Common'), false);
            continue;
        }
        if (metricConfig.Available_Values_vod__c != null) {
            Schema.DescribeSObjectResult productMetricsObject = Product_Metrics_vod__c.sObjectType.getDescribe();
            String fieldName = metricConfig.Name.toLowerCase();
            if (productMetricsObject.fields.getMap().keySet().contains(fieldName) && productMetricsObject.fields.getMap().get(fieldName).getDescribe().getType() == Schema.DisplayType.PICKLIST) {
                List<String> availableValues = metricConfig.Available_Values_vod__c.split(';');
                List<Schema.PicklistEntry> pickListValues = productMetricsObject.fields.getMap().get(fieldName).getDescribe().getPicklistValues();
                for (String value : availableValues) {
                    if (value != '') {
                        Boolean foundVal = false;
                        for (Schema.PicklistEntry pickListVal : pickListValues) {
                            System.debug(value);
                            System.debug(pickListVal.getValue());
                            if (value.equals(pickListVal.getValue())) {
                                foundVal = true;
                                break;
                            }
                        }
                        if (!foundVal) {
                            metricConfig.addError(VOD_GET_ERROR_MSG.getErrorMsg('INVALID_AVAILABLE_VALUES', 'Common'), false); 
                        }
                    }
                }
                
            }
        }
    }
}