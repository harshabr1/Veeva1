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

public with sharing class VEEVA_PRICE_RULE_CLASS {
  public String External_Id_vod;
  public Double Min_val;
  public Double Max_val;
  public Double Product_Minimum;
  public Double Product_Maximum;
  public Date Start_date;
  public Date End_date;
  public String Rule_Name;
  public Date Delivery_Start_date;
  public Date Delivery_End_date;
  public Double Min_Delivery_Time_Frame;
  public String subruleProducts;
  
  public VEEVA_PRICE_RULE_CLASS (String pExternal_Id_vod, Double pMin_val, Double pMax_val) {
    External_Id_vod = pExternal_Id_vod;
    Min_val = pMin_val;
    Max_val = pMax_val;
  }
  public VEEVA_PRICE_RULE_CLASS (String pExternal_Id_vod, Decimal pMin_val, Decimal pMax_val) {
    External_Id_vod = pExternal_Id_vod;
    Min_val = pMin_val;
    Max_val = pMax_val;
  }
  public VEEVA_PRICE_RULE_CLASS (String pExternal_Id_vod, Double pMin_val, Double pMax_val, Double prodMin_val, Double prodMax_val, Date dStart,Date dEnd) {
    External_Id_vod = pExternal_Id_vod;
    Min_val = pMin_val;
    Max_val = pMax_val;
    Product_Minimum = prodMin_val;
    Product_Maximum = prodMax_val;
    Start_date = dStart;
    End_date = dEnd;
  }
  public VEEVA_PRICE_RULE_CLASS (String pExternal_Id_vod, Decimal pMin_val, Decimal pMax_val,Date dStart,Date dEnd) {
    External_Id_vod = pExternal_Id_vod;
    Min_val = pMin_val;
    Max_val = pMax_val;
    Start_date = dStart;
    End_date = dEnd;
  }  
  public VEEVA_PRICE_RULE_CLASS (String pExternal_Id_vod, Decimal pMin_val, Decimal pMax_val,Double prodMin_val, Double prodMax_val,
                                 Date dStart,Date dEnd, String name, Date deliveryStart, Date deliveryEnd, Double minDelivery) {
    External_Id_vod = pExternal_Id_vod;
    Min_val = pMin_val;
    Max_val = pMax_val;
    Start_date = dStart;
    End_date = dEnd;
    Product_Minimum = prodMin_val;
    Product_Maximum = prodMax_val;
    Rule_Name = name;
    Delivery_Start_Date = deliveryStart;
    Delivery_End_Date = deliveryEnd;
    Min_Delivery_Time_Frame = minDelivery;
  }
   
  public String getSubruleProducts() {
    return this.subruleProducts;
  }
    
  public void setSubruleProducts(String subruleProducts) {
    this.subruleProducts = subruleProducts;
  }
    
  public boolean hasOverlappingDeliveryDates(Pricing_Rule_vod__c pr) {
      //if both start and end are null, then only one delivery rule can exist
      if ((pr.Delivery_Start_Date_vod__c == null && pr.Delivery_End_Date_vod__c == null) ||
          (this.Delivery_Start_Date == null && this.Delivery_End_Date == null)) {
              return true;
      }
      
      //check the trigger pricing rule, if either delivery start or end are null
      if (pr.Delivery_Start_Date_vod__c == null) {
          return this.Delivery_Start_Date == null || this.Delivery_Start_Date <= pr.Delivery_End_Date_vod__c;
      }
      if (pr.Delivery_End_Date_vod__c == null) {
          return this.Delivery_End_Date == null || this.Delivery_End_Date >= pr.Delivery_Start_Date_vod__c;
      }
      
      //check the existing pricing rule, if eithe delivery start or end are null
      if (this.Delivery_Start_Date == null) {
          return pr.Delivery_Start_Date_vod__c == null || this.Delivery_End_Date >= pr.Delivery_Start_Date_vod__c;
      }
      if (this.Delivery_End_Date == null) {
          return pr.Delivery_End_Date_vod__c == null || this.Delivery_Start_Date <= pr.Delivery_End_Date_vod__c;
      }
      
      return (pr.Delivery_Start_Date_vod__c >= this.Delivery_Start_Date && pr.Delivery_Start_Date_vod__c <= this.Delivery_End_Date) ||
                (this.Delivery_Start_Date >= pr.Delivery_Start_Date_vod__c && this.Delivery_Start_Date <= pr.Delivery_End_Date_vod__c);
  }
    
  public static String getBaseExternalId(Pricing_Rule_vod__c pr, RecordType freeGoodsType, RecordType freeGoodsPercentType,
                                         RecordType deliveryPeriodType, RecordType paymentType) {
      SObject prInterface = (SObject)pr;
      String Currcode  = '';
      try {
          Currcode = (String)prInterface.get('CurrencyIsoCode');
      } catch ( System.SObjectException e) {
      }
      
      String oldExternalId;
      if(pr.RecordTypeId == freeGoodsPercentType.Id) {
          oldExternalId = freeGoodsType.Id + '__';
      } else {
          oldExternalId = pr.RecordTypeId + '__';    
      }
      if (pr.RecordTypeId == deliveryPeriodType.Id) {
          oldExternalId += (pr.Min_Delivery_Time_Frame_vod__c != null);
      } else if (pr.RecordTypeId != paymentType.Id) {
          oldExternalId += pr.Comparison_Type_vod__c + '__';
      }
      oldExternalId += Currcode +'__'+
          pr.Product_vod__c + '__' +
          pr.Account_vod__c+ '__' +
          pr.Account_Group_vod__c +'__' +
          pr.Order_Campaign_vod__c +'__'+
          pr.Pricing_Group_vod__c +'__' +
          pr.Comparison_Product_vod__c + '__' +
          pr.Cross_Product_Rule_vod__c;

      if(pr.Price_Book_vod__c != null) {
        oldExternalId += '__' + pr.Price_Book_vod__c;
      }
                                             
      return oldExternalId;       
  }
  
}