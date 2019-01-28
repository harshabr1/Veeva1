trigger VOD_CONTENT_ACK_ITEM_BEFORE_INSERT_UPDATE on Content_Acknowledgement_Item_vod__c (before insert, before update) {
     Set<Id> parentIds = new Set<Id>();
     for (Content_Acknowledgement_Item_vod__c item : Trigger.new) {
         if (item.Content_Acknowledgement_vod__c != null) {
             parentIds.add(item.Content_Acknowledgement_vod__c);
         }
     }
     Map<Id, Content_Acknowledgement_vod__c> parentMap = new Map<Id, Content_Acknowledgement_vod__c>([SELECT Id, Account_vod__c
                                                                                                      FROM Content_Acknowledgement_vod__c
                                                                                                      WHERE Id IN : parentIds]);
     for (Content_Acknowledgement_Item_vod__c item : Trigger.new) {
         if (item.Content_Acknowledgement_vod__c != null) {
             Content_Acknowledgement_vod__c parent = parentMap.get(item.Content_Acknowledgement_vod__c);
             item.Account_vod__c = parent.Account_vod__c;
         }
     }
 }