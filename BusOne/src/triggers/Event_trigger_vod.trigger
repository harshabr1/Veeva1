trigger Event_trigger_vod on Event bulk (before update, before delete,after update, after delete) {
            if (VOD_CALL_TO_CALENDAR.getCallTrig() == true)
                    return;
                
                VOD_CALL_TO_CALENDAR.setCalendarTrig(true);
            
            
            
            RecordType recType = [Select Id from RecordType where SobjectType = 'Event' and Name = 'Call_vod'];
        
            if (Trigger.isBefore)  {
                if (Trigger.isUpdate || Trigger.isDelete) {
                    List <String> ids = new List<String>();
                    for (Event es : Trigger.old) {
                        ids.add(es.WhatId);
                    }
                
                
                    Map <Id, Call2_vod__c> callMap = new    Map <Id, Call2_vod__c> ([Select Id, Status_vod__c from Call2_vod__c where Id in :ids]);
                
                
                    for (Integer k = 0; k < Trigger.old.size (); k++) {
                        Call2_vod__c call = callMap.get(Trigger.old[k].WhatId);
                        if (call != null) {
                            if (recType.Id == Trigger.old[k].RecordTypeId)  {
                                    if (call.Status_vod__c == 'Submitted_vod')  {
                                        if (Trigger.isUpdate) 
                                            Trigger.new[k].Id.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_EVE','TriggerError'), false);
                                        else
                                            Trigger.old[k].Id.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_EVE','TriggerError'), false);
                                    } else if ( call.Status_vod__c == 'Saved_vod') {
                                        if (Trigger.isDelete) {
                                            Trigger.old[k].Id.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_EVE_INPROG','TriggerError'), false);
                                        }
                                    }
                            }
                        }
                    }
                }
            } else {
        
                List<Call2_vod__c> callList = new List<Call2_vod__c>();
                List<Call2_vod__c> delList = new List<Call2_vod__c>();
                Event [] newEvents = Trigger.new;
                Event [] oldEvents = Trigger.old;
            
          
               for (Integer i = 0; i < (Trigger.isDelete ? Trigger.old.size(): Trigger.new.size()); i++)    {
                    String recId = Trigger.isDelete ? oldEvents[i].RecordTypeId:newEvents[i].RecordTypeId;
                    if (recType.Id  == recId ) {
                        if (Trigger.isUpdate) { 
                            if (newEvents[i].ActivityDateTime == oldEvents[i].ActivityDateTime && newEvents[i].ActivityDate == oldEvents[i].ActivityDate )
                                continue;
                    }
                    
                    String id = Trigger.isDelete ? oldEvents[i].WhatId : newEvents[i].WhatId;
                
                    if (Trigger.isUpdate) { 
                       
                        Integer callCount = [Select Count() from Call2_vod__c where ID =:id];
                       Date cDate = null;
                        if (callCount > 0) {
                          if (newEvents[i].ActivityDateTime != null )
                              cDate = Date.newInstance (newEvents[i].ActivityDateTime.year(), 
                                                        newEvents[i].ActivityDateTime.month(),
                                                        newEvents[i].ActivityDateTime.day());
                          else 
                              cDate = System.today();
                          Call2_vod__c call = new Call2_vod__c (Id = newEvents[i].WhatId,
                                                                   Call_Datetime_vod__c= newEvents[i].ActivityDateTime,
                                                                   Call_Date_vod__c = cDate);
                                                            
                           callList.add(call);
                        }
                    }
                   if (Trigger.isDelete) {
                          Integer callCount = [Select Count() from Call2_vod__c where ID =:id and Status_vod__c = 'Planned_vod'];
                  
                       if (callCount > 0) {
                          Call2_vod__c delCall = new Call2_vod__c (Id = oldEvents[i].WhatId);
                          delList.add(delCall);
                        }
                   }
                } 
            }
            try {
            if (callList.size() > 0)
               update callList;
            if (delList.size() > 0)
               delete delList;
               
            }    catch (System.DmlException e) {
                        if (Trigger.isDelete) {
                            Trigger.old[0].Id.addError (VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_EVE','TriggerError'), false);
                        }
                        if (Trigger.isUpdate) {
                            Trigger.new[0].Id.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_EVE','TriggerError'), false);
                        }
            }
            }
         }