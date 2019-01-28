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
 * Copyright (c) 2010-2013 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
trigger VEEVA_USER_BEFORE_UPDATE on User (before update) {

    Map<String, Schema.SObjectField> userFields = Schema.SObjectType.User.fields.getMap();

    for (Integer i = 0; i < Trigger.new.size(); i++) {
        SObject oldUserObject = Trigger.old[i];
        SObject newUserObject = Trigger.new[i];

        for (String fieldName : userFields.keySet()) {
            System.debug(fieldName);
            if (VEEVA_USER_SYNC_FIELDS.EXCLUDE_FIELDS.contains(fieldName.toLowerCase())) {
                System.debug('Skipping field ' + fieldName + ' because it is explicitly excluded.');
                continue;
            }

            Schema.SObjectField userField = userFields.get(fieldName);
            Schema.SoapType fieldType = userField.getDescribe().getSOAPType();
            if (fieldType == Schema.SoapType.ADDRESS || fieldType == Schema.SoapType.LOCATION) {
                System.debug('Skipping field ' + fieldName + ' because it is of unuspported type ' + fieldType + '.');
                continue;
            }

            if (oldUserObject.get(fieldName) != newUserObject.get(fieldName)) {
                System.debug ('Field  :' + fieldName + ' has Changed. old:' + oldUserObject.get(fieldName) + ' new: ' + newUserObject.get(fieldName));
                Trigger.new[i].Override_SystemModstamp_Timestamp_vod__c = System.now();
                break;
            }
        }
    }
}