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
trigger VEEVA_CYCLE_PLAN_BEFORE_UPDATE on Cycle_Plan_vod__c (before update) {
  
  // Query the profile of the user to determine if they have permission to modify all data.
  // We will allow users to modify Cycle Plans if they have the modify all data option.
  String ProfileId = Userinfo.getProfileId();
  Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
    boolean modAllData = false;
    if (pr != null && pr.PermissionsModifyAllData)
       modAllData = true;
    
    //Lood through all the rows in the transaction
    for (Integer i = 0 ; i < Trigger.new.size(); i ++) {
      Cycle_Plan_vod__c cycle_new = Trigger.new[i];
      Cycle_Plan_vod__c cycle_old = Trigger.old[i];
      
     if (cycle_old.Lock_vod__c == true && cycle_new.Lock_vod__c == false) {
    	  //User had access to Lock vod
    	  	cycle_new.Status_vod__c = 'In_Progress_vod';    	  
    	} else  if ((cycle_old.Lock_vod__c == true && modAllData == false) ) {
    		cycle_new.Id.addError (System.Label.CYCLE_PLAN_BEFORE_DELETE_ERROR, false);
    	}
      //  Set the lock flag when the plan is switched to submitted.
      if ('Submitted_vod' == cycle_new.Status_vod__c) {
        cycle_new.Lock_vod__c = true;
      }
      
      // Update external ID if needed.
      if (cycle_new.Active_vod__c == true) {
         cycle_new.External_Id_vod__c = cycle_new.Territory_vod__c + '__true';
       } else {
         
         cycle_new.External_Id_vod__c = null;
       }
    }
}