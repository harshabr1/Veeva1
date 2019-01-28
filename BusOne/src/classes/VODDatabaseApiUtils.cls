global with sharing class VODDatabaseApiUtils {
    
    public static void processObjectTag(Xmlstreamreader xmlReader, Set<String> vodIds, Map<String, Set<String>> dependentMap,
                                         Map<String, VodObject> vodObjMap, List<VodObject> vodObjs) {
        VodObject vObject = createVodObject(xmlReader);
        Set<String> parentIds = new Set<String>();
        
        // loop on the children of the OBJECT
        while (xmlReader.hasNext()) {
            xmlReader.next();
            if (xmlReader.isEndElement() && xmlReader.getLocalName() == 'OBJECT') {
                vodObjMap.put(vObject.m_objectid, vObject);
                vodIds.add(vObject.m_objectid);
                break;
            }   
            if (xmlReader.isStartElement() &&  xmlReader.getLocalName() == 'FIELD') {
                modifyVodObject(xmlReader, parentIds, vodIds, vObject);
            }                       
        }
        
        vodObjs.add(vObject);
        if (parentIds.size() == 0) { // ready for DML
            vObject.m_ready = true;
        }
        else {
            addChildIds(vObject.m_objectid, parentIds, dependentMap);
        }
    }
    
    public static VodObject createVodObject(Xmlstreamreader xmlReader) {
        String uri = xmlReader.getNamespace();                   
        String action = xmlReader.getAttributeValue(uri, 'action');
        String objectid = xmlReader.getAttributeValue(uri, 'id');
        String name = xmlReader.getAttributeValue(uri, 'name');
        String upsertField = xmlReader.getAttributeValue(uri, 'upsertField');
        return new VodObject (name,objectid,action,upsertField);
    }
    
    public static void modifyOptionsHolder(Xmlstreamreader xmlReader, UpsertOptionsHolder upsertVarHolder) {
        String fldUri = xmlReader.getNamespace();                   
        String withShare = xmlReader.getAttributeValue(fldUri, 'withShare');     
        String useDMLOpt = xmlReader.getAttributeValue(fldUri, 'useDMLOpt'); 
        if (withShare != null) { //null check is needed here, incase package is applied and old codebase is used            
            upsertVarHolder.upsertWithShare = Boolean.valueOf(withShare);
            if (useDMLOpt != null) {
                upsertVarHolder.upsertWithDMLOption = Boolean.valueOf(useDMLOpt);
            }  
        }   
    }
    
    public static void modifyVodObject(XmlstreamReader xmlReader, Set<String> parentIds, Set<String> vodIds, VodObject vObject) {
        String fldUri = xmlReader.getNamespace();
        String fldName = xmlReader.getAttributeValue(fldUri, 'name'); 
        String fldType = xmlReader.getAttributeValue(fldUri, 'type');
        String fldValue = xmlReader.getAttributeValue(fldUri, 'value');
        String fldRefObjectName = xmlReader.getAttributeValue(fldUri, 'refObjectName');
        String fldRefFieldName = xmlReader.getAttributeValue(fldUri, 'refFieldName'); 
        String[] splits = fldValue.split('@');
        if (splits.size() > 1 && vodIds.contains(splits[1])) {
            parentIds.add(splits[1]); 
        }
        VodField fld = new VodField(fldName, fldType, fldValue, fldRefObjectName, fldRefFieldName);
        vObject.m_fieldList.put(fld.m_name, fld);
    }
    
    public static void addChildIds(String objectId, Set<String> parentIds, Map<String, Set<String>> dependentMap) {
        // map of parent to children
        for (String parentId : parentIds) {                       
            Set<String> childIds = dependentMap.get(parentId);
            if (childIds == null) {
                childIds = new Set<String>();
                dependentMap.put(parentId, childIds);
            } 
            childIds.add(objectId);
        }
    }
    
    public class VodField { 
        String m_name;
        String m_fldType;
        String m_value;
        String m_refObjectName;
        String m_refFieldName;
        
        @TestVisible VodField(String name, String fldType, String value, String refObjectName, String refFieldName) {
            m_name = name;
            m_fldType = fldType;
            m_value = value;    
            m_refObjectName = refObjectName;
            m_refFieldName = refFieldName;
        }
        
        
        public String getName() {
            return m_name;
        }
        
        public String getfldType() {
            return m_fldType;
        }
        
        public String getValue() {
            return m_value;
        }
        
        public void setValue(String value) {
            m_value = value;
        }
        
        public String getRefObjectName() {
            return m_refObjectName;
        }
        
        public String getRefFieldName() {
            return m_refFieldName;
        }
        
        public Boolean equals(VodField obj) {
            return strEqWithNull(m_name, obj.m_name) && strEqWithNull(m_fldType, obj.m_fldType) &&
                strEqWithNull(m_value, obj.m_value) && strEqWithNull(m_refObjectName, obj.m_refObjectName) &&
                strEqWithNull(m_refFieldName, obj.m_refFieldName);
        }
    }
    
    public class VodObject {
        String m_action; 
        String m_objectid;
        String m_name;
        String m_upsertField;
        Boolean m_ready;
        
        Map <String,VodField> m_fieldList = new Map <String,VodField>();
    
        @TestVisible VodObject(String name, String objectid, string action, String upsertField) {
            m_action = action; 
            m_objectid = objectid;
            m_name = name;
            m_upsertField = upsertField;
            m_ready = false;
        }
        
        public String getAction() {
            return m_action;
        }
        
        public String getObjectId() {
            return m_objectid;
        }
        
        public String getName() {
            return m_name;
        }
        
        public String getupsertField() {
            return m_upsertField;
        }
        
        public VodField getField(String fldName) {
            return m_fieldList.get(fldName);
        }
        
        public Map<String,VodField> getFieldList() {
            return m_fieldList;
        }
        
        public void putField(String key, VodField val) {
            m_fieldList.put(key, val);
        }
        
        public boolean isReady() {
            return m_ready;
        }
        
        public void setReady(boolean ready) {
            m_ready = ready;
        }        
        
        public Boolean equals(VodObject obj) {
            for (String key : m_fieldList.keySet()) {
                VodField thisFld = m_fieldList.get(key);
                System.debug('this is m_fieldList: ' + m_fieldList);
                System.debug('this is obj.m_fieldList: ' + obj.m_fieldList);
                VodField objFld = obj.m_fieldList.get(key);
                
                return (objFld == null && thisFld == null) ||
                    (thisFld != null && thisFld.equals(objFld));
            }
            
            return strEqWithNull(m_action, obj.m_action) && strEqWithNull(m_objectid, obj.m_objectid) &&
                strEqWithNull(m_name, obj.m_name) && strEqWithNull(m_upsertField, obj.m_upsertField) &&
                ((m_ready && obj.m_ready) || (!m_ready && !obj.m_ready));
        }
    }
    
    public static Boolean strEqWithNull(String str1, String str2) {
        return (str1 == null && str2 == null) || (str1 != null && str1.equals(str2));
    }
	
    public static ID getValidId(String recordId) {
        try {
            return ID.valueOf(recordId);
        } catch (System.StringException e) {
            return null;
        }
    }	
    
    Global With Sharing class UpsertOptionsHolder {
        // this will hold if Upsert need to be invoked with Share or not.
        // basically get the value from withShare attribute of transaction element 
        boolean upsertWithShare = true;
        // this holds if any DMLOpt will be used. useDMLOpt attribute value is set to this var 
        boolean upsertWithDMLOption = true;
        
        public boolean isUpsertWithShare() {
            return upsertWithShare;
        }
        
        public boolean isUpsertWithDMLOption() {
            return upsertWithDMLOption;
        }
    }
    
}