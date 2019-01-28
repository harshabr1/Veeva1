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
 * Copyright (c) 2009 Verticals onDemand, Inc.  All Rights Reserved.
 *
 ******************************************************************************/
public with sharing class VOD_UserTerritoryExtension {
    private final Account acct;
    private List<UserTerritoryRow> theList = null;
    
    public VOD_UserTerritoryExtension(ApexPages.StandardController controller) {
        this.acct = (Account)controller.getRecord();
    }

    public List<UserTerritoryRow> getUserTerritories() {
        if (theList != null)
            return theList;
            
        String acctId = acct.id;
        if ((acctId == null) || (acctId == ''))
            return null;
        
        Set<String> groupIds = new Set<String>();
        for (AccountShare acctShare : [Select UserOrGroupId From AccountShare Where AccountId=:acctId And RowCause In ('Territory','TerritoryManual')]) {
            groupIds.add(acctShare.UserOrGroupId);
        }
        
        if (groupIds.size() <= 0)
            return null;
                
        Set<String> territoryIds = new Set<String>();
        for (Group gr : [Select RelatedId From Group Where Id In :groupIds]) {
            territoryIds.add(gr.RelatedId);
        }
        
        if (territoryIds.size() <= 0)
            return null;
                
        Map<Id,UserTerritory> userTerritories = new Map<Id,UserTerritory>([Select Id,UserId,TerritoryId From UserTerritory Where TerritoryId In :territoryIds And IsActive=true]);

        Set<String> userIds = new Set<String>();
        for (UserTerritory ut : userTerritories.values()) {
            userIds.add(ut.UserId);
        }

        Map<Id,User> users = null;
        if (userIds.size() > 0)
            users = new Map<Id,User>([Select Id,Name From User Where Id In :userIds]);
        else
            return null;
        
        Map<Id,Territory> territories = new Map<Id,Territory>([Select Id,Name,Description From Territory Where Id In :territoryIds]);
        
        Map<String,UserTerritoryRow> tempMap = new Map<String,UserTerritoryRow>();
        for (Territory terr : territories.values()) {
            UserTerritoryRow utr = new UserTerritoryRow();
            utr.Territory = terr.Name;
            utr.Users = '';
            if (terr.Description != null)
                utr.Description = terr.Description;
            else
                utr.Description = '';
            tempMap.put(terr.Name+'   '+terr.Id, utr);  // just in case Name is not unique
        }

        for (UserTerritory ut : userTerritories.values()) {
            Territory tempTerr = territories.get(ut.TerritoryId);
            if (tempTerr == null)
                continue;
            String keyValue = tempTerr.Name+'   '+tempTerr.Id;
            UserTerritoryRow terrRow = tempMap.get(keyValue);
            if (terrRow == null)
                continue;
                
            User usr = users.get(ut.UserId);
            if (terrRow.Users.length() > 0)
                terrRow.Users += ', ';
                
            terrRow.Users += usr.Name;
            tempMap.put(keyValue, terrRow);
        }
        
        List<String> keys = new List<String>(tempMap.keySet());
        keys.sort();
        
        theList = new List<UserTerritoryRow>();
        for (String key : keys)
            theList.add(tempMap.get(key));

        return theList;
    }
	
    public String getOnLoadJS() {
        List<UserTerritoryRow> terrs = getUserTerritories();
        return 'if(document.documentElement&&document.documentElement.scrollHeight){window.resizeBy(0,document.documentElement.scrollHeight-200);}else if(document.body.scrollHeight){window.resizeBy(0,document.body.scrollHeight-200);}';
    }
    
    public class UserTerritoryRow {
        public String territory{get; set;}
        public String users{get; set;}
        public String description{get; set;}
    }
}