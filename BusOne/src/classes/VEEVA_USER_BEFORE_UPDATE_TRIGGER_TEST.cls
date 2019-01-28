/******************************************************************************
 *                                                                              
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 * 
 * Copyright (c) 2013 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
@isTest
private class VEEVA_USER_BEFORE_UPDATE_TRIGGER_TEST {

    static testMethod void testUpdateSyncFields() {
        Profile userProfile = [SELECT Id FROM Profile LIMIT 1]; // Don't care which profile - just pick one.
        User testUser = new User(FirstName='Veeva',LastName='Systems',UserName='veeva_systems_test@veeva.com',Email='veeva_systems_test@veeva.com',
                                Alias='testUser',TimeZoneSidKey='America/Los_Angeles',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',
                                LanguageLocaleKey='en_US',ProfileId=userProfile.Id);
        insert testUser;
        
        System.Test.startTest();

        // now run an update in order to set the override timestamp the first time 
        testUser.CommunityNickname = 'JoeBob';
        update testUser;
        User inserted = [SELECT Id, UserName, Override_SystemModstamp_Timestamp_vod__c FROM User WHERE Id=:testUser.Id LIMIT 1];
        Datetime origTimestamp = inserted.Override_SystemModstamp_Timestamp_vod__c;
        System.assert(origTimestamp != null,'Trigger failed to set override timestamp on update.');

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.User.fields.getMap();
        Integer count = 0;
        for (String fieldName : VEEVA_USER_SYNC_FIELDS.EXCLUDE_FIELDS) {
            // Can only directly manipulate the custom fields
            if (fieldName.endsWith('__c')) {
                User updateUser = new User();
                updateUser.Id = testUser.Id;
            	Schema.SObjectField field = fieldMap.get(fieldName);
                System.assert(field != null, 'Could not find field ' + fieldName);
                Schema.DisplayType fieldType = field.getDescribe().getType();
                if (fieldType == Schema.DisplayType.DATETIME) {
                    updateUser.put(field, System.now());
                } else if (fieldType == Schema.DisplayType.STRING) {
                    updateUser.put(field, 'v1.0Test');
                }
                update updateUser;
        		User updated = [SELECT Id, UserName, Override_SystemModstamp_Timestamp_vod__c FROM User WHERE Id=:testUser.Id LIMIT 1];
                System.assertEquals(origTimestamp, updated.Override_SystemModstamp_Timestamp_vod__c, 'Override Timestamp was updated for ' + fieldName);
                count++;
            }
        }
        System.assertEquals(VEEVA_USER_SYNC_FIELDS.EXCLUDE_FIELDS.size()-6, count, 'Failed to all custom fields.');
        System.Test.stopTest();
    }
}