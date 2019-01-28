trigger VOD_MEDICAL_INQUIRY_TO_AUDIT on Medical_Inquiry_vod__c (before delete, before update) {
    
    List <Medical_Inquiry_Audit_vod__c> miaList = new List <Medical_Inquiry_Audit_vod__c> ();
    
    String action = Trigger.isUpdate ? 'U' : 'D';
    
    for (Integer i = 0; i < Trigger.old.size (); i++) {
        boolean toAudit = false;
        if (Trigger.isUpdate) {
            toAudit = Trigger.old[i].Previously_Submitted_vod__c || Trigger.new[i].Status_vod__c == 'Submitted_vod' || Trigger.old[i].Status_vod__c == 'Submitted_vod';
        }
        else {
            toAudit = Trigger.isDelete;
        }
        if (!toAudit) 
            continue;
        
        System.Debug(Trigger.old[i]);
        Medical_Inquiry_vod__c mi = Trigger.old[i];
        Medical_Inquiry_Audit_vod__c  miaudit = new Medical_Inquiry_Audit_vod__c (
            Account_vod__c = mi.Account_vod__c,
            Action_vod__c = action,
            Address_Line_1_vod__c = mi.Address_Line_1_vod__c,
            Address_Line_2_vod__c = mi.Address_Line_2_vod__c,
            Call2_vod__c = mi.Call2_vod__c,
            City_vod__c = mi.City_vod__c,
            Country_vod__c = mi.Country_vod__c,
            Delivery_Method_vod__c = mi.Delivery_Method_vod__c,
            Disclaimer_vod__c = mi.Disclaimer_vod__c,
            Email_vod__c = mi.Email_vod__c,
            Entity_Reference_Id_vod__c = mi.Entity_Reference_Id_vod__c,
            Fax_number_vod__c = mi.Fax_Number_vod__c,
            Group_Identifier_vod__c = mi.Group_Identifier_vod__c,
            Inquiry_text__c = mi.Inquiry_Text__c,
            Lock_vod__c = mi.Lock_vod__c,
            Medical_Inquiry_Id_vod__c = mi.Id,
            Phone_Number_vod__c = mi.Phone_Number_vod__c,
            Product__c = mi.Product__c,
            Request_Receipt_vod__c = mi.Request_Receipt_vod__c,
            Rush_delivery__c = mi.Rush_Delivery__c,
            Signature_Date_vod__c = mi.Signature_Date_vod__c,
            Signature_vod__c = mi.Signature_vod__c,
            State_vod__c = mi.State_vod__c,
            Status_vod__c = mi.Status_vod__c,
            Submitted_by_Mobile_vod__c = mi.Submitted_by_Mobile_vod__c,
            Zip_vod__c = mi.Zip_vod__c
        );
        
        miaList.add (miaudit);
    }
    
    if (miaList.size () > 0)
        insert miaList;   
}