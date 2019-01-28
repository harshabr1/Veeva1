trigger VOD_MC_CYCLE_PLAN_PRODUCT_BEFORE_UPDATE_DELETE on MC_Cycle_Plan_Product_vod__c (before update, before delete) {
    String ProfileId = Userinfo.getProfileId();
    Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
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
    
    List<Id> channelIds = new List<Id>();
    for(MC_Cycle_Plan_Product_vod__c product: Trigger.old){
        channelIds.add(product.Cycle_Plan_Channel_vod__c);        
    }
    Map<Id, MC_Cycle_Plan_Channel_vod__c> cyclePlanChannelMap = new Map<Id, MC_Cycle_Plan_Channel_vod__c>([SELECT Id, Cycle_Plan_Target_vod__c FROM MC_Cycle_Plan_Channel_vod__c WHERE Id IN :channelIds]);
    
    List<Id> targetIds = new List<Id>();
    for(MC_Cycle_Plan_Channel_vod__c channel: cyclePlanChannelMap.values()){
        targetIds.add(channel.Cycle_Plan_Target_vod__c);        
    }
    Map<Id, MC_Cycle_Plan_Target_vod__c> cyclePlanTargets = new Map<Id, MC_Cycle_Plan_Target_vod__c>([SELECT Id, Cycle_Plan_vod__c FROM MC_Cycle_Plan_Target_vod__c WHERE Id IN :targetIds]);
    
    List<Id> cpIds = new List<Id>();
    for(MC_Cycle_Plan_Target_vod__c target: cyclePlanTargets.values()){
        cpIds.add(target.Cycle_Plan_vod__c);        
    }
    Map<Id,MC_Cycle_Plan_vod__c> cyclePlanMap = new Map<Id, MC_Cycle_Plan_vod__c>([SELECT Id, Lock_vod__c FROM MC_Cycle_Plan_vod__c WHERE Id IN :cpIds]);
    
    for(Integer i = 0; i< Trigger.old.size(); i++){
        MC_Cycle_Plan_Product_vod__c oldPlan = Trigger.old[i];
        //if true, then lock the record
        if(cyclePlanMap.get(cyclePlanTargets.get(cyclePlanChannelMap.get(oldPlan.Cycle_Plan_Channel_vod__c).Cycle_Plan_Target_vod__c).Cycle_Plan_vod__c).Lock_vod__c && !profileModAllData && !isMccpAdmin){
            if(Trigger.isDelete){
                oldPlan.addError(errorText);
            }
            else{
                MC_Cycle_Plan_Product_vod__c newPlan = Trigger.new[i];
                newPlan.addError(errorText);
            }
        }    
    }
    
  }