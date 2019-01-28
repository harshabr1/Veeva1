trigger Business_Event_Target_after_upsert on Business_Event_Target_vod__c (after insert, after update) {
    if (VEEVA_BUSINESS_EVENT_TARGET_TRIG.holders.size() == 0)
    {
        return;
    }
            
    List<Call_Objective_vod__c> newCallObjs = new List<Call_Objective_vod__c>();
    for (VEEVA_BUSINESS_EVENT_TARGET_TRIG.CallObjectiveHolder holder : VEEVA_BUSINESS_EVENT_TARGET_TRIG.holders)
    {
        holder.callObj.Business_Event_Target_vod__c = Trigger.new[holder.trig_idx].Id;
        newCallObjs.add(holder.callObj);
    }
    
    // skip call objective triggers
    VEEVA_CALL_OBJECTIVE_TRIG.invoked = true;
    insert(newCallObjs);
}