/******************************************************************************
 *                                                                              
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems.
 * 
 * Copyright (c) 2010 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
trigger VEEVA_CYCLE_PLAN_BEFORE_INSERT on Cycle_Plan_vod__c (before insert) {

   // We can only have a single active Cycle Plan for a territory. External_Id_vod__c is a 
   // Unique external id.  By setting the values in the before trigger we will perfom the unique
   // check in an index and this will not hit Salesforce govenor limits.
   
   for (Cycle_Plan_vod__c cycle : Trigger.new) {
     if (cycle.Active_vod__c == true) {
       cycle.External_Id_vod__c = cycle.Territory_vod__c + '__true';
     } else {
       cycle.External_Id_vod__c = null;
     }
      
   }
       
}