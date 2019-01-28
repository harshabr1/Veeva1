trigger VEEVA_MULTICHANNEL_ACTIVITY_LINE_AFTER_UPSERT on Multichannel_Activity_Line_vod__c (after update, after insert, after delete) {
    Set<id> parentIds = new set<id>();
    List<Multichannel_Activity_Line_vod__c> inputMAL = null;
    if (trigger.isInsert || trigger.isUpdate ) {
        inputMAL = trigger.new;
    } else if ( trigger.isDelete ) {
        inputMAL = trigger.old;
    }
    
    for(Multichannel_Activity_Line_vod__c mac : inputMAL) {
      parentIds.add(mac.Multichannel_Activity_vod__c);  
    }
    List<AggregateResult> durations = [SELECT Multichannel_Activity_vod__c parentId,
                                       sum(Duration_vod__c) totalDuration 
                                       FROM Multichannel_Activity_Line_vod__c 
                                       WHERE Multichannel_Activity_vod__c in :parentIds 
                                       group by Multichannel_Activity_vod__c];
    if (!durations.isEmpty() && durations.size() > 0 ) {
        List<Multichannel_Activity_vod__c> listMCA = new List<Multichannel_Activity_vod__c>();
        for(AggregateResult ar : durations ) {
            Decimal duration = (Decimal)ar.get('totalDuration');
            id parentId = (id)ar.get('parentId');
            Multichannel_Activity_vod__c parentMAC = new Multichannel_Activity_vod__c (id=parentId);
            parentMAC.Total_Duration_vod__c = duration;
            listMCA.add(parentMAC);  
        }
        update listMCA;
    }  
}