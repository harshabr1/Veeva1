/* This class must run with administrator access.  User's sharing rules should not be applied. */
global class VOD_ProcessATL_Asyn {
    @future
    public static void processATL (String loadersXmlDoc, Set<Id> acctIds, boolean extendATLMode) {
        List<Account_Territory_Loader_vod__c> loaders = parse(loadersXmlDoc);
        VOD_ProcessATL.processATL(loaders, acctIds, extendATLMode);
    }
       
    public static String write(List<Account_Territory_Loader_vod__c> loaders) {
        XmlStreamWriter writer = new XmlStreamWriter();
        writer.writeStartDocument(null, '1.0');
        writer.writeStartElement(null, 'loaders', null);
        for (Account_Territory_Loader_vod__c loader : loaders) {      
            writer.writeStartElement(null, 'loader', null);
            writer.writeAttribute(null, null, 'acct', loader.Account_vod__c);
            if(loader.Territory_vod__c != null) {
            	writer.writeAttribute(null, null, 'territory', loader.Territory_vod__c);
            }
            if(loader.Territory_To_Add_vod__c != null) {
            	writer.writeAttribute(null, null, 'territory_to_add', loader.Territory_To_Add_vod__c);
            }
            if(loader.Territory_To_Drop_vod__c != null) {
            	writer.writeAttribute(null, null, 'territory_to_drop', loader.Territory_To_Drop_vod__c);
            }
            writer.writeEndElement();
        }
        writer.writeEndElement();
        writer.writeEndDocument();
        String xmlOutput = writer.getXmlString();
        writer.close();
        return xmlOutput;
    }
            
    static List<Account_Territory_Loader_vod__c> parse(String xmldoc) {
        Account_Territory_Loader_vod__c[] loaders = new List<Account_Territory_Loader_vod__c>();
        XmlStreamReader reader = new XmlStreamReader(xmldoc);
        while(reader.hasNext()) {
            reader.next();
            if (reader.getEventType() == XmlTag.START_ELEMENT) {
                if ('loader' == reader.getLocalName()) {
                    String acct = reader.getAttributeValue(null, 'acct');   
                    String terr = reader.getAttributeValue(null, 'territory');
                    String terr_to_add = reader.getAttributeValue(null, 'territory_to_add');
                    String terr_to_drop = reader.getAttributeValue(null, 'territory_to_drop');
                    Account_Territory_Loader_vod__c loader = new Account_Territory_Loader_vod__c(Account_vod__c=acct, 
                    	Territory_vod__c=terr,Territory_To_Add_vod__c=terr_to_add,Territory_To_Drop_vod__c=terr_to_drop);
                    loaders.add(loader);
                }
           } 
        }
        return loaders;
    }
}