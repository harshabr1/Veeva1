trigger VOD_CALL2_AFTER_DELETE_TRIGGER on Call2_vod__c (after delete) {
    String str = VOD_ProcessTSF.writeCalls(Trigger.old, false);
    if (str.indexOf('call2_vod') != -1)
        VOD_ProcessTSF.processTSF(str);
    List<Call2_vod__c> calls = new List<Call2_vod__c>();
    if (VEEVA_CYCLE_PLAN_REALTIME_CALC.isEnableRealTimeCC()) {
        for (Integer i = 0 ; i < Trigger.old.size(); i++) {
            Call2_vod__c call = Trigger.old[i];
            if (call.Account_vod__c == null || call.Call_Date_vod__c == null || call.Territory_vod__c == null)
                continue;
            calls.add(call);
        }
        VEEVA_CYCLE_PLAN_REALTIME_CALC.invokeCalculation(calls);
    }

    if (!VEEVA_CALL_OBJECTIVE_TRIG.objectives.isEmpty()) {
        update VEEVA_CALL_OBJECTIVE_TRIG.objectives;
    }
}