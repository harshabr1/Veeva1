global class VOD_ProcessTSF {
    
           public static Set<Id> tsfProcessed = new Set<Id> ();
        // Use async call to avoid reaching statement limit
        // System.debug('limit: ' + Limits.getLimitScriptStatements());
        public static void processTSF (String callsXmlDoc) {
            if (System.isBatch() || System.isFuture()) {
                processTSFNoFuture(callsXmlDoc);
            } else {
                processTSFFuture(callsXmlDoc);
            }
        }

        @future
        public static void processTSFFuture(String callsXmlDoc){
            processTSFNoFuture(callsXmlDoc);
        }

        public static void processTSFNoFuture(String callsXmlDoc){
            // parse xmldoc to extract call information
            System.debug(callsXmlDoc);
            List<CallInfo> calls = parseCalls(callsXmlDoc);     
                                    
            Set <String> territoryInTrans = new Set <String> ();
            Set <Id> acctIds = new Set<Id>();
            Map <String, TSF_vod__c> tsfByTerr = new Map <String, TSF_vod__c> ();
            Map <String, String> perfAccMap = new Map <String,String>();
            Set <String> terrInTsf = new Set <String> ();
            Set<String> callids  = new Set<String>();
            // Create List of Accounts\Territories in trigger list
            for (CallInfo call : calls ) {
                acctIds.add(call.account);
                String key = call.account + '__' + call.territory;
                terrInTsf.add(call.territory);
                territoryInTrans.add (key);
                callids.add(call.id);
            }
       
           for (TSF_vod__c tsf : [Select Account_vod__c, Territory_vod__c, External_Id_vod__c 
                                  From TSF_vod__c 
                                  where Account_vod__c in :acctIds and Territory_vod__c in :terrInTsf] ) {
                String key = tsf.Account_vod__c + '__' + tsf.Territory_vod__c;      
                if (territoryInTrans.contains(key) && tsf.External_Id_vod__c == key) {
                    tsf.YTD_Activity_vod__c = 0;
                    tsf.Last_Activity_Date_vod__c = null;
                    tsfByTerr.put(key, tsf);
                }
            }
            
            for (Call2_vod__c busCall : 
                    [ Select Territory_vod__c, 
                             Account_vod__c,
                             (Select Account_vod__c From Call2_vod__r where Account_vod__c != null 
                               and Account_vod__r.IsPersonAccount = false LIMIT 1)
                      From Call2_vod__c 
                      where Id in :callids]) {
                    
                    String key = busCall.Account_vod__c  + '__' + busCall.Territory_vod__c;
                    String account = null;
                    for (Call2_vod__c childCall : busCall.Call2_vod__r) {
                        account = childCall.Account_vod__c;
                    }              
                    
                    if (account != null)
                        perfAccMap.put(key,account);
           }                                
            
                                           
                                           
             
            // locate TSF record types and account record type name         
            Map<String, TSF_vod__c> newTsfByTerr = new Map<String, TSF_vod__c>();           
            for ( AggregateResult results :  [Select Account_vod__c, Territory_vod__c, Count(Id) totCalls, max(Call_Date_vod__c) mcalldate
                                     From Call2_vod__c where Account_vod__c in :acctIds and Territory_vod__c in :terrInTsf                        
                                     AND Status_vod__c != 'Planned_vod'
                                     AND Call_Date_vod__c = THIS_YEAR
                                     AND Call_Date_vod__c <= TODAY
                                     GROUP BY Account_vod__c, Territory_vod__c ]) {
                    
                String territory = (String)results.get('Territory_vod__c');
                String accountid = (String)results.get('Account_vod__c');
                Date maxDate = (Date)results.get('mcalldate');
                Integer callsYTD = (Integer)results.get('totCalls');
                
                String key = accountid + '__' + territory;                                 
                if (territoryInTrans.contains (key) == false) 
                    continue;
                
                    
                TSF_vod__c tsf = tsfByTerr.get(key);
                if (tsf == null) {
                    tsf = newTsfByTerr.get(key);
                    if (tsf == null) {
                        tsf = new TSF_vod__c(YTD_Activity_vod__c = 0, Name = territory, Account_vod__c = accountid, Territory_vod__c = territory,
                                        External_Id_vod__c = key);
                        newTsfByTerr.put(key, tsf);
                    }
                }   
                tsf.Last_Activity_Date_vod__c  = maxDate;
                tsf.YTD_Activity_vod__c = callsYTD;
                String busAccount = perfAccMap.get(key);
                if (busAccount != null)
                   tsf.Preferred_Account_vod__c = busAccount;
                            
            }
            
            for (CallInfo newCall : calls) {        
                if (newCall.parentAddr != null && newCall.parentCall == null ) {
                    TSF_vod__c tsf = tsfByTerr.get(newCall.account + '__' + newCall.territory);
                    if (tsf == null)
                        tsf = newTsfByTerr.get(newCall.account + '__' + newCall.territory);
                    if (tsf != null)
                        tsf.Address_vod__c = newCall.parentAddr;
                }
            }         
                       
            if (tsfByTerr.size() > 0 ) {
                System.debug(tsfByTerr.values());
                try {
                    update tsfByTerr.values();
                } catch (DMLException e) { // ignore UNABLE_TO_LOCK_ROW
                    System.debug(e.getMessage()); 
                }
            }  
            
            if (newTsfByTerr.size() > 0 ) {
                // set record type for new TSF
                setTSFRecordType(newTsfByTerr.values());                
                System.debug(newTsfByTerr.values());
                try {
                    Database.upsert (newTsfByTerr.values(), TSF_vod__c.External_Id_vod__c, false);
                } catch (DMLException e) { // ignore the error, another process has added the TSF
                    System.debug(e.getMessage());                   
                }
            }                       
        }
        
    public static String writeCalls(Call2_vod__c[] calls, boolean isUpdate) {
        XmlStreamWriter writer = new XmlStreamWriter();
        writer.writeStartDocument(null, '1.0');
        writer.writeStartElement(null, 'calls', null);
        for (Call2_vod__c call : calls) {  
            if (call.Account_vod__c == null || call.Territory_vod__c == null || (!isUpdate && call.Status_vod__c == 'Planned_vod'))
                continue;
            writer.writeStartElement(null, 'call2_vod', null);
            writer.writeAttribute(null, null, 'account', call.Account_vod__c);
            writer.writeAttribute(null, null, 'territory', call.Territory_vod__c);
            if (call.Parent_Address_vod__c != null)
                writer.writeAttribute(null, null, 'parent_addr', call.Parent_Address_vod__c);
            if (call.Parent_Call_vod__c != null)
                writer.writeAttribute(null, null, 'parent_call', call.Parent_Call_vod__c);
             writer.writeAttribute(null, null, 'callid', call.Id);   
            writer.writeEndElement(); 
        }
        writer.writeEndElement();
        writer.writeEndDocument();
        String xmlOutput = writer.getXmlString();
        writer.close();
        return xmlOutput;
    }
            
    static List<CallInfo> parseCalls(String callsXmlDoc) {
        List<CallInfo> calls = new List<CallInfo>();
        XmlStreamReader reader = new XmlStreamReader(callsXmlDoc);
        while(reader.hasNext()) {
            reader.next();
            if (reader.getEventType() == XmlTag.START_ELEMENT) {
                if ('call2_vod' == reader.getLocalName()) {
                    calls.add(parseCall(reader));
                }
           } 
        }
        
        return calls;
    }
        
    // Parse each call
    static CallInfo parseCall(XmlStreamReader reader) {
        CallInfo call = new CallInfo();
       
        call.account = reader.getAttributeValue(null, 'account');
        call.territory = reader.getAttributeValue(null, 'territory');
        call.parentAddr = reader.getAttributeValue(null, 'parent_addr');
        call.parentCall = reader.getAttributeValue(null, 'parent_call');
        call.id = reader.getAttributeValue(null, 'callid');
        return call;
    }    
    
    class CallInfo {
        String id;
        String account;
        String territory;
        String parentAddr;
        String parentCall;
        String perfAcct;
    }
    
    // get TSF record types <name, ID> and default ID
    private static Boolean getTsfRecTypes(Map<String, ID> tsfRecTypes, List<ID> defRecType) {
        Boolean hasRecType = false;
        Schema.DescribeSObjectResult descTSF = TSF_vod__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> tsfFldMap = Schema.SObjectType.TSF_vod__c.fields.getMap();
        if (tsfFldMap.containsKey('RecordTypeId')) {
            hasRecType = true;
            for (RecordType recType : [Select Id, Name From RecordType Where SObjectType='TSF_vod__c' and IsActive=true]) {
                for (Schema.RecordTypeInfo info : descTSF.getRecordTypeInfos()) {
                    if ((info.getRecordTypeId() == recType.Id) &&
                            info.isAvailable()) {
                        tsfRecTypes.put(recType.Name, recType.Id);
                        if (info.isDefaultRecordTypeMapping())
                            defRecType.add(recType.Id);
                        break;
                    }
                }
            }
        }
        return hasRecType;
    }
    
        // set TSF record type   
    private static void setTSFRecordType(List<TSF_vod__c> newTSFs) {   
        if (newTSFs.size() == 0) 
            return;
            
        // find record types
        Map<String, ID> tsfRecTypes = new Map<String, ID>();
        List<ID> defRecType = new List<ID>();
        Boolean hasRecType = getTsfRecTypes(tsfRecTypes, defRecType);
        if (hasRecType) {
            Set<Id> acctIds = new Set<Id>();
            for (TSF_vod__c tsf : newTSFs)
               acctIds.add(tsf.Account_vod__c);
            // find accounts  
            Map<ID, Account> accts = new Map<ID, Account>([Select Id, RecordType.Name From Account Where Id In : acctIds]); 
            // update TSF record type with account record types
            for (TSF_vod__c tsf : newTSFs) {
                Account acct = accts.get(tsf.Account_vod__c);
                if (acct != null) {
                    String tsfRecType = tsfRecTypes.get(acct.RecordType.Name);
                    if (tsfRecType != null)
                       tsf.put('RecordTypeId', tsfRecType);
                    else if (defRecType.size() > 0)
                       tsf.put('RecordTypeId', defRecType.get(0));
                }
            }
        }       
    }
    
    public static void updateRecType (Set<String> acctIds) {
        if (System.isBatch() || System.isFuture()) {
            updateRecTypeNoFuture(acctIds);
        } else {
            updateRecTypeFuture(acctIds);
        }
    }
    
    @future
    public static void updateRecTypeFuture (Set<String> acctIds) {
        updateRecTypeNoFuture(acctIds);
    }
    
    public static void updateRecTypeNoFuture (Set<String> acctIds) {    
        System.debug('acctIds with recType change ' + acctIds);
        
        // get TSF record types for update
        Map<String, ID> tsfRecTypes = new Map<String, ID>();
        List<ID> defRecType = new List<ID>();
        Boolean hasRecType = getTsfRecTypes(tsfRecTypes, defRecType);
        System.debug(tsfRecTypes);
        if (!hasRecType)
            return;
        String defRecTypeId = (defRecType.size() > 0) ? defRecType.get(0) : null;
        Map<ID, Account> accts = new Map<ID,Account>([Select Id,RecordType.Name From Account Where Id In :acctIds]);
        
        // update    
        for (List<TSF_vod__c> tsfs : [Select Id, Account_vod__c, 
                   YTD_Activity_vod__c, Territory_vod__c From TSF_vod__c where Account_vod__c in :acctIds] ) {
            List<TSF_vod__c> toDelete = new List<TSF_vod__c>();
            List<TSF_vod__c> toInsert = new List<TSF_vod__c>();
            List<TSF_vod__c> toUpdate = new List<TSF_vod__c>();
            for (TSF_vod__c tsf : tsfs) {
                Account acct = accts.get(tsf.Account_vod__c);
                if (acct != null) {
                    String tsfRecType = tsfRecTypes.get(acct.RecordType.Name);                
                    if (tsfRecType == null) {
                        if (defRecTypeId != null) {
                           System.debug('tsf ' + tsf.id + ' new(def) ' + defRecTypeId);
                           tsf.put('RecordTypeId', defRecTypeId); 
                           toUpdate.add(tsf);
                        }
                        else {
                          System.debug('tsf ' + tsf.id + ' is cleared');
                          // use delete + insert in order to clear RecordTypeId
                          toDelete.add(tsf);  
                          TSF_vod__c newTsf = new TSF_vod__c(YTD_Activity_vod__c = tsf.YTD_Activity_vod__c, Name = tsf.Territory_vod__c, 
                                  Account_vod__c = acct.Id, Territory_vod__c = tsf.Territory_vod__c);         
                          toInsert.add(newTsf);                       
                        }                         
                    }  
                    else {
                       System.debug('tsf ' + tsf.id + ' new ' + tsfRecType);
                       tsf.put('RecordTypeId', tsfRecType);
                       toUpdate.add(tsf);   
                    }                                   
                }  
            }
            
            if (toDelete.size() > 0) 
                delete toDelete;
            if (toInsert.size() > 0)
                insert toInsert;
            if (toUpdate.size() > 0) 
                update tsfs;
        }                                  
    }
}