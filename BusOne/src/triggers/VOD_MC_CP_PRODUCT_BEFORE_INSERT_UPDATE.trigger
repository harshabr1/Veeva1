trigger VOD_MC_CP_PRODUCT_BEFORE_INSERT_UPDATE on MC_Cycle_Plan_Product_vod__c (before insert, before update) {

    Map<Id, Map<MC_Cycle_Plan_Product_vod__c, String>> mapOfTragetToProductsAndEditGoal = new Map<Id, Map<MC_Cycle_Plan_Product_vod__c, String>>();
    Map<Id, Map<MC_Cycle_Plan_Product_vod__c, String>> mapOfChannelToProductsAndEditGoal = new Map<Id, Map<MC_Cycle_Plan_Product_vod__c, String>>();
    Set<MC_Cycle_Plan_Target_vod__c> cyclePlanTragetListToUpdate = new Set<MC_Cycle_Plan_Target_vod__c>();

    Boolean populatingGoalEdit = false;
    Boolean blankingGoalEdit = false;
    String POPULATE = 'POPULATE';
    String NULLIFY = 'NULLIFY';
    String BOTH = 'BOTH';

    List<Id> channelIds = new List<Id>();
    List<Id> productIds = new List<Id>();

    for(MC_Cycle_Plan_Product_vod__c product: Trigger.new){
            channelIds.add(product.Cycle_Plan_Channel_vod__c);
            productIds.add(product.Id);

            Decimal oldActivityGoalEditValue = null;
            Decimal oldTeamActivityGoalEditValue = null;

           //loop through all products and check for target flag
           if(Trigger.oldMap != null){
                oldActivityGoalEditValue = Trigger.oldMap.get(product.Id).Activity_Goal_Edit_vod__c;
                oldTeamActivityGoalEditValue = Trigger.oldMap.get(product.Id).Team_Activity_Goal_Edit_vod__c;
           }
            Decimal newActivityGoalEditValue = product.Activity_Goal_Edit_vod__c;
            Decimal newTeamActivityGoalEditValue = product.Team_Activity_Goal_Edit_vod__c;

            if((oldActivityGoalEditValue != newActivityGoalEditValue ) || (oldTeamActivityGoalEditValue  != newTeamActivityGoalEditValue )){
                if(newActivityGoalEditValue  != null || newTeamActivityGoalEditValue  != null){
                    populatingGoalEdit = true;
                }
                if((oldActivityGoalEditValue != null && newActivityGoalEditValue == null) || (oldTeamActivityGoalEditValue != null && newTeamActivityGoalEditValue == null)){
                    blankingGoalEdit = true;
                }
                Id channelId = product.Cycle_Plan_Channel_vod__c;
                if(mapOfChannelToProductsAndEditGoal.containsKey(channelId)){
                    //defensive logic - if same channel is added in data load file
                    Map<MC_Cycle_Plan_Product_vod__c, String> mapOfProductsWithGoalEdit = mapOfChannelToProductsAndEditGoal.get(channelId);
                    mapOfProductsWithGoalEdit.put(product, checkPopulateOrBlankify(populatingGoalEdit, blankingGoalEdit));
                }
                else{
                    //check logic and add at channel level
                    Map<MC_Cycle_Plan_Product_vod__c, String> mapOfProductsWithGoalEdit = new Map<MC_Cycle_Plan_Product_vod__c, String>();
                    mapOfProductsWithGoalEdit.put(product, checkPopulateOrBlankify(populatingGoalEdit, blankingGoalEdit));
                    mapOfChannelToProductsAndEditGoal.put(channelId, mapOfProductsWithGoalEdit);
                }
            }
        }

        //populate map of targetIds with products -- __r is not working when we iterate over Trigger.new
        List<MC_Cycle_Plan_Channel_vod__c> mapOfCyclePlanChannelToTargetId = new List<MC_Cycle_Plan_Channel_vod__c>([select Id, Cycle_Plan_Target_vod__c from MC_Cycle_Plan_Channel_vod__c where Id IN: channelIds]);
        for(MC_Cycle_Plan_Channel_vod__c channel : mapOfCyclePlanChannelToTargetId){

            //get the list of logic per channel
            if(mapOfTragetToProductsAndEditGoal.get(channel.Cycle_Plan_Target_vod__c) == null){
                mapOfTragetToProductsAndEditGoal.put(channel.Cycle_Plan_Target_vod__c, mapOfChannelToProductsAndEditGoal.get(channel.Id));
            }
            else{
                if(mapOfChannelToProductsAndEditGoal.get(channel.Id) != null){
                    mapOfTragetToProductsAndEditGoal.get(channel.Cycle_Plan_Target_vod__c).putAll(mapOfChannelToProductsAndEditGoal.get(channel.Id));
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
        Set<Id> targetIds  =  mapOfTragetToProductsAndEditGoal.keySet();

        Map<Id, Integer> mapOfCyclePlanChannelsConnectedToTarget = new Map<Id,Integer>();
        Map<Id, Integer> mapOfCyclePlanProductConnectedToChannelAndTarget  = new Map<Id,Integer>();

        if(targetIds != null && targetIds.size() > 0 && productIds != null && productIds.size() > 0){
            totalChannels = [Select Cycle_Plan_Target_vod__c, count(Id) cnt From MC_Cycle_Plan_Channel_vod__c where Cycle_Plan_Target_vod__c IN :targetIds and (Activity_Goal_Edit_vod__c != null or Team_Activity_Goal_Edit_vod__c != null) group by Cycle_Plan_Target_vod__c];
            totalProducts = [select Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__c targetId, count(Id) cnt from MC_Cycle_Plan_Product_vod__c where Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__c IN:targetIds and Id NOT IN: productIds AND (Activity_Goal_Edit_vod__c != null or Team_Activity_Goal_Edit_vod__c != null ) group by Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__c];

            for(AggregateResult ar : totalChannels){
                mapOfCyclePlanChannelsConnectedToTarget.put(Id.valueOf(String.valueOf(ar.get('Cycle_Plan_Target_vod__c'))), Integer.valueOf(ar.get('cnt')));
            }

             for(AggregateResult ar : totalProducts ){
                mapOfCyclePlanProductConnectedToChannelAndTarget.put(Id.valueOf(String.valueOf(ar.get('targetId'))), Integer.valueOf(ar.get('cnt')));
            }
        }
    
        //loop through all channels and decide which target will be updated
        List<MC_Cycle_Plan_Target_vod__c> targets = new List<MC_Cycle_Plan_Target_vod__c>([Select Id, Goals_Edited_vod__c From MC_Cycle_Plan_Target_vod__c where Id = :targetIds]);
        for(MC_Cycle_Plan_Target_vod__c target : targets){
        
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
              Map<MC_Cycle_Plan_Product_vod__c, String> mapOfProductsWithDifference = mapOfTragetToProductsAndEditGoal.get(target.Id);
              if(mapOfProductsWithDifference != null)
              {
                  for(MC_Cycle_Plan_Product_vod__c product : mapOfProductsWithDifference.keySet()){
                     //check data and decide logic 
                        String logic = mapOfProductsWithDifference.get(product);
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

    //update the target 
    update new List<MC_Cycle_Plan_Target_vod__c>(cyclePlanTragetListToUpdate);
}