// VODDatabaseApi presumes that no objects are dependent of objects behind them,
// and objects are committed to DB on request order.

global with sharing class VODDatabaseApi {
    
    static Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
    static Map<String, List<SObject>> newListMap = new Map<String, List<SObject>>();
    WebService static String process(String xml) {
        String output = '';
        if (xml == null || xml.length() == 0)
            return output;
        // System.debug(xml);
        Map<String, VODDatabaseApiUtils.VodObject> vodObjMap = new Map<String, VODDatabaseApiUtils.VodObject>();
        Map<String, Set<String>> dependentMap = new Map<String, Set<String>>();
        VODDatabaseApiUtils.UpsertOptionsHolder upsertVarHolder = new VODDatabaseApiUtils.UpsertOptionsHolder();
        List<VODDatabaseApiUtils.VodObject> vodObjs = parseDocument(xml, dependentMap, vodObjMap, upsertVarHolder);
        if (vodObjs.size() == 0)
            return output;               
        Savepoint sp = Database.setSavepoint();          
        try {       
            output = processVodObjects(vodObjs, sp, dependentMap, vodObjMap, upsertVarHolder); 
            System.debug(output);
            return output;
            }
        catch (System.DmlException  e) { 
            output ='err;;;E;;;';        
            for (Integer i = 0; i < e.getNumDml(); i++) 
                output += e.getDmlMessage(i) + '; ';
            Database.rollback(sp);
            return output; 
        }
        catch(DBException e) {
            output = 'err;;;E;;;' + e.getMessage();
            Database.rollback(sp);
            return output;
        }
        catch (System.Exception e) {
            output = 'err;;;E;;;' + e.getMessage();
            Database.rollback(sp);
            return output;
        }
    }
   
    //  1) perform DML on objects with all dependents resolved
    //  2) call updateDependents to resolve their child objects
    private static String processVodObjects(List<VODDatabaseApiUtils.VodObject> vodObjs, 
                            Savepoint sp, Map<String, Set<String>> dependentMap, 
                            Map<String, VODDatabaseApiUtils.VodObject> vodObjMap, VODDatabaseApiUtils.UpsertOptionsHolder upsertVarHolder) {
            
        if (vodObjs.size() == 0)
            return '';
        Map<String, String> sfIdMap = new Map<String, String>();   
        Set<String> allParentIds = dependentMap.keySet();
        Set<String> parentIds = new Set<String>();
        String output = '';
        
        // collect objects ready to be committed in a group
        List<SObject> readySObjects = null;
        List<String> readyVodIds = new List<String>();
        Set<String> readySObjIds = new Set<String>();
        String action = null;
        String typeName = null;
        Schema.SObjectField upsertField = null;
        String listType = null;
        
        // process VodObject in order
        for (VODDatabaseApiUtils.VodObject vObj : vodObjs) {                             
            // group SObjects ready to be committed
            boolean added = addToGroup(readySObjects, readyVodIds, readySObjIds, 
                        action, upsertField, typeName, vObj, allParentIds, parentIds);
                                    
            if (!added) {
                if (readySObjects != null) {                    
                    // commit SObjects collected so far
                    output += updateDB(readyVodIds, readySObjects, action, typeName, upsertField, sfIdMap, upsertVarHolder);     
                    if (parentIds.size() > 0) {
                        updateDependents(parentIds, dependentMap, vodObjMap, sfIdMap);  
                    } 
                    readySObjects = null;
                    readySObjIds.clear();
                    readyVodIds.clear();
                    parentIds.clear();
                }
                
                // start a new group                                    
                List<SObject> newList = newListMap.get(vObj.getName());
                if (newList == null) {
                    // workaround for creating List<SObject>
                    String objectName = String.escapeSingleQuotes(vObj.getName()); // CRM-45716
                    newList = Database.query('select id from ' + objectName + ' limit 0');
                   
                    newListMap.put(vObj.getName(), newList);
                }
                readySObjects = newList.clone();   
                action = vObj.getAction();
                typeName = vObj.getName();
                // Set upsertField if it's been provided and isn't 'Id' (which is the default and in lots of copied and pasted code)
                if (vObj.getUpsertField() != null && vObj.getUpsertField().length() > 0 && (!(vObj.getUpsertField() == 'Id'))) {             
                    Schema.SObjectType sObjectType = gd.get(typeName);
                    upsertField = sObjectType.getDescribe().fields.getMap().get(vObj.getUpsertField());                    
                } else {
                    upsertField = null;
                }
                addToGroup(readySObjects, readyVodIds, readySObjIds, action, upsertField, typeName, 
                            vObj, allParentIds, parentIds);
            }
            
            if (!vObj.isReady())
                throw new DBException('not all objects can be committed to DB');           
        } 
        
        if (readySObjects != null)   
            output += updateDB(readyVodIds, readySObjects, action, typeName, upsertField, sfIdMap, upsertVarHolder); 
                       
        return output;
    }  
    
    private static String updateDB(List<String> vodIds, List<SObject> sObjs, String action, 
                                   String typeName, Schema.SObjectField upsertField,   
                                Map<String, String> sfIdMap, VODDatabaseApiUtils.UpsertOptionsHolder upsertVarHolder) {
        if (sObjs.size() ==0)
            return ''; // no op
        if (action == 'INS')
            return doInsert(vodIds, sObjs, sfIdMap);
        else if (action == 'UPD')
            return doUpdate(vodIds, sObjs, sfIdMap);
        else if (action == 'UPS')
            return doUpsert(vodIds, sObjs, sfIdMap, typeName, upsertField, upsertVarHolder);
        else if (action == 'DEL')
            return doDelete(vodIds, sObjs); 
        return ''; // no op                             
    }           
   
    private static String doInsert(List<String> vodIds, List<SObject> sObjects, 
                            Map<String, String> sfIdMap) {
        String output = '';
        List<Database.Saveresult> results = Database.insert(sObjects, true);  
        Integer i = 0;
        for (Database.Saveresult sr : results) {
            if (sr.isSuccess()) {            	
            	output += vodIds.get(i) + ';;;S;;;' + sr.getId() + ';;;C' + '<--->';            	
                sfIdMap.put(vodIds.get(i), sr.getId());                            
            } else {
                output = '';
                for (Database.Error err: sr.getErrors()) {
                    output += err.getMessage() + '; ';
                }
                throw new DBException(output);
            }
            i++;
        }
        return output;       
    }
   
    private static String doUpdate(List<String> vodIds, List<SObject> sObjects, 
                                Map<String, String> sfIdMap) {
        String output = '';
        List<Database.Saveresult> results = Database.update(sObjects, true);  
        Integer i = 0;
        for (Database.Saveresult sr : results) {
            if (sr.isSuccess()) {
                output += vodIds.get(i) + ';;;S;;;' + sr.getId() + '<--->'; 
                sfIdMap.put(vodIds.get(i), sr.getId());                               
            } else {
                output = '';
                for (Database.Error err: sr.getErrors()) {
                    output += err.getMessage() + '; ';
                }
                throw new DBException(output);
            }
            i++;
        }
        return output;       
   }
   
   private static String doUpsert(List<String> vodIds, List<SObject> sObjects,  
                                  Map<String, String> sfIdMap, String typeName, Schema.SObjectField upsertField, VODDatabaseApiUtils.UpsertOptionsHolder upsertVarHolder) {
        String output = '';
        List<Database.Upsertresult> results;     
        boolean upsertWithShare = upsertVarHolder.isUpsertWithShare();     
        boolean upsertWithDMLOpt = upsertVarHolder.isUpsertWithDMLOption(); 
        List<SObject>  resultSObjs = null;      
        if (upsertField != null) {
            // Database.upsert that includes external id field won't compile with List<SObject> even with API version 36, it results in
            // "Upsert requires a concrete SObject type" error.  Based on 
            // http://salesforce.stackexchange.com/questions/61340/is-it-possible-to-upsert-a-listsobject-with-external-id-specified?lq=1
            // and
            // http://salesforce.stackexchange.com/questions/64988/apex-cast-sobject-list-dynamically-to-a-specific-sobject-type
            // there doesn't seem to be a usable workaround other than manually figuring out whether it should be insert versus update OR
            // using concrete types.
            // For now, manually supporting the 3 objects that are used by network integration.
            if (upsertWithShare == true) {
            	// These 3 method names (doUpsertAccounts,doUpsertAddresses,doUpsertChildAccounts)are different but contents are same as in 
            	// methods in UpsertWithoutSharing(upsertAccounts,upsertAddresses,upsertChildAccounts) class.it seems Apex expects 
            	// unique method name across outer class.
	            if ('Account'.equals(typeName)) {
	                results = doUpsertAccounts(sObjects, upsertField);
	            } else if ('Address_vod__c'.equals(typeName)) {
	            	results = doUpsertAddresses(sObjects, upsertField);
	            } else if ('Child_Account_vod__c'.equals(typeName)) {
	            	results = doUpsertChildAccounts(sObjects, upsertField);
	            } else {
	            	throw new DBException('Upsert with upsertField not supported for type ' + typeName + ', it needs to be manually added: ' + 'Upsert requires a concrete SObject type');
	            }   
            }else {
            	//If the upsertWithShare is false. execute upsert methods without share. lil duplicate code as above but couldn't get around it.
            	UpsertWithoutSharing upsertWithoutShare = new UpsertWithoutSharing();
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.allowFieldTruncation = true;
	            if ('Account'.equals(typeName)) {
	                results = upsertWithoutShare.upsertAccounts(sObjects, upsertField, dml);
	            } else if ('Address_vod__c'.equals(typeName)) {
	            	results = upsertWithoutShare.upsertAddresses(sObjects, upsertField, dml);
	            } else if ('Child_Account_vod__c'.equals(typeName)) {
	            	results = upsertWithoutShare.upsertChildAccounts(sObjects, upsertField, dml);
	            } else {
	            	throw new DBException('Upsert with upsertField not supported for type ' + typeName + ', it needs to be manually added: ' + 'Upsert requires a concrete SObject type');
	            }       
            }
                 
        } else {        	
        	if (upsertWithShare == true) {
        		results = Database.upsert(sObjects, true);        		
        	}else {
        		UpsertWithoutSharing upsertWithoutShare = new UpsertWithoutSharing();
        		//here we are allowing to upsert without Share.
        		if (upsertWithDMLOpt) {		
            		resultSObjs = upsertWithoutShare.doUpsertWithDMLOpt(sObjects);
        		}else {
            		results = upsertWithoutShare.doUpsert(sObjects);
        		}
        	}
        }        
        Integer i = 0;
        // if upsert is done with DMLOptions , means it is using upsert keyword, hence the Ids will be in SObject. 
        // we will not be able to know if create / update so C /U will not be appended to the output.
        if (upsertWithDMLOpt) {
	        for(SObject sObj : resultSObjs) {
	        	output += vodIds.get(i) + ';;;S;;;' + sObj.get('Id') +'<--->';
	        	String sId = (String)sObj.get('Id');
	        	sfIdMap.put(vodIds.get(i), sId);
	        	i++;
	        }
        }else {
	        for (Database.Upsertresult sr : results) {
	            if (sr.isSuccess()) {            	
	            		if (sr.isCreated()) {
	            			output += vodIds.get(i) + ';;;S;;;' + sr.getId() + ';;;C' + '<--->';
	            		}else {
	            			output += vodIds.get(i) + ';;;S;;;' + sr.getId() + ';;;U' +'<--->';
	            		}            	
	                sfIdMap.put(vodIds.get(i), sr.getId());                               
	            } else {
	                output = '';
	                for (Database.Error err: sr.getErrors()) {
	                    output += err.getMessage() + '; ';
	                }
	                throw new DBException(output);
	            }
	            i++;
	        }
        }
        return output;
    }

    private static List<Database.Upsertresult> doUpsertAccounts(List<SObject> sObjects, Schema.SObjectField upsertField) {
	    List<Account> accountList = new List<Account>();
	    for (SObject s : sObjects) {
	    	Account a = (Account)s;
	    	accountList.add(a);
	    }
	    return Database.upsert(accountList, upsertField, true);
   	}
    
	private  static List<Database.Upsertresult> doUpsertAddresses(List<SObject> sObjects, Schema.SObjectField upsertField) {
	    List<Address_vod__c> addressList = new List<Address_vod__c>();
	    for (SObject s : sObjects) {
	    	Address_vod__c a = (Address_vod__c)s;
	    	addressList.add(a);
	    }
	    return Database.upsert(addressList, upsertField, true);
	}
    
	private  static List<Database.Upsertresult> doUpsertChildAccounts(List<SObject> sObjects, Schema.SObjectField upsertField) {
	    List<Child_Account_vod__c> childAccountList = new List<Child_Account_vod__c>();
	    for (SObject s : sObjects) {
	    	Child_Account_vod__c a = (Child_Account_vod__c)s;
	    	childAccountList.add(a);
	    }
	    return Database.upsert(childAccountList, upsertField, true);
	}
	
    private static String doDelete(List<String> vodIds, List<SObject> sObjects) {
        String output = '';
        List<Database.Deleteresult> results = Database.delete(sObjects, true);  
        Integer i = 0;
        for (Database.Deleteresult sr : results) {
            if (sr.isSuccess()) {
                output += vodIds.get(i) + ';;;S;;;<--->';                              
            } else {
                output = '';
                for (Database.Error err: sr.getErrors()) {
                    output += err.getMessage() + '; ';
                }
                throw new DBException(output);
            }
            i++;
        }
        return output;
    }
   
    // collect a group of objects ready to be committed
    private static boolean addToGroup(List<SObject> readySObjects, List<String> readyVodIds,
                                Set<String> readySObjIds, 
                                String action, Schema.SObjectField upsertField, String typeName, VODDatabaseApiUtils.VodObject vObj, 
                                Set<String> allParentIds, Set<String> parentIds) 
    {
        if (readySObjects == null || !vObj.isReady())
           return false;   
        if (vObj.getAction() != action || vObj.getName() != typeName)
           return false;
        if (readySObjects.size() == 200) //govenor limit
           return false;
        
        // construct SObject 
        Schema.SObjectType objType = gd.get(vObj.getName());
        if (objType == null) 
            return true; //no op
        
        if (upsertField != null) {
            Schema.SObjectField currentUpsertField = null;
            if (vObj.getUpsertField() != null && (!(vObj.getUpsertField() == 'Id'))) {
                currentUpsertField = objType.getDescribe().fields.getMap().get(vObj.getUpsertField());
            }
            if (upsertField != currentUpsertField) {
                return false;
            }
        } else if (vObj.getUpsertField() != null && (!(vObj.getUpsertField() == 'Id'))) {
            return false;
        }
            
        String idValue = null;
        VODDatabaseApiUtils.VodField idField = vObj.getField('Id');
 
        if (idField != null) 
            idValue = idField.getValue();
        
        SObject sObj = null;
        if ('INS' != vObj.getAction() && idValue != null && idValue.length() > 0) {
            if (readySObjIds.contains(idValue))
                return false;
            readySObjIds.add(idValue); 
            sObj = objType.newSObject(idValue);
        } else {
            sObj = objType.newSObject(); 
        }
                       
        for (VODDatabaseApiUtils.VodField vField : vObj.getFieldList().values()) {
            if (vField.getName() == 'Id')
                continue;                       
            addField (vField, sObj);
        }
           
        readySObjects.add(sObj);
        readyVodIds.add(vObj.getObjectId());
        if (action != 'DEL' && allParentIds.contains(vObj.getObjectId()))
            parentIds.add(vObj.getObjectId());                 
        return true;           
   }       
                
    private static void updateDependents (Set<String> parentVodIds, 
                            Map<String, Set<String>> dependentMap, 
                            Map<String, VODDatabaseApiUtils.VodObject> vodObjMap, Map<String, String> sfIdMap) 
    {
        Map<String, String> nameMap = new Map<String, String>();
        Set<String> resolved = new Set<String>();
        for (String parent : parentVodIds) {        
            String searchId = '@' + parent + '@';
            String searchIdName = '@' + parent + '@NAME@';
            String sfId = sfIdMap.get(parent);    
    
            for (String dependentId : dependentMap.get(parent)) {
                VODDatabaseApiUtils.VodObject vObj = vodObjMap.get(dependentId);
                for (VODDatabaseApiUtils.VodField vField : vObj.getFieldList().values()) {
                    String value = vField.getValue();
                    if (value == searchId) {
                        vField.setValue(sfId);
                    }
                    if (value == searchIdName) {
                        String Name = nameMap.get(sfId);
                        if (Name == null) {
                            // CRM-45716 - cleaning the inputs to prevent SOQL injection
                            String objectName = String.escapeSingleQuotes(vodObjMap.get(parent).getName());
                            String sfIdClean = String.escapeSingleQuotes(sfId);
                            sObject S = Database.query('SELECT ID, NAME FROM ' + objectName + ' WHERE ID =\'' + sfIdClean + '\'');
                            if (S != null) {
                                String sName = (String)S.get('Name');
                                nameMap.put(sfId, sName);
                                Name = sName;
                            }
                        }
                        vField.setValue(Name);
                    }
                }               
            }
            resolved.addAll(dependentMap.get(parent));
            dependentMap.remove(parent);
        }
        
        // find VodObjects ready to be processed
        Set<String> allDependents = new Set<String>();
        for (Set<String> ids : dependentMap.values())
           allDependents.addAll(ids);
        resolved.removeAll(allDependents);
        for (String id : resolved) 
           vodObjMap.get(id).setReady(true);    
    }
 
    private static List<VODDatabaseApiUtils.VodObject> parseDocument(String xml, 
            Map<String, Set<String>> dependentMap, Map<String, VODDatabaseApiUtils.VodObject> vodObjMap, VODDatabaseApiUtils.UpsertOptionsHolder upsertVarHolder) {
        
        List<VODDatabaseApiUtils.VodObject> vodObjs = new List<VODDatabaseApiUtils.VodObject>();  
        Set<String> vodIds = new Set<String>();       
        Xmlstreamreader xmlReader = new Xmlstreamreader(xml);
        while(xmlReader.hasNext()) {
            // Start at the beginning of the book and make sure that it is a book
            if (xmlReader.isStartElement()) {                
                if ('TRANSACTIONS' == xmlReader.getLocalName()) {
                    VODDatabaseApiUtils.modifyOptionsHolder(xmlReader, upsertVarHolder);             
                }
                if ('OBJECT' == xmlReader.getLocalName()) {
                    VODDatabaseApiUtils.processObjectTag(xmlReader, vodIds, dependentMap, vodObjMap, vodObjs);
                }           
            }
                
            if (xmlReader.hasNext())
                xmlReader.next();               
        }
        System.debug(dependentMap);
        return vodObjs;            
    }
    
    private static void addField(VODDatabaseApiUtils.VodField vField, SOBject sobj) {
        String fldType = vField.getFldType();
        String value = vField.getValue();
        String name = vField.getName();
        
         if ('_boolean' == fldType || 'boolean' == fldType) {
            boolean b = false;                   
            if ('true'.equalsIgnoreCase(value)) {
                b = true;
            }
            sobj.put(name,b);
            return;
        }
        
         if (value == null || value.length() == 0) {
                sobj.put(name,null);
                return;
         }
        
        if ('date' == fldType) {
            Date dt = Date.valueOf(value);
            sobj.put(name,dt);
        } else if ('datetime' == fldType) {
            if (value == null || value.length() == 0)
            return;
            Long l = Long.valueOf(value);
            Datetime dtm = Datetime.newInstance(l);     
            sobj.put(name,dtm); 
        } else if ('_double' == fldType || 'double' == fldType || 'currency' == fldType ) {
            Double d = Double.valueOf(value);
            sobj.put(name,d);   
        }  else if ('_long' == fldType || 'long' == fldType) {
            Long l = Long.valueOf(value);
            sobj.put(name,l);   
        }  else if ('_int' == fldType || 'int' == fldType) {
            Integer i = Integer.valueOf(value);
            sobj.put(name,i);   
        }  else if ('percent' == fldType || '_precent' == fldType) {
            Double d = Double.valueOf(value);
            sobj.put(name,d);
        }  else if ('reference' == fldType) {
            String refObjectName = vField.getRefObjectName();
            String refFieldName = vField.getRefFieldName();
            if (refObjectName != null && refObjectName.length() > 0 && refFieldName != null && refFieldName.length() > 0) {
                // External id reference to another object
                Schema.SObjectType refObjectType = gd.get(refObjectName);
                SObject refObject = refObjectType.newSObject();
                refObject.put(refFieldName, value);
                sobj.putSObject(name, refObject);
            } else {
                sobj.put(name, value);
            }          
        }  else {
            sobj.put(name,value);
        }       
    }
    
    class DBException extends Exception {}
    
    private static Schema.DescribeSObjectResult getDescribeResult(String objectName)
    {
        Schema.DescribeSObjectResult toReturn = null;
        Schema.SObjectType obj = gd.get(objectName);
        if (obj != null) {
            Schema.DescribeSObjectResult describe = obj.getDescribe();
            if (describe.isAccessible()) {
                toReturn = describe;
            }
        }
        return toReturn;
    }
    
    private static boolean hasSurveyAccess()
    {
        Schema.DescribeSObjectResult describe = getDescribeResult('Survey_vod__c');
        return describe != null && describe.isCreateable() && describe.isUpdateable() && describe.IsDeletable();
    }
    
    private static boolean hasSurveyQuestionAccess()
    {
        Schema.DescribeSObjectResult describe = getDescribeResult('Survey_Question_vod__c');
        return describe != null && describe.isCreateable() && describe.isUpdateable();
    }
    
    private static boolean hasQuestionAccess()
    {
        Schema.DescribeSObjectResult describe = getDescribeResult('Question_vod__c');
        return describe != null;
    }    
    
    private static boolean hasProductAccess()
    {
        Schema.DescribeSObjectResult describe = getDescribeResult('Product_vod__c');
        return describe != null;
    }
    
    Webservice static String addSharingForSurvey(String[] userOrGroupIds, String parentId) {
        // Check for access
        if (hasSurveyAccess() && hasSurveyQuestionAccess() && hasQuestionAccess() && hasProductAccess()) {
            updateSurveyShare surveyShare = new updateSurveyShare();
            return surveyShare.updateShares(userOrGroupIds, parentId);
        }
        return 'ERROR:Missing Object Permissions' + 
                (!hasSurveyAccess() ? ';;Survey(View,Create,Update,Delete)' : '') + 
                (!hasSurveyQuestionAccess() ? ';;SurveyQuestion(View,Create,Update)' : '') +
                (!hasQuestionAccess() ? ';;Question(View)' : '') +
                (!hasProductAccess() ? ';;Product(View)' : '');
    }
    
    Global Without Sharing class updateSurveyShare {
        public String updateShares(String[] userOrGroupIds, Id surveyId) {
            String output = '';
            boolean error = false;
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Survey_vod__Share');
            if (targetType != null) {
                String searchQuery = 'SELECT Id FROM Survey_vod__Share WHERE ParentId = :surveyId AND RowCause = \'VEEVA_ADVANCED_SHARE_vod__c\'';       
                List<SObject> listOfShares = Database.query(searchQuery);
                if (listOfShares.size() > 0) {
                    Database.delete(listOfShares);
                }
                listOfShares.clear();          
            	for (String userOrGroupId : userOrGroupIds) {
                	SObject cs = targetType.newSObject();
                	cs.put('RowCause', 'VEEVA_ADVANCED_SHARE_vod__c');
                	cs.put('AccessLevel', 'Read');
                	cs.put('UserOrGroupId', userOrGroupId);
                	cs.put('ParentId', surveyId);
                	listOfShares.add(cs);
            	}
            	Database.SaveResult[] results = Database.insert(listOfShares, true);
            
            	
            	Integer i = 0;
            	
            	for (Database.SaveResult sr : results) {
                	if (sr.isSuccess()) {
                    	output += ';;;S;;;' + sr.getId() + '<--->';                             
                	} else {
                    	output = '';
                    	for (Database.Error err: sr.getErrors()) {
                        	output += err.getMessage() + '; ';
                    	}
                    	error = true;
                    	throw new DBException(output);
                	}
                	i++;
            	}
            	
            } else {
                error = true;
                output = 'Survey_vod__Share not available, check Sharing rules';
            }
            return (error ? 'ERROR;;' : 'SUCCESS;;') + output;
        }
    }
    
    Global Without Sharing class UpsertWithoutSharing {    	
    	private  List<Database.Upsertresult> upsertAccounts(List<SObject> sObjects, Schema.SObjectField upsertField, Database.DMLOptions dml) {
		    List<Account> accountList = new List<Account>();
		    for (SObject s : sObjects) {
		    	Account a = (Account)s;
		    	a.setOptions(dml);
		    	accountList.add(a);
		    }
		    return Database.upsert(accountList, upsertField, true);
   		}
    
	    private  List<Database.Upsertresult> upsertAddresses(List<SObject> sObjects, Schema.SObjectField upsertField, Database.DMLOptions dml) {
		    List<Address_vod__c> addressList = new List<Address_vod__c>();
		    for (SObject s : sObjects) {
		    	Address_vod__c a = (Address_vod__c)s;
		    	a.setOptions(dml);
		    	addressList.add(a);
		    }
		    return Database.upsert(addressList, upsertField, true);
	    }
    
	    private  List<Database.Upsertresult> upsertChildAccounts(List<SObject> sObjects, Schema.SObjectField upsertField, Database.DMLOptions dml) {
		    List<Child_Account_vod__c> childAccountList = new List<Child_Account_vod__c>();
		    for (SObject s : sObjects) {
		    	Child_Account_vod__c a = (Child_Account_vod__c)s;
		    	a.setOptions(dml);
		    	childAccountList.add(a);
		    }
		    return Database.upsert(childAccountList, upsertField, true);
	    }
	    private  List<Database.UpsertResult> doUpsert(List<SObject> sObjects) {	    	
	    	return Database.upsert(sObjects,true);	    	
	    }
	    // execute upsert with few DMLOptions
	    private  List<SObject> doUpsertWithDMLOpt(List<SObject> sObjects) {	  
	    	Database.DMLOptions dml = new Database.DMLOptions();
	    	try{
			    dml.optAllOrNone = true;
			    dml.allowFieldTruncation = true;
		    	for (SObject s : sObjects) {
		    		s.setOptions(dml);
		    	}
		    	upsert sObjects;	
	    	}catch (DmlException e) {
	    		String errorMessage ='';
	    		for (Integer i = 0; i < e.getNumDml(); i++) {
	                    errorMessage += e.getDmlMessage(i) + '; ';
	            }
	            if (String.isNotBlank(errorMessage) && errorMessage.endsWith('; ')) {
	            	errorMessage = errorMessage.removeEnd('; ');
	            }
	    		throw new DBException(errorMessage);
	    	}  
	    	return sObjects;  	
	    }
    }
}