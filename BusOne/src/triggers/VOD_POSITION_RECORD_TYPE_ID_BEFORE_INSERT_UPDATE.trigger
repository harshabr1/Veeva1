trigger VOD_POSITION_RECORD_TYPE_ID_BEFORE_INSERT_UPDATE on Position_vod__c (before insert, before update) {
    RecordTypeIdByName.setRecordIdsByRecordNames(Trigger.new);
}