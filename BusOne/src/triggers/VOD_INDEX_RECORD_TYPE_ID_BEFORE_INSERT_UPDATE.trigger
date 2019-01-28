trigger VOD_INDEX_RECORD_TYPE_ID_BEFORE_INSERT_UPDATE on Index_vod__c (before insert, before update) {
  RecordTypeIdByName.setRecordIdsByRecordNames(Trigger.new);
}