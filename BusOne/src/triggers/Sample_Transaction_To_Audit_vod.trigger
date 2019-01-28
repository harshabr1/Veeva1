trigger Sample_Transaction_To_Audit_vod on Sample_Transaction_vod__c (before delete, before update) {

            List <Sample_Transaction_Audit_vod__c> staList = new List <Sample_Transaction_Audit_vod__c> ();

            Map <Id, Sample_Transaction_vod__c> transMap =
                 new Map <Id, Sample_Transaction_vod__c> (
                                 [Select Adjust_For_vod__c,
                                         Adjust_For_vod__r.Name,
                                         Address_Line_1_vod__c,
                                         Address_Line_2_vod__c,
                                         State_vod__c,
                                         Sample_Card_vod__c,
                                         Adjusted_Date_vod__c,
                                         Call_Name_vod__c,
                                         City_vod__c,
                                         Comments_vod__c,
                                         Confirmed_Quantity_vod__c,
                                         CreatedById,
                                         CreatedBy.Name,
                                         Disbursed_To_vod__c,
                                         Disclaimer_vod__c,
                                         Discrepancy_vod__c,
                                         Id,
                                         Inventory_Impact_Quantity_vod__c,
                                         LastModifiedById,
                                         LastModifiedBy.Name,
                                         LastModifiedDate,
                                         Lot_Name_vod__c,
                                         Lot_vod__c,
                                         Lot_vod__r.Name,
                                         Name,
                                         Quantity_vod__c,
                                         Reason_vod__c,
                                         Receipt_Comments_vod__c,
                                         Return_To_vod__c,
                                         Sample_vod__c,
                                         Shipment_Id_vod__c,
                                         Signature_Date_vod__c,
                                         Signature_vod__c,
                                         Status_vod__c,
                                         Submitted_Date_vod__c,
                                         Transfer_To_Name_vod__c,
                                         Transfer_To_vod__c,
                                         Transfer_To_vod__r.Name,
                                         Transferred_Date_vod__c,
                                         Transferred_From_Name_vod__c,
                                         Transferred_From_vod__c,
                                         Transferred_From_vod__r.Name,
                                         Type_vod__c,
                                         U_M_vod__c,
                                         Unlock_vod__c,
                                         Zip_vod__c,
                                         Received_vod__c,
                                         Zip_4_vod__c,
                                         Call_Date_vod__c,
                                         Call_Datetime_vod__c,
                                         DEA_vod__c,
                                         Sample_Card_Reason_vod__c,
                                         ASSMCA_vod__c,
                                         DEA_Expiration_Date_vod__c,
                                         Account_vod__c,
                                         Group_Transaction_Id_vod__c,
                                         Request_Receipt_vod__c,
                                         Group_Identifier_vod__c,
                                         License_vod__c,
                                         License_Expiration_Date_vod__c,
                                         License_Status_vod__c,
                                         Credentials_vod__c,
                                         Salutation_vod__c,
                                         Manufacturer_vod__c,
                                         Distributor_vod__c,
                                         CDS_vod__c,
                                         CDS_Expiration_Date_vod__c,
                                         Tag_Alert_Number_vod__c,
                                         Cold_Chain_Status_vod__c,
                                         Custom_Text_vod__c,
                                         Signature_Page_Display_Name_vod__c,
                                         State_Distributor_vod__c,
                                         State_Distributor_Expiration_Date_vod__c
                                         from Sample_Transaction_vod__c where Id in :Trigger.old] );



            for (Integer i = 0; i < Trigger.old.size (); i++) {
                Sample_Transaction_vod__c  st = transMap.get (Trigger.old[i].Id);
                System.debug (st);
                String action;
                if (Trigger.isUpdate) {
                    action = 'U';
                }  else
                    action =  'D';


                Sample_Transaction_Audit_vod__c  staudit = new Sample_Transaction_Audit_vod__c (
                                                              Action_vod__c = action,
                                                              Adjust_For_Name_vod__c=    st.Adjust_For_vod__r.Name,
                                                              Adjusted_Date_vod__c=  st.Adjusted_Date_vod__c,
                                                              Address_Line_1_vod__c = st.Address_Line_1_vod__c,
                                                              Address_Line_2_vod__c= st.Address_Line_2_vod__c,
                                                              Call_Name_vod__c = st.Call_Name_vod__c,
                                                              City_vod__c=   st.City_vod__c,
                                                              Comments_vod__c=   st.Comments_vod__c,
                                                              Confirmed_Quantity_vod__c=     st.Confirmed_Quantity_vod__c,
                                                              Disbursed_To_vod__c=   st.Disbursed_To_vod__c,
                                                              Disclaimer_vod__c=     st.Disclaimer_vod__c,
                                                              Discrepancy_vod__c=    st.Discrepancy_vod__c,
                                                              Inventory_Impact_Quantity_vod__c=  st.Inventory_Impact_Quantity_vod__c,
                                                              Lot_vod__c = st.Lot_vod__r.Id,
                                                              Lot_Name_vod__c=   st.Lot_vod__r.Name,
                                                              Quantity_vod__c=   st.Quantity_vod__c,
                                                              Reason_vod__c=     st.Reason_vod__c,
                                                              Receipt_Comments_vod__c=   st.Receipt_Comments_vod__c,
                                                              Return_To_vod__c=  st.Return_To_vod__c,
                                                              Sample_vod__c=     st.Sample_vod__c,
                                                              Shipment_Id_vod__c=    st.Shipment_Id_vod__c,
                                                              Signature_Date_vod__c=     st.Signature_Date_vod__c,
                                                              Signature_vod__c=  st.Signature_vod__c,
                                                              Status_vod__c=     st.Status_vod__c,
                                                              State_vod__c = st.State_vod__c,
                                                              Submitted_Date_vod__c=     st.Submitted_Date_vod__c,
                                                              Transaction_Created_By_vod__c=    st.CreatedById,
                                                              Transaction_Id_vod__c=    st.Name,
                                                              Transaction_Modified_By_vod__c=   st.LastModifiedById,
                                                              Transfer_To_Name_vod__c=   st.Transfer_To_vod__r.Name,
                                                              Transferred_Date_vod__c=   st.Transferred_Date_vod__c,
                                                              Transferred_From_Name_vod__c=  st.Transferred_From_vod__r.Name,
                                                              Type_vod__c=   st.Type_vod__c,
                                                              U_M_vod__c=    st.U_M_vod__c,
                                                              Sample_Card_vod__c  = st.Sample_Card_vod__c,
                                                              Zip_vod__c =   st.Zip_vod__c,
                                                              Zip_4_vod__c =   st.Zip_4_vod__c,
                                                              Call_Date_vod__c = st.Call_Date_vod__c,
                                                              Call_Datetime_vod__c = st.Call_Datetime_vod__c,
                                                              DEA_vod__c = st.DEA_vod__c,
                                                              Sample_Card_Reason_vod__c = st.Sample_Card_Reason_vod__c,
                                                              ASSMCA_vod__c = st.ASSMCA_vod__c,
                                                              DEA_Expiration_Date_vod__c = st.DEA_Expiration_Date_vod__c,
                                                              Account_vod__c = st.Account_vod__c,
                                                              Group_Transaction_Id_vod__c = st.Group_Transaction_Id_vod__c,
                                                              Group_Identifier_vod__c  = st.Group_Identifier_vod__c,
                                                              Request_Receipt_vod__c = st.Request_Receipt_vod__c,
                                                              License_vod__c = st.License_vod__c,
                                                              License_Expiration_Date_vod__c = st.License_Expiration_Date_vod__c, // added for call stamping CRM-28538
                                                              License_Status_vod__c = st.License_Status_vod__c, // added for call stamping CRM-28538
                                                              Credentials_vod__c = st.Credentials_vod__c,
                                                              Salutation_vod__c = st.Salutation_vod__c,
                                                              Manufacturer_vod__c = st.Manufacturer_vod__c,
                                                              Distributor_vod__c = st.Distributor_vod__c,
                                                              CDS_vod__c = st.CDS_vod__c,
                                                              CDS_Expiration_Date_vod__c = st.CDS_Expiration_Date_vod__c,
                                                              Tag_Alert_Number_vod__c = st.Tag_Alert_Number_vod__c,
                                                              Cold_Chain_Status_vod__c = st.Cold_Chain_Status_vod__c,
                                                              Custom_Text_vod__c = st.Custom_Text_vod__c,
                                                              Signature_Page_Display_Name_vod__c = st.Signature_Page_Display_Name_vod__c,
                                                              State_Distributor_vod__c = st.State_Distributor_vod__c,
                                                              State_Distributor_Expiration_Date_vod__c = st.State_Distributor_Expiration_Date_vod__c                                                              
                                                              );

            staList.add (staudit);

            }

            if (staList.size () > 0)
                insert staList;

        }