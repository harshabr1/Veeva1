trigger VEEVA_MULTICHANNEL_ACTIVITY_AFTER_INSERT on Multichannel_Activity_vod__c (after insert) {

    Set<id> callIds = new set<id>();
    Set<id> medicalEventIds = new set<id>();
    Set<id> eventAttendeeIds = new set<id>();
    Map<id,List<Multichannel_Activity_vod__c>> MCAMAP1 = new Map<id,List<Multichannel_Activity_vod__c>>(); 
    Map<id,List<Multichannel_Activity_vod__c>> MCAMAP2 = new Map<id,List<Multichannel_Activity_vod__c>>();
    Map<id,List<Multichannel_Activity_vod__c>> MCAMAP3 = new Map<id,List<Multichannel_Activity_vod__c>>();
    List<Multichannel_Activity_vod__c> inputMA = trigger.new;
 
    if ( inputMA != null && inputMA.size() > 0 ) {
  
        List<Multichannel_Activity_vod__c> tmpMAList1 = null;
        List<Multichannel_Activity_vod__c> tmpMAList2 = null;
        List<Multichannel_Activity_vod__c> tmpMAList3 = null;
        
        for(Multichannel_Activity_vod__c mac : inputMA) {
        
            // Find associated Call Ids
            if ( mac.Call_vod__c != null ) {
                callIds.add(mac.Call_vod__c); 
                tmpMAList1 = MCAMAP1.get(mac.Call_vod__c);
                
                if ( tmpMAList1 == null ) {
                    tmpMAList1 = new List<Multichannel_Activity_vod__c>();
                }
                tmpMAList1.add(mac);
                MCAMAP1.put(mac.Call_vod__c, tmpMAList1);
            }

            // Find associated Medical Event Ids
            if ( mac.Medical_Event_vod__c != null ) {
                medicalEventIds.add(mac.Medical_Event_vod__c); 
                tmpMAList2 = MCAMAP2.get(mac.Medical_Event_vod__c);
                
                if ( tmpMAList2 == null ) {
                    tmpMAList2 = new List<Multichannel_Activity_vod__c>();
                }
                tmpMAList2.add(mac);
                MCAMAP2.put(mac.Medical_Event_vod__c, tmpMAList2);
            }

            // Find associated Event Attendee Ids
            if ( mac.Event_Attendee_vod__c != null ) {
                eventAttendeeIds.add(mac.Event_Attendee_vod__c);
                tmpMAList3 = MCAMAP3.get(mac.Event_Attendee_vod__c);

                if( tmpMAList3 == null ) {
                    tmpMAList3 = new List<Multichannel_Activity_vod__c>();
                }
                tmpMAList3.add(mac);
                MCAMAP3.put(mac.Event_Attendee_vod__c, tmpMAList3);
            }
        }
    }

    // Update fields in Call object for the given Call Ids
    if ( callIds != null && callIds.size() > 0 ) { 
         List<Call2_vod__c> calls = [ SELECT id, Owner.id ,Cobrowse_MC_Activity_vod__c
                                         FROM Call2_vod__c 
                                         WHERE id in :callIds
                                         and Status_vod__c != 'Submitted_vod'
                                       ];                      
         List<Call2_vod__c> callToUpdate = null;
         List<Multichannel_Activity_vod__c> mcaToUpdate = null;
         if ( calls != null && calls.size() > 0 ) {
               
             callToUpdate = new List<Call2_vod__c>();
             List<Multichannel_Activity_vod__c> MCAList = null; 
             
             for (Call2_vod__c call: calls ) {
                 MCAList = MCAMAP1.get(call.id);   
                 if ( MCAList != null && MCAList.size() > 0 ) {
                     for(Multichannel_Activity_vod__c MCA:MCAList) {   //for every activity, stamping owner id from call.
                        Multichannel_Activity_vod__c tmca = new Multichannel_Activity_vod__c(id=MCA.id);
                        tmca.Organizer_vod__c = call.Owner.id;
                        if ( mcaToUpdate == null ) {
                            mcaToUpdate = new List<Multichannel_Activity_vod__c>();
                        }
                        mcaToupdate.add(tmca);
                     } 
                     if ( call.Cobrowse_MC_Activity_vod__c == null ) {
                         for(Multichannel_Activity_vod__c mavc: MCAList) {
                             if (mavc.Account_vod__c != null ) {
                                 call.Cobrowse_MC_Activity_vod__c = mavc.id;
                                 if ( callToUpdate == null ) {
                                    callToupdate = new List<Call2_vod__c>();
                                 }
                                 callToUpdate.add(call);
                                 break;
                             }
                         }        
                    }
                 }               
             }
             
             if (callToUpdate != null && callToUpdate.size() > 0) {
                update callToUpdate;
             }
             
             if (mcaToUpdate != null && mcaToUpdate.size() > 0 ) {
                update mcaToUpdate;
             }
         }
    }

    // Update fields in Medical Event object for the given Medical Event Ids
    if ( medicalEventIds != null && medicalEventIds.size() > 0 ) { 
         List<Medical_Event_vod__c> medicalEvents = null;
         boolean hasOwner = Schema.getGlobalDescribe().get('Medical_Event_vod__c').getDescribe().fields.getMap().keySet().contains('ownerid');

         if(hasOwner) {
            String eventIdStr = '';
         
         	for (String eid : medicalEventIds) {
            	if (eventIdStr.length() > 0) {
                	eventIdStr += ',';
            	}
            	eventIdStr += '\'' + eid + '\'';
         	}
         	
         	medicalEvents = Database.query('SELECT id, ownerid, Cobrowse_MC_Activity_vod__c FROM Medical_Event_vod__c WHERE Id IN('+ eventIdStr + ')');
         } else {
            medicalEvents = [ SELECT id, Cobrowse_MC_Activity_vod__c
                                         FROM Medical_Event_vod__c 
                                         WHERE id in :medicalEventIds
                            ];         
         }
         
         List<Multichannel_Activity_vod__c> mcaToUpdate = null;                     
         List<Medical_Event_vod__c> medicalEventToUpdate = null;

         if ( medicalEvents != null && medicalEvents.size() > 0 ) {
               
             medicalEventToUpdate = new List<Medical_Event_vod__c>();
             List<Multichannel_Activity_vod__c> MCAList = null; 
             
             for (Medical_Event_vod__c medicalEvent : medicalEvents ) {
                 MCAList = MCAMAP2.get(medicalEvent.id);   
                 if ( MCAList != null && MCAList.size() > 0 ) {

                     if(hasOwner) {
                         for(Multichannel_Activity_vod__c MCA : MCAList) {   //for every activity, stamping owner id from Medical Event.
                            Multichannel_Activity_vod__c tmca = new Multichannel_Activity_vod__c(id = MCA.id);
                            tmca.Organizer_vod__c = (Id)medicalEvent.get('ownerid');
                            if ( mcaToUpdate == null ) {
                                mcaToUpdate = new List<Multichannel_Activity_vod__c>();
                             }
                             mcaToUpdate.add(tmca);
                         }                        
                     }

                     if ( medicalEvent.Cobrowse_MC_Activity_vod__c == null ) {
                         medicalEvent.Cobrowse_MC_Activity_vod__c = MCAList.get(0).id;
                         medicalEventToUpdate.add(medicalEvent);
                     }
                 }               
             }
             
             if (mcaToUpdate != null && mcaToUpdate.size() > 0 ) {
                update mcaToUpdate;
             }

             if (medicalEventToUpdate != null && medicalEventToUpdate.size() > 0) {
                update medicalEventToUpdate;
             }
         }
    } 

    // Update fields in Event Attendee object for the given Event Attendee Ids
    if ( eventAttendeeIds != null && eventAttendeeIds.size() > 0 ) {
        List<Event_Attendee_vod__c> eventAttendees = [ SELECT id, Cobrowse_MC_Activity_vod__c, Status_vod__c
                                                FROM Event_Attendee_vod__c
                                                WHERE id in :eventAttendeeIds
                                            ];
        RecordType cobrowseRecordType =
            [SELECT id, DeveloperName FROM RecordType WHERE
            SobjectType='Multichannel_Activity_vod__c' AND DeveloperName='Cobrowse_vod'];

        List<Event_Attendee_vod__c> eventAttendeeToUpdate = null;

        if ( eventAttendees != null && eventAttendees.size() > 0 ) {

            eventAttendeeToUpdate = new List<Event_Attendee_vod__c>();
            List<Multichannel_Activity_vod__c> MCAList = null;

            for ( Event_Attendee_vod__c eventAttendee : eventAttendees ) {
                MCAList = MCAMAP3.get(eventAttendee.id);
                if( MCAList != null && MCAList.size() > 0 ) {
                    if ( eventAttendee.Cobrowse_MC_Activity_vod__c == null ) {

                        for (Multichannel_Activity_vod__c mcActivity : MCAList) {
                            // Loop through each mc activity, if there is any cobrowse activity,
                            // then give its id to Cobrowse_MC_Activity_vod__c.
                            // Otherwise Cobrowse_MC_Activity_vod__c remains null
                            if (mcActivity.RecordTypeId == cobrowseRecordType.id) {
                                eventAttendee.Cobrowse_MC_Activity_vod__c = mcActivity.id;
                                if ( eventAttendee.Status_vod__c != 'Attended' ) {
                                    eventAttendee.Status_vod__c = 'Attended';
                                }
                                break;
                            }
                        }
                    }

                    eventAttendeeToUpdate.add(eventAttendee);
                }
            }

            if(eventAttendeeToUpdate != null && eventAttendeeToUpdate.size() > 0) {
                update eventAttendeeToUpdate;
            }
        }
    }

}