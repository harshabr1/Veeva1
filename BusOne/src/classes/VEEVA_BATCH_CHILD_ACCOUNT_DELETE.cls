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
 * Copyright (c) 2010 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
global  with sharing  class VEEVA_BATCH_CHILD_ACCOUNT_DELETE implements Database.Batchable<sObject> {

  private final String initialState;
  // Contains the time we started to process the address delete. 
  global VEEVA_BATCH_CHILD_ACCOUNT_DELETE() {
  }
  
  global Database.QueryLocator start(Database.BatchableContext BC) {
    
    // This is the base query that dirves the chunking.
  
    
    String selStmt = 'Select Id From Address_vod__c Where Controlled_Address_vod__c = true AND Controlling_Address_vod__c = null';
    System.debug(selStmt);
    return Database.getQueryLocator(selStmt);
    
  }
  
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
    System.debug (batch);
    delete batch;
    }
  
  global void finish(Database.BatchableContext BC) {
    
  }
  
}