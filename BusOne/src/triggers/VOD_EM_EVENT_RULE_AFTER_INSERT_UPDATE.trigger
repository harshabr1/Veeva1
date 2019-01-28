trigger VOD_EM_EVENT_RULE_AFTER_INSERT_UPDATE on EM_Event_Rule_vod__c (after insert, after update) {
    Map<String, String> idToConfig = new Map<String, String>();
    Map<String, String> idToQualification = new Map<String, String>();
    Map<String, String> idToCountry = new Map<String, String>();
    Map<String, String> idToRecordType = new Map<String, String>();
    Map<String, String> idToMaterial = new Map<String, String>();
    Map<String, String> idToEmailTemplate = new Map<String, String>();
    
    List<RecordType> ruleRecordTypes = [SELECT DeveloperName, Id FROM RecordType WHERE SobjectType = 'EM_Event_Rule_vod__c'];
    Id qualificationRecordType;
    Id materialRecordType;
    Id childEventSettingsRecordType;
    for(RecordType rt: ruleRecordTypes){
        if(rt.DeveloperName =='Speaker_Qualification_vod') {
        	qualificationRecordType = rt.Id;    
        } else if (rt.DeveloperName == 'Material_vod') {
            materialRecordType = rt.Id;
        } else if (rt.DeveloperName == 'Child_Event_Settings_vod') {
            childEventSettingsRecordType = rt.Id;
        }
    }

    List<EM_Event_Rule_vod__c> rules = [ SELECT Id, RecordTypeId, Event_Configuration_vod__c, Qualification_vod__c, Country_Override_vod__c, Material_vod__c, Email_Template_vod__c FROM EM_Event_Rule_vod__c];
    for (EM_Event_Rule_vod__c rule : rules) {
        idToConfig.put(rule.Id, rule.Event_Configuration_vod__c);
        idToQualification.put(rule.Id, rule.Qualification_vod__c);
        idToCountry.put(rule.Id, rule.Country_Override_vod__c);
        idToRecordType.put(rule.id, rule.RecordTypeId);
        idToMaterial.put(rule.Id, rule.Material_vod__c);
        idToEmailTemplate.put(rule.id, rule.Email_Template_vod__c);
    }

    for (EM_Event_Rule_vod__c rule : Trigger.new) {
        // We want to compare the upsert objects to the newest versions of EM_Event_rule_vod
        // so we need to override what is already in the database
        idToConfig.put(rule.Id, rule.Event_Configuration_vod__c);
        idToQualification.put(rule.Id, rule.Qualification_vod__c);
        idToCountry.put(rule.Id, rule.Country_Override_vod__c);
        idToRecordType.put(rule.id, rule.RecordTypeId);
        idToMaterial.put(rule.Id, rule.Material_vod__c);
        idToEmailTemplate.put(rule.id, rule.Email_Template_vod__c);
    }

	EM_Event_Rule_vod__c childEventRule;
    for (EM_Event_Rule_vod__c rule1 : Trigger.new) {
            for (EM_Event_Rule_vod__c rule2 : rules) {
                if (!rule1.Id.equals(rule2.Id) && VOD_Utils.isValueSame(idToConfig, rule1.Id, rule2.Id) &&
                VOD_Utils.isValueSame(idToCountry, rule1.Id, rule2.Id) &&
                VOD_Utils.isValueSame(idToRecordType, rule1.Id, rule2.Id)) {

                    if(materialRecordType.equals(idToRecordType.get(rule1.Id))) {
                        if(idToMaterial.get(rule1.Id) != null && VOD_Utils.isValueSame(idToMaterial, rule1.Id, rule2.Id)) {
                            rule1.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_CONFIG_ERROR', 'TriggerError',
                                                                                    'Duplicate Configuration Error'));
                        } else if (idToEmailTemplate.get(rule1.Id) != null && VOD_Utils.isValueSame(idToEmailTemplate, rule1.Id, rule2.Id)) {
                            rule1.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_CONFIG_ERROR', 'TriggerError',
                                                                                    'Duplicate Configuration Error'));
                        }
                    }
                    else if(qualificationRecordType.equals(idToRecordType.get(rule1.Id))) {
                        if(VOD_Utils.isValueSame(idToQualification, rule1.Id, rule2.Id)) {
                            rule1.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_CONFIG_ERROR', 'TriggerError',
                                                                                    'Duplicate Configuration Error'));
                        }
                    } else if (childEventSettingsRecordType.equals(idToRecordType.get(rule1.id))) {
                    	childEventRule = rule1;
                	} else {
                        rule1.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_CONFIG_ERROR', 'TriggerError',
                                                                                'Duplicate Configuration Error'));
                    }
                }
            }
        }
    //if event rule was a child event settings record type, then we should have a reference, and verify the rule is not a duplicate on the same event config
    if (childEventRule != null) {
        List<EM_Event_Rule_vod__c> newChildEventSettingsRule = [SELECT Id FROM EM_Event_Rule_vod__c WHERE EM_Event_Rule_vod__c.Country_Override_vod__c = :childEventRule.Country_Override_vod__c AND EM_Event_Rule_vod__c.Event_Configuration_vod__c = :childEventRule.Event_Configuration_vod__c AND EM_Event_Rule_vod__c.Id NOT IN :Trigger.New];
        if (newChildEventSettingsRule.size() > 0) {
            childEventRule.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_CONFIG_ERROR', 'TriggerError', 'Duplicate Configuration Error'));
        }
    }
}