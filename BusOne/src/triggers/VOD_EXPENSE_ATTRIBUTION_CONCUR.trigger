trigger VOD_EXPENSE_ATTRIBUTION_CONCUR on Expense_Attribution_vod__c (before insert, before update, before delete) {
    Set<Id> expenseLineIds = new Set<Id>();
    Set<String> errorConcurStatuses = new Set<String>();
    errorConcurStatuses.add('Submitted_vod');
    errorConcurStatuses.add('Sending_vod');
    
    List<Expense_Attribution_vod__c> attrs;
    
    if(Trigger.isDelete) {
        attrs = Trigger.old;
    } else {
        attrs = Trigger.new;
    }
    
    for(Expense_Attribution_vod__c attr: attrs) {        
        expenseLineIds.add(attr.Expense_Line_vod__c);
    }
    
    List<Expense_Line_vod__c> expenseLines = [SELECT Id, Expense_Header_vod__r.Concur_Status_vod__c FROM Expense_Line_vod__c WHERE Id IN :expenseLineIds];

    Map<String, String> expenseLineToConcurStatus = new Map<String, String>();
    for(Expense_Line_vod__c line: expenseLines) {
        expenseLineToConcurStatus.put(line.Id, line.Expense_Header_vod__r.Concur_Status_vod__c);
    }

    List<Message_vod__c> messageList;
    String concurError = '';
    try {
        messageList = [SELECT Name, Text_vod__c From Message_vod__c
                       WHERE Name='CONCUR_ALREADY_SENT_VIEW'
                       AND Category_vod__c='Concur' AND Active_vod__c=true
                       AND Language_vod__c=:UserInfo.getLanguage()];
        concurError = messageList.get(0).Text_vod__c;
    } catch(Exception e) {
        concurError = 'This record has already been submitted to Concur and cannot be modified.';
    }   
    
    for(Expense_Attribution_vod__c attr: attrs) {
        if(Trigger.old != null && Trigger.new != null) {
            Expense_Attribution_vod__c oldAttr = Trigger.oldMap.get(attr.Id);
            Expense_Attribution_vod__c newAttr = Trigger.newMap.get(attr.Id);
            if(oldAttr.Concur_Response_Attendee_Timestamp_vod__c != newAttr.Concur_Response_Attendee_Timestamp_vod__c ||
               oldAttr.Concur_Response_Time_Association_vod__c != newAttr.Concur_Response_Time_Association_vod__c ||
              oldAttr.Concur_System_Attendee_ID_vod__c != newAttr.Concur_System_Attendee_ID_vod__c ||
               oldAttr.Concur_System_ID_vod__c != newAttr.Concur_System_ID_vod__c) {
                   continue;
               }
        }
        String concurStatus = expenseLineToConcurStatus.get(attr.Expense_Line_vod__c);
        if(errorConcurStatuses.contains(concurStatus)) {
            attr.addError(concurError);
        }
    }
}