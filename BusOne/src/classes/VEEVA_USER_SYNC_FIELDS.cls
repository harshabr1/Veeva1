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
public class VEEVA_USER_SYNC_FIELDS {
    // Static set of fields used by VEEVA_USER_BEFORE_UPDATE trigger. Changes to these fields won't trigger a re-sync of the User record.
    public static Set<String> EXCLUDE_FIELDS = new Set<String>{
        'CreatedById'.toLowerCase(),
        'CreatedDate'.toLowerCase(),
        'LastLoginDate'.toLowerCase(),
        'LastModifiedById'.toLowerCase(),
        'LastModifiedDate'.toLowerCase(),
        'SystemModstamp'.toLowerCase(),
        'Last_Blackberry_Connect_vod__c'.toLowerCase(),
        'Last_Blackberry_Connect_Version_vod__c'.toLowerCase(),
        'Last_Blackberry_Sync_vod__c'.toLowerCase(),
        'Last_Mobile_Connect_vod__c'.toLowerCase(),
        'Last_Mobile_Connect_Version_vod__c'.toLowerCase(),
        'Last_Mobile_Sync_vod__c'.toLowerCase(),
        'Last_Tablet_Connect_vod__c'.toLowerCase(),
        'Last_Tablet_Connect_Version_vod__c'.toLowerCase(),
        'Last_Tablet_Sync_vod__c'.toLowerCase(),
        'Last_iPad_Connect_vod__c'.toLowerCase(),
        'Last_iPad_Connect_Version_vod__c'.toLowerCase(),
        'Last_iPad_Sync_vod__c'.toLowerCase(),
        'Last_iPad_iOS_Version_vod__c'.toLowerCase(),
        'Last_WinModern_Connect_vod__c'.toLowerCase(),
        'Last_WinModern_Connect_Version_vod__c'.toLowerCase(),
        'Last_WinModern_Sync_vod__c'.toLowerCase(),
        'Last_WinModern_Windows_Version_vod__c'.toLowerCase()
    };
}