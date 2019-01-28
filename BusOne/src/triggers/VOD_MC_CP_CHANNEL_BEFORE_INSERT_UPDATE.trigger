trigger VOD_MC_CP_CHANNEL_BEFORE_INSERT_UPDATE on MC_Cycle_Plan_Channel_vod__c (before insert, before update) {
    Map<Id, Map<MC_Cycle_Plan_Channel_vod__c, String>> mapOfTragetToChannelsAndEditGoal = new Map<Id, Map<MC_Cycle_Plan_Channel_vod__c, String>>();
    Set<MC_Cycle_Plan_Target_vod__c> cyclePlanTragetListToUpdate = new Set<MC_Cycle_Plan_Target_vod__c>();
    Boolean populatingGoalEdit = false;
    Boolean blankingGoalEdit = false;
    
    String POPULATE = 'POPULATE';
    String NULLIFY = 'NULLIFY';
    String BOTH = 'BOTH';
  
    String profileId = Userinfo.getProfileId();
    Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :profileId];
    boolean profileModAllData = false;
    if (pr != null){
        profileModAllData = pr.PermissionsModifyAllData;
    }

    User user = new Map<Id,User>([Select MCCP_Admin_vod__c from User where User.Id=:Userinfo.getUserId()]).get(Userinfo.getUserId());
    boolean isMccpAdmin = user.MCCP_Admin_vod__c;

    List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='MCCP_LOCK_MSG' AND Category_vod__c='Multichannel' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    String errorText;
    if(messages.size() != 0){
        errorText = messages[0].Text_vod__c;
    }
    else{
        errorText = 'You do not have sufficient privileges to edit or delete a locked cycle plan.';
    }  
    List<Id> targetIds = new List<Id>();
    List<Id> channelIds = new List<Id>();
    
    for(MC_Cycle_Plan_Channel_vod__c channel: Trigger.new){              
        targetIds.add(channel.Cycle_Plan_Target_vod__c);
        channelIds.add(channel.Id);
        
        Decimal oldActivityGoalEditValue = null;
        Decimal oldTeamActivityGoalEditValue = null;
    
        //if there is any change detected between old and new objects 
        if(Trigger.oldMap != null){
            oldActivityGoalEditValue = Trigger.oldMap.get(channel.Id).Activity_Goal_Edit_vod__c;
            oldTeamActivityGoalEditValue = Trigger.oldMap.get(channel.Id).Team_Activity_Goal_Edit_vod__c;
        }
        if((oldActivityGoalEditValue != channel.Activity_Goal_Edit_vod__c) || (oldTeamActivityGoalEditValue != channel.Team_Activity_Goal_Edit_vod__c)){
             if(channel.Activity_Goal_Edit_vod__c != null || channel.Team_Activity_Goal_Edit_vod__c != null) {
                populatingGoalEdit = true;
            }
            if((oldActivityGoalEditValue != null && channel.Activity_Goal_Edit_vod__c == null) || 
                 (oldTeamActivityGoalEditValue != null && channel.Team_Activity_Goal_Edit_vod__c == null) ){
                    blankingGoalEdit = true;
            }
            if(mapOfTragetToChannelsAndEditGoal.containsKey(channel.Cycle_Plan_Target_vod__c)){
                //defensive logic - if same channel is added in data load file 
                Map<MC_Cycle_Plan_Channel_vod__c, String> mapOfChannelsWithGoalEdit  = mapOfTragetToChannelsAndEditGoal.get(channel.Cycle_Plan_Target_vod__c);
                mapOfChannelsWithGoalEdit.put(channel, checkPopulateOrBlankify(populatingGoalEdit, blankingGoalEdit));
            }
            else{
                //check logic and add at channel level 
                Map<MC_Cycle_Plan_Channel_vod__c, String> mapOfChannelsWithGoalEdit = new Map<MC_Cycle_Plan_Channel_vod__c, String>();
                mapOfChannelsWithGoalEdit.put(channel, checkPopulateOrBlankify(populatingGoalEdit, blankingGoalEdit));
                mapOfTragetToChannelsAndEditGoal.put(channel.Cycle_Plan_Target_vod__c, mapOfChannelsWithGoalEdit);
            }
        }       
    }
    //new function for adding logic at the channel level to update target object
    String checkPopulateOrBlankify(Boolean populating, Boolean blanking){
        if(populatingGoalEdit && blankingGoalEdit){
            return BOTH;
        }
        else if(populatingGoalEdit){
            return POPULATE;
        }
        return NULLIFY;
    }
    
    //populate list of target ids and channel ids 
    AggregateResult[] totalChannels= null;
    AggregateResult[] totalProducts = null;
    
    Map<Id, Integer> mapOfCyclePlanChannelsConnectedToTarget = new Map<Id,Integer>();
    Map<Id, Integer> mapOfCyclePlanProductConnectedToChannelAndTarget  = new Map<Id,Integer>();
    
    if(targetIds != null && targetIds.size() > 0 && channelIds != null && channelIds.size() > 0){ 
        totalChannels = [select Cycle_Plan_Target_vod__c, count(Id) cnt From MC_Cycle_Plan_Channel_vod__c where Cycle_Plan_Target_vod__c IN:targetIds and Id NOT IN:channelIds and (Activity_Goal_Edit_vod__c != null or Team_Activity_Goal_Edit_vod__c != null ) group by Cycle_Plan_Target_vod__c];
        totalProducts = [select Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__c targetId, count(Id) cnt from MC_Cycle_Plan_Product_vod__c where Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__c IN:targetIds and (Activity_Goal_Edit_vod__c != null or Team_Activity_Goal_Edit_vod__c != null ) group by Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__c];
        
        for(AggregateResult ar : totalChannels){
            mapOfCyclePlanChannelsConnectedToTarget.put(Id.valueOf(String.valueOf(ar.get('Cycle_Plan_Target_vod__c'))), Integer.valueOf(ar.get('cnt')));
        }
        
         for(AggregateResult ar : totalProducts ){
            mapOfCyclePlanProductConnectedToChannelAndTarget.put(Id.valueOf(String.valueOf(ar.get('targetId'))), Integer.valueOf(ar.get('cnt')));
        }
    }
             
     //loop through all channels and decide which target will be updated 
    List<MC_Cycle_Plan_Target_vod__c> targets = new List<MC_Cycle_Plan_Target_vod__c>([Select Id, Goals_Edited_vod__c From MC_Cycle_Plan_Target_vod__c where Id = :targetIds]);
    for(MC_Cycle_Plan_Target_vod__c target : targets ){
        
        //check the size of the map that has values from database shows other connections to the target 
        if((mapOfCyclePlanChannelsConnectedToTarget != null && mapOfCyclePlanChannelsConnectedToTarget.get(target.Id) > 0) || 
                (mapOfCyclePlanProductConnectedToChannelAndTarget != null && mapOfCyclePlanProductConnectedToChannelAndTarget.get(target.Id) > 0)){
           
           //existing connection found - do not turn the flag off  
            if(target.Goals_Edited_vod__c == false){
                target.Goals_Edited_vod__c = true;
                cyclePlanTragetListToUpdate.add(target);
            }
            continue;
        }
        //no data in database which has any values in GE and TGE in any channel or product for this target  
        else{
            //goalEdit at target will be false          
            boolean goalEdit = false;
            
            //take decision to update the target level flag 
            Map<MC_Cycle_Plan_Channel_vod__c, String> mapOfchannelsWithDifference = mapOfTragetToChannelsAndEditGoal.get(target.Id);
            if(mapOfchannelsWithDifference != null){
                for(MC_Cycle_Plan_Channel_vod__c channel : mapOfchannelsWithDifference.keySet()){
                    //check data and decide logic 
                    String logic = mapOfchannelsWithDifference.get(channel);
                    if(logic.equals(POPULATE) || logic.equals(BOTH)){
                        goalEdit = true;
                    }
                    else if(logic.equals(NULLIFY)){
                        continue;
                    }
                }
                //if the target is not same as goalEdit (assumed value) then update 
                if(goalEdit != target.Goals_Edited_vod__c){
                    target.Goals_Edited_vod__c = goalEdit;
                    cyclePlanTragetListToUpdate.add(target);
                }  
            }               
        }
    }

    Map<Id, MC_Cycle_Plan_Target_vod__c> cyclePlanTargets = new Map<Id, MC_Cycle_Plan_Target_vod__c>([SELECT Id, Cycle_Plan_vod__c FROM MC_Cycle_Plan_Target_vod__c WHERE Id IN :targetIds]);
    List<Id> cpIds = new List<Id>();
    for(MC_Cycle_Plan_Target_vod__c cpTarget: cyclePlanTargets.values()){
        cpIds.add(cpTarget.Cycle_Plan_vod__c);      
    }
    Map<Id,MC_Cycle_Plan_vod__c> cyclePlanMap = new Map<Id, MC_Cycle_Plan_vod__c>([SELECT Id, Lock_vod__c FROM MC_Cycle_Plan_vod__c WHERE Id IN :cpIds]);

    //for both insert and update 
    for(MC_Cycle_Plan_Channel_vod__c channel: Trigger.new){
        if(channel.Cycle_Plan_Target_vod__c != null && channel.Cycle_Channel_vod__c != null){
            channel.VExternal_Id_vod__c = channel.Cycle_Plan_Target_vod__c + '__' + channel.Cycle_Channel_vod__c;

            //for insert
            if(Trigger.isInsert){
                //if true, then lock the record
                if(cyclePlanMap.get(cyclePlanTargets.get(channel.Cycle_Plan_Target_vod__c).Cycle_Plan_vod__c).Lock_vod__c && !profileModAllData && !isMccpAdmin){
                    channel.addError(errorText);
                }
            }
        }
    }

    //update the object 
    update new List<MC_Cycle_Plan_Target_vod__c>(cyclePlanTragetListToUpdate);
}