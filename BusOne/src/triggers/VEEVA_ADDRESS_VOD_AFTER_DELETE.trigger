trigger VEEVA_ADDRESS_VOD_AFTER_DELETE on Address_vod__c (after delete) {
    
    String isRealTime = System.Label.ENABLE_REALTIME_ADDRESS_PUSH;
   if ('TRUE'.equalsIgnoreCase(isRealTime)) { 
        Set<Id> delSet = VOD_ADDRESS_TRIG.getDelSet();
    
        if (delSet.size() > 0) {
            String csIdList = '';
            Integer counter = 0;
            for (Id delId : delSet) {
                if (counter > 0)
                   csIdList += ',';
                csIdList += delId;
                counter++;
            }
            System.debug ('Deleting '+  csIdlist);
            VEEVA_ASYNC_ADDRESS_PUSH.deletePushedAccounts(csIdlist);
        }
   }
}