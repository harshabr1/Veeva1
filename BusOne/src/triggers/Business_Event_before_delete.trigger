trigger Business_Event_before_delete on Business_Event_vod__c (before delete) {
    for (Business_Event_vod__c be : Trigger.old)
    {
        List<Call_Objective_vod__c> callObjs =
            [select Id, Completed_Flag_vod__c
             from Call_Objective_vod__c
             where Business_Event_vod__c = :be.Id];
        
        for (Call_Objective_vod__c callObj : callObjs)
        {
            if (!callObj.Completed_Flag_vod__c)
            {
                continue;
            }

            be.addError((be.Name + ' ' + VOD_GET_ERROR_MSG.getErrorMsg('CALL_COMPLETED','BusinessEvent')), false);
            return;        
        }
        
        List<Business_Event_Target_vod__c> busEvnts =
            [select Id
             from Business_Event_Target_vod__c
             where Business_Event_vod__c = :be.Id];
     
        if (callObjs.size() > 0)
        {
            // delete Call Objective             
            VEEVA_CALL_OBJECTIVE_TRIG.invoked = true;
            delete(callObjs);
        }        

        if (busEvnts.size() > 0)
        {
            // delete Business Event        
            VEEVA_BUSINESS_EVENT_TARGET_TRIG.invoked = true;
            delete(busEvnts);
        }
    } 
}