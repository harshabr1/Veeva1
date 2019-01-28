trigger VOD_DATA_CHANGE_REQUEST_LINE_AFTER_INS_UPD on Data_Change_Request_Line_vod__c (after insert, after update) {
	List<String> possibleIdChanges = new List<String>();
    for (Integer i=0; i < Trigger.new.size(); i++) {
        Data_Change_Request_Line_vod__c changed = Trigger.new[i];
        Data_Change_Request_Line_vod__c original = null;
        if (Trigger.isUpdate) {
            original = Trigger.old[i];
        }
        VOD_DCR_LINE_UTIL.addPossibleIdChanges(original, changed, possibleIdChanges);
    }
    if (possibleIdChanges.size() > 0) {
        // future call
        VOD_DCR_LINE_UTIL.processPossibleIdChanges(possibleIdChanges);
    }
}