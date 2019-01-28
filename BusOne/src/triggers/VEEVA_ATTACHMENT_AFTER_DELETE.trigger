trigger VEEVA_ATTACHMENT_AFTER_DELETE on Attachment (after delete) {

    //// Update the following fields in parent HTML_Report_vod if related Attachment is deleted
    // Status_vod ------------- Unpublished_vod
    // Failure_Msg_vod -------- NULL
    // Published_Date_vod__c -- Current Datetime

    // if org does not have KOL_Profile_vod record type for HTML_Report_vod__c, don't need to proceed further
    RecordType[] recordTypes = [Select Id, Name from RecordType where SobjectType = 'HTML_Report_vod__c' and Name = 'KOL_Profile_vod'];
    if(recordTypes.size() == 0) {
        return;
    }
    String KOLRecordTypeId = recordTypes[0].Id;

    // filter out all the parent HTML_Report_vod records
    Set<String> htmlReportIds = new Set<String>();
    Set<String> attDeletedForHTMLReport = new Set<String>();
    // get all the parent html report id
    for(Attachment att : trigger.Old) {
        if(att.ParentId.getSobjectType() == HTML_Report_vod__c.SobjectType) {
            attDeletedForHTMLReport.add(att.Id);
            htmlReportIds.add(att.ParentId);
        }
    }
    if(htmlReportIds.size() == 0) {
        return;
    }

    // query HTML_Report_vod objects of KOL_Profile_vod record type and in published status only
    Map<String, HTML_Report_vod__c> htmlReportMap = new Map<String, HTML_Report_vod__c>([SELECT Id, Status_vod__c, Failure_Msg_vod__c, Published_Date_vod__c FROM HTML_Report_vod__c WHERE Id IN: htmlReportIds and RecordTypeId =: KOLRecordTypeId and Status_vod__c = 'Published_vod']);
    if(htmlReportMap.keySet().size() == 0) {
        return;
    }
    else {
        htmlReportIds = htmlReportMap.keySet();
    }

    // get the all the child Attachments (existing ones in sf and the deleted ones in trigger.Old)
    Map<String, Attachment> allAttachmentChild = new Map<String, Attachment>([SELECT Id, ParentId, LastModifiedDate FROM Attachment WHERE ParentId IN: htmlReportIds]);
    for(Attachment att : trigger.Old) {
        if(htmlReportIds.contains(att.ParentId)) {
            allAttachmentChild.put(att.Id, att);
        }
    }
    if(allAttachmentChild.keySet().size() == 0) {
        return;
    }

    // maps html report id to the Attachment that has been published (with latest LastModifiedDate but before Published_Date_vod__c)
    Map<String, Attachment> publishedAtt = new Map<String, Attachment>();
    for(Attachment att : allAttachmentChild.values()) {
        String parentId = att.ParentId;
        HTML_Report_vod__c parent = htmlReportMap.get(parentId);
        if(att.LastModifiedDate <= parent.Published_Date_vod__c && (publishedAtt.get(parentId) == null || publishedAtt.get(parentId).LastModifiedDate < att.LastModifiedDate)) {
            publishedAtt.put(parentId, att);
        }
    }
    if(publishedAtt.keySet().size() == 0) {
        return;
    }

    // update HTML_Report_vod__c records accordingly
    for(String htmlReportId : publishedAtt.keySet()) {
        Attachment publishedAttachment = publishedAtt.get(htmlReportId);
        HTML_Report_vod__c htmlReport = htmlReportMap.get(htmlReportId);
        if(htmlReport != null && publishedAttachment != null && attDeletedForHTMLReport.contains(publishedAttachment.Id)) {
            htmlReport.Status_vod__c = 'Unpublished_vod';
            htmlReport.Failure_Msg_vod__c = '';
            htmlReport.Published_Date_vod__c = System.now();
        }
    }
    update htmlReportMap.values();
}