global with sharing class VEEVA_KeyMessageAccessChecker{
        
    /* handle user's access check for key message mapping in approved email
     * Return Map of three entries key of API names: Approved_Document_vod__c, Sent_Email_vod__c and Sent_Fragment_vod__c
     */  
    Global Map<String, Boolean> getUserAccessToKeyMessageForAE() {
        Map<String, Boolean> result = new Map<String, Boolean>();
        // Check Key_Message_vod__c exist in Approved_Document_vod__c
        Set<String> adObjectFields = Schema.SObjectType.Approved_Document_vod__c.fields.getMap().keySet();
        Boolean isViewable = adObjectFields.contains('key_message_vod__c');
        result.put('Approved_Document_vod__c', isViewable);  
        // Check Key_Message_vod__c editable in Sent_Email_vod__c and Sent_Fragment_vod__c
        Map<String, Schema.SObjectField> seMap = Schema.SObjectType.Sent_Email_vod__c.fields.getMap();
        try {
            if (seMap.get('Key_Message_vod__c').getDescribe().isUpdateable()) {
                result.put('Sent_Email_vod__c', true);
            }
            else {
                result.put('Sent_Email_vod__c', false);
            }
        }
        catch (Exception e) {
            result.put('Sent_Email_vod__c', false);
        }
        
        Map<String, Schema.SObjectField> sfMap = Schema.SObjectType.Sent_Fragment_vod__c.fields.getMap();
        try {
            if (sfMap.get('Key_Message_vod__c').getDescribe().isUpdateable()) {
                result.put('Sent_Fragment_vod__c', true);
            }
            else {
                result.put('Sent_Fragment_vod__c', false);
            }
        }
        catch (Exception e) {
            result.put('Sent_Fragment_vod__c', false);
        }
        return result;
    }
}