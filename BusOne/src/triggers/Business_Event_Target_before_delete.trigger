trigger Business_Event_Target_before_delete on Business_Event_Target_vod__c (before delete) {
    if (VEEVA_BUSINESS_EVENT_TARGET_TRIG.invoked)
    {
        return;
    }
    VEEVA_BUSINESS_EVENT_TARGET_TRIG.invoked = true;
    
    for (Business_Event_Target_vod__c bet : Trigger.old)
    {
        List<Call_Objective_vod__c> callObjs =
            [select Id, Completed_Flag_vod__c
             from Call_Objective_vod__c
             where Business_Event_Target_vod__c = :bet.Id];
             
        if (callObjs.size() > 0)
        {        
            for (Call_Objective_vod__c callObj : callObjs)
            {
                if (callObj.Completed_Flag_vod__c)
                {
                    bet.addError((bet.Name + ' ' + VOD_GET_ERROR_MSG.getErrorMsg('CALL_COMPLETED','BusinessEvent')), false);
                    return;
                }
            }            
            
            // skip call objective triggers
            VEEVA_CALL_OBJECTIVE_TRIG.invoked = true;
            delete(callObjs);
        }
    }    
}