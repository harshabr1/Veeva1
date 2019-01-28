trigger VOD_CONSENT_TEMPLATE_AFTER_INSUPD on Consent_Template_vod__c (after insert, after update) {
    List<Consent_Template_vod__c> allTemplates = [SELECT Id, Start_Date_vod__c, End_Date_vod__c FROM Consent_Template_vod__c ORDER BY Start_Date_vod__c];
    Set<Id> overlapTemplates = new Set<Id>();
    Set<Id> noEndDateTemplates = new Set<Id>();
    Consent_Template_vod__c prevTemplate = null;
    for (Consent_Template_vod__c template : allTemplates) {
        if (template.End_Date_vod__c == null) {
            noEndDateTemplates.add(template.Id);
        }
        if (prevTemplate != null && (prevTemplate.End_Date_vod__c == null || prevTemplate.End_Date_vod__c >= template.Start_Date_vod__c)) {
            overlapTemplates.add(prevTemplate.Id);
            overlapTemplates.add(template.Id);
        }
        prevTemplate = template;
    }

    for (Consent_Template_vod__c template : Trigger.new) {
        if (overlapTemplates.contains(template.Id) || (noEndDateTemplates.size() > 1 && noEndDateTemplates.contains(template.Id))) {
            template.addError('Overlapping Template');
        }
    }
}