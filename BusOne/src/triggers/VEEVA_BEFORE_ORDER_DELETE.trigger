trigger VEEVA_BEFORE_ORDER_DELETE on Order_vod__c (before delete) {
      VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
        
            for (Integer i = 0; i <Trigger.old.size(); i++) {
                Order_vod__c orderOld = Trigger.old[i];
            
                if (orderOld.Lock_vod__c == true) {
                    orderOld.Id.addError(System.Label.NO_MODIFY_ORDER, false);
                } 
                
            }
}