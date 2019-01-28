trigger VOD_COMP_COLLAB_RECORD_TYPE_ID_BEFORE_INSERT_UPDATE on Company_Collaboration_vod__c (before insert, before update) {
  RecordTypeIdByName.setRecordIdsByRecordNames(Trigger.new);
}