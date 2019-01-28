trigger VEEVA_APPROVED_DOCUMENT_AFTER_UPSERT on Approved_Document_vod__c (after insert, after update) {
    if(Trigger.new.size() == 0){
        return;
    }
    
    RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Approved_Document_vod__c' AND DeveloperName = 'Email_Receipt_vod' AND IsActive = TRUE];
    
    if (Trigger.isAfter) {
        if (recordType != null) {
            Id recordTypeId = recordType.Id;
            Map<Id, Id> replaceDocMap = new Map<Id, Id>();
            
            for (Approved_Document_vod__c appDoc : trigger.new) {
            	// System.debug('proccessing doc: ' + appDoc.name + ' id:' + appDoc.Id + ' status: ' + appDoc.Status_vod__c + ' vault: ' + appDoc.Document_ID_vod__c);
                if (appDoc.RecordTypeId == recordTypeId && appDoc.Status_vod__c == 'Approved_vod') {
                    Id appDocId = appDoc.Id;
                    String vaultDocId = appDoc.Vault_Document_ID_vod__c;
                    String vaultInstance = appDoc.Vault_Instance_ID_vod__c;
                    if (vaultDocId != null && vaultInstance != null) {
                        List<Approved_Document_vod__c> oldDocs = 
                            new List<Approved_Document_vod__c>([SELECT RecordTypeId, Name, Vault_Document_ID_vod__c,  Id, Status_vod__c, Vault_Instance_ID_vod__c, Document_ID_vod__c FROM Approved_Document_vod__c Where RecordTypeId = :recordTypeId AND Vault_Instance_ID_vod__c = :vaultInstance AND Vault_Document_ID_vod__c = :vaultDocId]);
                        if (!oldDocs.isEmpty()) {
                            for (Approved_Document_vod__c oldDoc : oldDocs) {
                                Id oldDocId = oldDoc.Id;
                                if (oldDocId != appDocId) {
                                	// System.debug('Need to replace ' + oldDocId + ' by ' + appDocId);
                                	replaceDocMap.put(oldDocId, appDocId);
                                }
                            }
                        }
                    }
                }
            }
            
            // Update MC Routing Records
            if (!replaceDocMap.isEmpty()) {
                Set<Id> oldDocIds = replaceDocMap.keySet();
                List<Multichannel_Route_vod__c> records = 
                    new List<Multichannel_Route_vod__c>([SELECT Id, Approved_Document_vod__c FROM Multichannel_Route_vod__c WHERE Approved_Document_vod__c IN :oldDocIds]);
                if (!records.isEmpty()) {
                    for (Multichannel_Route_vod__c record : records) {
                        Id oldDocId = record.Approved_Document_vod__c;
                        Id newDocId = replaceDocMap.get(oldDocId);
                        record.Approved_Document_vod__c = newDocId;
                    }
                    
                    update records;
                }   
            }
        }
    }
}