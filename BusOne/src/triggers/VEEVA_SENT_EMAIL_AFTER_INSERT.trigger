trigger VEEVA_SENT_EMAIL_AFTER_INSERT on Sent_Email_vod__c (after insert) {
    VEEVA_KeyMessageAccessChecker keyMsgChecker = new VEEVA_KeyMessageAccessChecker();
    Map<String, Boolean> keyMsgAccessMap = keyMsgChecker.getUserAccessToKeyMessageForAE();
    Boolean allowMapKeyMsg = keyMsgAccessMap.get('Approved_Document_vod__c') && keyMsgAccessMap.get('Sent_Fragment_vod__c');

    // if the email is of type "Events_Management_vod" store all event id and template id
    RecordType EMRecordType = [SELECT Id FROM RecordType WHERE SobjectType='Sent_Email_vod__c' AND DeveloperName = 'Events_Management_vod'];
    Map<Id, Set<Id>> eventIdToTemplateIdsMap = new Map<Id, Set<Id>>();
    Set<Id> allTemplateIds = new Set<Id>();
    Set<String> allFragmentIds = new Set<String>();

    // build all the necessary maps and sets
    for (Sent_Email_vod__c se : trigger.new){
        // get all template id
        allTemplateIds.add(se.Approved_Email_Template_vod__c);
        // get all fragment ids
        String fragments = se.Email_Fragments_vod__c;
        if(fragments != null) {
            allFragmentIds.addAll(fragments.split(','));
        }
        // if the sent email is sent from an event
        if(EMRecordType != null && se.RecordTypeId == EMRecordType.id) {
            // build the event-id-to-template-id map
            // these fields must be there if this Sent Email is of type Event_Management_vod
            if(eventIdToTemplateIdsMap.containsKey(se.Event_vod__c)) {
                // existing event, put the template in the template id set (will not store duplicate)
                eventIdToTemplateIdsMap.get(se.Event_vod__c).add(se.Approved_Email_Template_vod__c);
            }
            else {
                // new event, put template id in new set and store the entry in the map
                Set<Id> newTemplateIdList = new Set<Id>();
                newTemplateIdList.add(se.Approved_Email_Template_vod__c);
                eventIdToTemplateIdsMap.put(se.Event_vod__c, newTemplateIdList);
            }
        }
    }

    // get all the fragments approved document
    Map<Id, Approved_Document_vod__c> fragmentMap = new Map<Id, Approved_Document_vod__c>([SELECT Id, Key_Message_vod__c, Key_Message_vod__r.Name FROM Approved_Document_vod__c WHERE Id =: allFragmentIds]);

    // get all the key messages in the fragments
    Map<Id, Key_Message_vod__c> keyMsgMap = new Map<Id, Key_Message_vod__c>();
    for(Approved_Document_vod__c doc : fragmentMap.values()) {
        keyMsgMap.put(doc.Key_Message_vod__c, doc.Key_Message_vod__r);
    }

    // created new Sent_Fragment_vod objects that lookup to the email template and email fragments sent out
    List<Sent_Fragment_vod__c> sentFragments = new List<Sent_Fragment_vod__c>();
    for (Sent_Email_vod__c se : trigger.new){
        Id templateID = se.Approved_Email_Template_vod__c; 
        String fragments = se.Email_Fragments_vod__c;
        if(fragments != null){
            String[] fragmentList = fragments.split(',');
            for(String fragmentId: fragmentList){
                Sent_Fragment_vod__c fragment = new Sent_Fragment_vod__c();
                try {
                    fragment.Sent_Fragment_vod__c = fragmentId;
                    fragment.Email_Template_vod__c = templateID;
                    fragment.Sent_Email_vod__c = se.Id;
                    fragment.Account_vod__c = se.Account_vod__c;
                    // Update key message if available in fragment
                    if (allowMapKeyMsg) {
                        Approved_Document_vod__c apprDoc = fragmentMap.get(fragmentId);
                        if (apprDoc.Key_Message_vod__c != NULL) {

                            Id keyMsgId = apprDoc.Key_Message_vod__c;
                            Key_Message_vod__c keyMsg = keyMsgMap.get(keyMsgId);
                            if (keyMsg != null) {
                                fragment.Key_Message_vod__c = keyMsgId;
                            }
                        }
                    }
                    sentFragments.add(fragment);
                }catch( Exception e ) {
                   continue;
                }
            }
        }
    }

    // create the sent fragments at once outside the for-loop (to avoid too many DML statements: 151 exception)
    try {
        insert sentFragments;
    } catch( Exception e ) {
        System.debug(':::Fail to insert Sent_Fragment_vod__c objects, cause: ' + e.getMessage());
    }

    // if at lease one sent email is sent from event
    if(eventIdToTemplateIdsMap.size() > 0) {
        try {
            // store all event materials that need to be updated
            List<EM_Event_Material_vod__c> toUpdate = new List<EM_Event_Material_vod__c>();

            // get all event materials where event_vod_c is in the list eventIds and email_template_vod__c is in eventTemplateIds
            Set<Id> allEventIds = eventIdToTemplateIdsMap.keySet();
            List<EM_Event_Material_vod__c> materials = [SELECT Id, Event_vod__c, Email_Template_vod__c, Material_Used_vod__c FROM EM_Event_Material_vod__c WHERE Event_vod__c IN: allEventIds AND Email_Template_vod__c IN: allTemplateIds];

            if(materials != null){
                // loop through all materials and update the matching ones
                for(EM_Event_Material_vod__c mat : materials) {
                    if(eventIdToTemplateIdsMap.get(mat.Event_vod__c).contains(mat.Email_Template_vod__c)) {
                        mat.Material_Used_vod__c = true;
                        toUpdate.add(mat);
                    }
                }
            }

            // update
            update toUpdate;
        }
        catch (Exception e){
            System.debug(':::Fail to update EM_Event_Material_vod__c.Material_Used_vod__c');
        }
    }


}