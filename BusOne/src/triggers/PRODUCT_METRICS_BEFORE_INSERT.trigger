trigger PRODUCT_METRICS_BEFORE_INSERT on Product_Metrics_vod__c (before insert) {
    List<Product_Metrics_vod__c> deleteMetrics = new List<Product_Metrics_vod__c>();
    //look for Product Metrics records to delete
    for (Integer i=0; i<Trigger.new.size(); i++) {
    	Product_Metrics_vod__c newProdMetric = Trigger.new[i];
    	//only check new Product Metrics that are being uploaded from offline (mobile devices)
    	if (newProdMetric.Mobile_ID_vod__c != null) {
			String accountId = newProdMetric.Account_vod__c;
			String productsId = newProdMetric.Products_vod__c;
			String detailGroupId = newProdMetric.Detail_Group_vod__c;

			for (Product_Metrics_vod__c prodMetrics : [SELECT Id, Mobile_ID_vod__c FROM Product_Metrics_vod__c WHERE
														   Account_vod__c = :accountId AND
														   Products_vod__c = :productsId AND
														   Detail_Group_vod__c = :detailGroupId
													   ]) {
				if (prodMetrics.Mobile_ID_vod__c != null) {
					//duplicate mobile record exists, so delete the old record, so the new one can replace it
					deleteMetrics.add(new Product_Metrics_vod__c(Id = prodMetrics.Id));
				}
			}
		}
    }
    delete deleteMetrics;
}