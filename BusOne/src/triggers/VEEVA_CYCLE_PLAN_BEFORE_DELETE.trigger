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
 
trigger VEEVA_CYCLE_PLAN_BEFORE_DELETE on Cycle_Plan_vod__c (before delete) {
  // Query the profile of the user to determine if they have permission to modify all data.
  // We will allow users to delete Cycle Plans if they have the modify all data option.
  String ProfileId = Userinfo.getProfileId();
  Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
    boolean modAllData = false;
    if (pr != null && pr.PermissionsModifyAllData)
       modAllData = true;
    
  for (Integer i = 0 ; i < Trigger.old.size(); i ++) {
         Cycle_Plan_vod__c cycle_old = Trigger.old[i];
      
      // If it was previously locked don't allow modification.
      if (cycle_old.Lock_vod__c == true && modAllData == false ) {
        cycle_old.Id.addError (System.Label.CYCLE_PLAN_BEFORE_DELETE_ERROR, false);
      }
  }
}