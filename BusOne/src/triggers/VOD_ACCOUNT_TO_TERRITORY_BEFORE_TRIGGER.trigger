/*******************************************************************************
 *                                                                              
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems.
 * 
 * Copyright (c) 2010-Present Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
 
trigger VOD_ACCOUNT_TO_TERRITORY_BEFORE_TRIGGER on Account_Territory_Loader_vod__c (before insert, before update) {

    // System.debug ('VOD_ACCOUNT_TO_TERRITORY_BEFORE_TRIGGER starts');
    for (Integer i = 0 ;  i < Trigger.new.size(); i++) {
        if (Trigger.new[i].External_ID_vod__c == null || Trigger.new[i].External_ID_vod__c.length() == 0)
           Trigger.new[i].External_ID_vod__c =Trigger.new[i].Account_vod__c;
  
        //System.debug ('Territory List Before processing ' + Trigger.new[i].Territory_vod__c);
        String territory = Trigger.new[i].Territory_vod__c;
		String addedTerListExistedInTerVod ='';
        if(territory!=null && territory.Length() > 0) {
            String[] territories = territory.split(',');
            if(territories[0].startsWith(';')==false) {
                territory = ';';
                addedTerListExistedInTerVod =';';
            } else {
                territory = '';
                addedTerListExistedInTerVod = '';
            }
            for(Integer j=0;j<territories.size();j++)  {
                if(territories[j].Length()==0)
                    continue;
                territory = territory + territories[j].trim();
                if(territories[0].endsWith(';')==false)
                territory = territory + ';';
            }
            if (Trigger.new[i].Territory_To_Add_vod__c != null) {
                String [] terrAddSplit = Trigger.new[i].Territory_To_Add_vod__c.split(';');
                for (String myAddTerr :terrAddSplit) {
                    if ('' == myAddTerr)
                        continue;
                    String terrval = ';'+myAddTerr+';';
                    Integer loc = territory.indexOf(terrval);
                    if (loc == -1) {
                        //System.debug ('Add to Territory' + myAddTerr);
                        territory += myAddTerr+';';
                    }else {
                        addedTerListExistedInTerVod += myAddTerr+';';
                    }
                }
                Trigger.new[i].Territory_To_Add_vod__c  = null;
            }
            if (Trigger.new[i].Territory_To_Drop_vod__c != null) {
                String [] terrDropSplit = Trigger.new[i].Territory_To_Drop_vod__c.split(';');
                for (String myDropTerr :terrDropSplit) {
                    if ('' == myDropTerr)
                        continue;
                    //System.debug ('Territory to Drop ' + myDropTerr);
                    String terrval = ';'+myDropTerr+';';
                    territory = territory.replaceAll(Pattern.quote(terrval),';');
                    if (';'.equals(territory)) {
                        territory = '';
                    }
                }
                Trigger.new[i].Territory_To_Drop_vod__c = null;
            }
            if (';'.equals(addedTerListExistedInTerVod)) {
                addedTerListExistedInTerVod = '';
            }
            Trigger.new[i].Territory_vod__c = territory;
            // System.debug('List of Territory Added to the HEADER CLASS: ' + addedTerListExistedInTerVod);
            VOD_ACCOUNT_TO_TERRITORY_HEADER_CLASS.setExistingTerritories(Trigger.new[i].Id, addedTerListExistedInTerVod);
            // System.debug ('Territory List After processing ' + Trigger.new[i].Territory_vod__c); 
        } else {
            territory=';';
            addedTerListExistedInTerVod =';';
            if (Trigger.new[i].Territory_To_Add_vod__c != null) {
                String [] terrAddSplit = Trigger.new[i].Territory_To_Add_vod__c.split(';');
                for (String myAddTerr :terrAddSplit) {
                    if ('' == myAddTerr)
                        continue;
                    String terrval = ';'+myAddTerr+';';
                    Integer loc = territory.indexOf(terrval);
                    if (loc == -1) {
                        //System.debug ('Add to Territory' + myAddTerr);
                        territory += myAddTerr+';';
                    }else {
                        addedTerListExistedInTerVod += myAddTerr+';';
                    }
                }
                Trigger.new[i].Territory_To_Add_vod__c  = null;
                if (territory == ';')
                    territory='';
                Trigger.new[i].Territory_vod__c = territory;
            }
            if (Trigger.new[i].Territory_To_Drop_vod__c != null) {
                //System.debug ('Territory to Drop ');    
                String [] terrDropSplit = Trigger.new[i].Territory_To_Drop_vod__c.split(';');
                for (String myDropTerr :terrDropSplit) {
                    if ('' == myDropTerr)
                        continue;
                    //System.debug ('Territory to Drop ' + myDropTerr);
                    String terrval = ';'+myDropTerr+';';
                    territory = territory.replaceAll(Pattern.quote(terrval),';');
                    if (';'.equals(territory)) {
                        territory = '';
                    }
                }
                Trigger.new[i].Territory_To_Drop_vod__c = null;
                if (territory == ';')
                    territory='';
                Trigger.new[i].Territory_vod__c = territory;
            }
        }
    }
    //System.debug ('VOD_ACCOUNT_TO_TERRITORY_BEFORE_TRIGGER ends');
}