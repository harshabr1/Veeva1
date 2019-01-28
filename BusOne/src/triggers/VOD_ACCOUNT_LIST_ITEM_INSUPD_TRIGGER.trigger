trigger VOD_ACCOUNT_LIST_ITEM_INSUPD_TRIGGER on Account_List_Item_vod__c (before insert, before update){

    for (Account_List_Item_vod__c item: Trigger.new) {
        item.External_ID_vod__c = item.Account_List_vod__c + '__' + item.Account_vod__c;
    }
}