trigger VOD_COACHING_REPORT_BEFORE_INSUPD_TRIGGER on Coaching_Report_vod__c ( before insert, before update) {
    if(VEEVA_PROCESS_FLAGS.getUpdateCR()== true){
        return;
    }
    
    
    for (Integer i = 0 ; i < Trigger.new.size(); i++) 
    {
       if (Trigger.new[i].Employee_vod__c != null ) 
         {
             Trigger.new[i].OwnerId = Trigger.new[i].Employee_vod__c;
         }
    }
}