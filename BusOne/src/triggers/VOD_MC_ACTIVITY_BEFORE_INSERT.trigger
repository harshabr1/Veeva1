trigger VOD_MC_ACTIVITY_BEFORE_INSERT on Multichannel_Activity_vod__c(before insert) {
    
    if(Schema.sObjectType.Multichannel_Activity_vod__c.fields.Territory_vod__c.isCreateable() && (Schema.sObjectType.Sent_Email_vod__c.fields.Territory_vod__c.isAccessible() || Schema.sObjectType.Call2_vod__c.fields.Territory_vod__c.isAccessible())){

        Set<Id> sentEmailIds = new Set<Id>();
        Set<Id> callIds = new Set<Id>();
        for(Multichannel_Activity_vod__c mca: Trigger.new){
            if(mca.Territory_vod__c == null){
                if(mca.Sent_Email_vod__c != null){
                    sentEmailIds.add(mca.Sent_Email_vod__c);
                }
                else if(mca.Call_vod__c != null){
                    callIds.add(mca.Call_vod__c );  
                }
            }
        }
        
        
        Map<Id, Sent_Email_vod__c> sentEmails;
        if(sentEmailIds.size() > 0){
            sentEmails = new Map<Id, Sent_Email_vod__c>([Select Id, Territory_vod__c FROM Sent_Email_vod__c WHERE Id IN :sentEmailIds]);
        }
        else{
            sentEmails = new Map<Id, Sent_Email_vod__c>();
        }
        
        Map<Id, Call2_vod__c> calls;
        if(callIds.size() > 0){
            calls = new Map<Id, Call2_vod__c>([Select Id, Territory_vod__c FROM Call2_vod__c WHERE Id IN :callIds]);
        }
        else{
            calls = new Map<Id, Call2_vod__c>();
        }
        
        for(Multichannel_Activity_vod__c mca: Trigger.new){
            if(mca.Territory_vod__c == null){
                if(mca.Sent_Email_vod__c != null){
                    Sent_Email_vod__c se = sentEmails.get(mca.Sent_Email_vod__c);
                    mca.Territory_vod__c = se.Territory_vod__c;
                }
                else if(mca.Call_vod__c != null){
                    Call2_vod__c call = calls.get(mca.Call_vod__c);
                    mca.Territory_vod__c = call.Territory_vod__c;
                }
            }            
        }
        
    
    }

}