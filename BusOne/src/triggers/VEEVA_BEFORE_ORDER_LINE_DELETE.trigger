/******************************************************************************
 *                                                                              
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Verticals onDemand, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Verticals onDemand.
 * 
 * Copyright (c) 2010 Veeva Systems , Inc.  All Rights Reserved.
 *
 *******************************************************************************/
trigger VEEVA_BEFORE_ORDER_LINE_DELETE on Order_Line_vod__c (before delete) {
  
  Map<String,Order_Line_vod__c> orderMap = 
           new Map <String,Order_Line_vod__c> ([Select Id,Order_vod__r.Lock_vod__c from Order_Line_vod__c where ID in :Trigger.old]);
           
           
    for (Order_Line_vod__c order : Trigger.old) {
        Order_Line_vod__c orderParent = orderMap.get(order.Id);
        if (orderParent.Order_vod__r.Lock_vod__c == true) {
                order.Name.addError(System.Label.NO_MODIFY_ORDER, false);
        }
    }
}