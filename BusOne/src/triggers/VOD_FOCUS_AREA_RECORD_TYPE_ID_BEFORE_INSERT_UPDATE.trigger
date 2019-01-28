trigger VOD_FOCUS_AREA_RECORD_TYPE_ID_BEFORE_INSERT_UPDATE on Focus_Area_vod__c (before insert, before update) {
  RecordTypeIdByName.setRecordIdsByRecordNames(Trigger.new);
}