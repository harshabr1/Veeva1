trigger Account_List_After_Delete_vod on Account_List_vod__c (after delete) {
	for (Account_List_Item_vod__c [] items : [Select Id from Account_List_Item_vod__c where Account_vod__c in :trigger.oldMap.KeySet()])
        delete items;
}