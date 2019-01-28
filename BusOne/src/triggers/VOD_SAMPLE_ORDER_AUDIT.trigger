trigger VOD_SAMPLE_ORDER_AUDIT on Sample_Order_Transaction_vod__c (before update, before delete) {

 Map<String, Schema.SObjectField> sampleOrderFieldMap = Schema.SObjectType.Sample_Order_Transaction_vod__c .fields.getMap();
 Map<String, Schema.SObjectField> sampleOrderAuditFieldMap = Schema.SObjectType.Sample_Order_Transaction_Audit_vod__c.fields.getMap();

   Sample_Order_Transaction_vod__c [] triggerObjects = null;
 
 if (Trigger.IsUpdate) {
    triggerObjects = Trigger.new;
 } else {
    triggerObjects  = Trigger.old;
 }

 List<Sample_Order_Transaction_vod__c> rows = [Select Account_Id_vod__c,
                        Name, 
                        Id, 
                        Account_Name_vod__c, 
                        Call_Name_vod__c,
                        Call_Id_vod__c,
                        Call_Sample_Id_vod__c,
                        Call_Sample_Name_vod__c,
                        Comments_vod__c,
                        Delivery_Status_vod__c, 
                        Disclaimer_vod__c, 
                        Discrepancy_vod__c, 
                        Distributor_vod__c, 
                        Quantity_vod__c, 
                        Confirmed_Quantity_vod__c,  
                        RecordTypeId, 
                        Sample_U_M__c, 
                        Sample_vod__c, 
                        Ship_Address_Line_1_vod__c, 
                        Ship_Address_Line_2_vod__c, 
                        Ship_City_vod__c, 
                        Ship_Country_vod__c, 
                        Ship_License_Expiration_Date_vod__c, 
                        Ship_License_Status_vod__c, 
                        Ship_License_vod__c, 
                        Ship_Location_vod__c,
                        Ship_State_vod__c, 
                        Ship_Zip_vod__c, 
                        Shipment_Id_vod__c, 
                        Signature_Date_vod__c, 
                        Signature_vod__c, 
                        Status_vod__c, 
                        Territory_vod__c,
                        Ship_Zip_4_vod__c,
                        Unlock_vod__c,
                        Call_Date_vod__c,
                        Call_Datetime_vod__c,
                        DEA_vod__c,
                        Sample_Card_Reason_vod__c,
                        ASSMCA_vod__c,
                        DEA_Expiration_Date_vod__c,
                        Account_vod__c,
                        Request_Receipt_vod__c,
                        Sample_Send_Card_vod__c,
                        Credentials_vod__c,
                        Salutation_vod__c,
                        Manufacturer_vod__c,
                        Ship_CDS_vod__c,
                        Ship_CDS_Expiration_Date_vod__c,
                        Custom_Text_vod__c,
                        Signature_Page_Display_Name_vod__c,
                        Ship_State_Distributor_vod__c,
                        Ship_State_Distributor_Exp_Date_vod__c
                        from Sample_Order_Transaction_vod__c s where Id in :triggerObjects];
     
 List< Sample_Order_Transaction_Audit_vod__c > rowsToAdd = new  List< Sample_Order_Transaction_Audit_vod__c >();
 for (Sample_Order_Transaction_vod__c obj : rows) {
 
    
    String action ='U';
    if (Trigger.IsDelete)
        action ='D'; 
    Sample_Order_Transaction_Audit_vod__c newAuditObj 
          = new Sample_Order_Transaction_Audit_vod__c (
                            Action_vod__c = action,
                            Transaction_Id_vod__c = obj.Id, 
                            Account_Id_vod__c = obj.Account_Id_vod__c,
                            Account_Name_vod__c = obj.Account_Name_vod__c, 
                            Call_Name_vod__c = obj.Call_Name_vod__c,
                            Call_Sample_Name_vod__c = obj.Call_Sample_Name_vod__c,
                            Call_Sample_Id_vod__c = obj.Call_Sample_Id_vod__c,
                            Call_Id_vod__c = obj.Call_Id_vod__c,
                            Comments_vod__c = obj.Comments_vod__c,
                            Delivery_Status_vod__c = obj.Delivery_Status_vod__c, 
                            Disclaimer_vod__c = obj.Disclaimer_vod__c, 
                            Discrepancy_vod__c = obj.Discrepancy_vod__c, 
                            Distributor_vod__c = obj.Distributor_vod__c, 
                            Quantity_vod__c = obj.Quantity_vod__c, 
                            Confirmed_Quantity_vod__c = obj.Confirmed_Quantity_vod__c,  
                            Sample_U_M__c = obj.Sample_U_M__c, 
                            Sample_vod__c = obj.Sample_vod__c, 
                            Ship_Address_Line_1_vod__c = obj.Ship_Address_Line_1_vod__c, 
                            Ship_Address_Line_2_vod__c = obj.Ship_Address_Line_2_vod__c, 
                            Ship_City_vod__c = obj.Ship_City_vod__c, 
                            Ship_Country_vod__c = obj.Ship_Country_vod__c, 
                            Ship_License_Expiration_Date_vod__c = obj.Ship_License_Expiration_Date_vod__c, 
                            Ship_License_Status_vod__c = obj.Ship_License_Status_vod__c, 
                            Ship_License_vod__c = obj.Ship_License_vod__c, 
                            Ship_Location_vod__c = obj.Ship_Location_vod__c,
                            Ship_State_vod__c = obj.Ship_State_vod__c, 
                            Ship_Zip_vod__c = obj.Ship_Zip_vod__c, 
                            Shipment_Id_vod__c = obj.Shipment_Id_vod__c, 
                            Signature_Date_vod__c = obj.Signature_Date_vod__c, 
                            Signature_vod__c = obj.Signature_vod__c, 
                            Status_vod__c = obj.Status_vod__c,
                            Call_Date_vod__c = obj.Call_Date_vod__c,
                            Call_Datetime_vod__c = obj.Call_Datetime_vod__c,
                            DEA_vod__c = obj.DEA_vod__c,
                            Sample_Card_Reason_vod__c = obj.Sample_Card_Reason_vod__c,
                            ASSMCA_vod__c = obj.ASSMCA_vod__c,
                            DEA_Expiration_Date_vod__c = obj.DEA_Expiration_Date_vod__c,
                            Account_vod__c = obj.Account_vod__c,
                            Territory_vod__c = obj.Territory_vod__c,
                            Request_Receipt_vod__c = obj.Request_Receipt_vod__c,
                            Sample_Send_Card_vod__c = obj.Sample_Send_Card_vod__c,
                            Credentials_vod__c = obj.Credentials_vod__c,
                            Salutation_vod__c = obj.Salutation_vod__c,
                            Manufacturer_vod__c = obj.Manufacturer_vod__c,
                            Ship_CDS_vod__c = obj.Ship_CDS_vod__c,
                            Ship_CDS_Expiration_Date_vod__c = obj.Ship_CDS_Expiration_Date_vod__c,
                            Custom_Text_vod__c = obj.Custom_Text_vod__c,
                            Signature_Page_display_Name_vod__c = obj.Signature_Page_Display_Name_vod__c,
                            Ship_State_Distributor_vod__c = obj.Ship_State_Distributor_vod__c,
                            Ship_State_Distributor_Exp_Date_vod__c = obj.Ship_State_Distributor_Exp_Date_vod__c                            
                            
            );    
            
    rowsToAdd.add(newAuditObj);
 }
   
   if (rowsToAdd.size() > 0) {
     try {
            insert rowsToAdd;
        }   catch (System.DmlException e) {
            Integer numErrors = e.getNumDml();
            String error = '';
            for (Integer i = 0; i < numErrors; i++) {
                Id thisId = e.getDmlId(i);
                if (thisId != null)  {
                    error += thisId + ' - ' + e.getDmlMessage(i) + '<br>';
                }
            }
            
            for (Sample_Order_Transaction_vod__c errorRec : triggerObjects) {
                errorRec.Id.addError(error, false);
            }
        }
    
   }
 
}