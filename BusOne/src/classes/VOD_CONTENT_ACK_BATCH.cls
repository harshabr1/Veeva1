global class VOD_CONTENT_ACK_BATCH implements Database.Batchable<SObject>, Schedulable, Database.Stateful {
    global String alertTitle;
    global String alertText;
    global Map<String, String> alertTitles;
    global Map<String, String> alertTexts;

    global VOD_CONTENT_ACK_BATCH() {
        List<Message_vod__c> messages = [SELECT Name, Text_vod__c, Language_vod__c FROM Message_vod__c
                                         WHERE Category_vod__c = 'AOC' AND Active_vod__c = true
                                         AND Name IN ('AOC_ALERT_TEXT', 'AOC_ALERT_TITLE')];
        alertText = '{0} has an overdue Acknowledgment of Content. Please obtain a confirmation signature for the associated shipment.';
        alertTitle = 'Overdue AOC for {0}';
        alertTitles = new Map<String, String>();
        alertTexts = new Map<String, String>();
        for (Message_vod__c message : messages) {
            if ('AOC_ALERT_TEXT'.equals(message.Name)) {
                alertTexts.put(message.Language_vod__c, message.Text_vod__c);
            } else if ('AOC_ALERT_TITLE'.equals(message.Name)) {
                alertTitles.put(message.Language_vod__c, message.Text_vod__c);
            }
        }
    }

    global void execute(SchedulableContext sc) {
        Database.Batchable<SObject> b = new VOD_CONTENT_ACK_BATCH();
        Database.executeBatch(b, 50);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, AOC_Due_Date_vod__c, Alert_Created_vod__c, Alert_Duration_vod__c, Account_vod__c, Account_vod__r.Name, OwnerId ' +
                'FROM Content_Acknowledgement_vod__c ' +
                'WHERE AOC_Due_Date_vod__c <= TODAY AND Status_vod__c != \'Completed_vod\' AND Alert_Created_vod__c = false'
        );
    }

    global void execute(Database.BatchableContext bc, List<Content_Acknowledgement_vod__c> acks) {
        List<Alert_vod__c> alerts = new List<Alert_vod__c>();
        String newAlertText, newAlertTitle;
        List<String> ownerIds = new List<String>();
        for (Content_Acknowledgement_vod__c ack : acks) {
            ownerIds.add(ack.OwnerId);
        }
        List<User> users = [SELECT Id, LanguageLocaleKey FROM User WHERE Id IN :ownerIds];
        Map <String, String> userToLanguage = new Map<String, String>();
        for (User user : users) {
            userToLanguage.put(user.Id, user.LanguageLocaleKey);
        }
        for (Content_Acknowledgement_vod__c ack : acks) {
            newAlertText = alertTexts.get(userToLanguage.get(ack.OwnerId));
            if (newAlertText == null) {
                newAlertText = alertText;
            }
            newAlertTitle = alertTitles.get(userToLanguage.get(ack.OwnerId));
            if (newAlertTitle == null) {
                newAlertTitle = alertTitle;
            }
            Alert_vod__c alert = new Alert_vod__c(
                Activation_Date_vod__c = ack.AOC_Due_Date_vod__c,
                Dismissible_vod__c = true,
                Priority_vod__c = 'Important',
                Link_Reference_vod__c = ack.Id + ',Content_Acknowledgement_vod__c',
                Alert_Text_vod__c = newAlertText.replace('{0}', ack.Account_vod__r.Name),
                Name = newAlertTitle.replace('{0}', ack.Account_vod__r.Name),
                OwnerId = ack.OwnerId
            );
            if (ack.Alert_Duration_vod__c != null) {
                alert.Expiration_Date_vod__c = ack.AOC_Due_Date_vod__c.addDays(ack.Alert_Duration_vod__c.intValue());
            } else {
                alert.Expiration_Date_vod__c = ack.AOC_Due_Date_vod__c;
            }
            alerts.add(alert);
            ack.Alert_Created_vod__c = true;
        }
        if (!acks.isEmpty()) {
            update acks;
            insert alerts;
        }

        List<Alert_User_Action_vod__c> actions = new List<Alert_User_Action_vod__c>();
        for (Alert_vod__c alert : alerts) {
            Alert_User_Action_vod__c action = new Alert_User_Action_vod__c(
                Alert_vod__c = alert.Id,
                Dismissed_vod__c = false,
                User_vod__c = alert.OwnerId
            );
            actions.add(action);
        }
        if (!actions.isEmpty()) {
            insert actions;
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}