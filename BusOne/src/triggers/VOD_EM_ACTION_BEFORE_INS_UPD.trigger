trigger VOD_EM_ACTION_BEFORE_INS_UPD on EM_Event_Action_vod__c (before insert, before update) {
    List<EM_Event_Action_vod__c> actions = [SELECT Id, Event_Configuration_vod__c, Button_Name_vod__c, Country_Override_vod__c, Starting_Status_vod__c
                                             FROM EM_Event_Action_vod__c];
    for (EM_Event_Action_vod__c action : actions) {
        for (EM_Event_Action_vod__c newAction : Trigger.new) {
            if (!action.Id.equals(newAction.Id)
                && action.Event_Configuration_vod__c == newAction.Event_Configuration_vod__c
                && action.Button_Name_vod__c == newAction.Button_Name_vod__c
                && action.Country_Override_vod__c == newAction.Country_Override_vod__c
                && action.Starting_Status_vod__c == newACtion.Starting_Status_vod__c) {
            	
            		newAction.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_CONFIG_ERROR', 'TriggerError',
                                                                          'Duplicate Configuration Error'));
            }
        }		
    }
}