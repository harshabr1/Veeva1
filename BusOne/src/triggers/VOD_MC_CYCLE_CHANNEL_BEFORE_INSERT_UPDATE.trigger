trigger VOD_MC_CYCLE_CHANNEL_BEFORE_INSERT_UPDATE on MC_Cycle_Channel_vod__c (before insert, before update) {

    for(MC_Cycle_Channel_vod__c channel: Trigger.new){
        Id cycleId = channel.Cycle_vod__c;
        String channelObject = channel.Channel_Object_vod__c;
        String channelLabel = channel.Channel_Label_vod__c;
        if(cycleId != null && channelObject != null){
            channel.VExternal_Id_vod__c = cycleId + '__' + channelObject + '__' + channelLabel;
        }
    }

}