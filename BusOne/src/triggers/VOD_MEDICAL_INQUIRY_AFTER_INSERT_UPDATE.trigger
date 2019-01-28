trigger VOD_MEDICAL_INQUIRY_AFTER_INSERT_UPDATE on Medical_Inquiry_vod__c (after insert, after update) {

    // check if the medical inquiry fulfillment record has access
    //boolean hasMIFAccess = Schema.getGlobalDescribe().get('Medical_Inquiry_Fulfillment_vod__c').getDescribe();
    Schema.DescribeSObjectResult drSObj = Schema.sObjectType.Medical_Inquiry_Fulfillment_vod__c;
    Boolean thisUserMayRead = drSObj.isAccessible();
    
    // feature turned on check
    if (thisUserMayRead) {
   
        // add a new list to add the medical inquiry fulfillment records
        List <Medical_Inquiry_Fulfillment_vod__c> mIFList =  new  List <Medical_Inquiry_Fulfillment_vod__c> ();
    
        String currentUserId = System.Userinfo.getUserId();   
        system.debug(' user id is  ' + currentUserId );  
    
        // get the med Inq id
        Set<Id> medInqIds = new Set<Id> ();
        for (Integer i = 0; i <Trigger.new.size(); i++) {
            medInqIds.add(Trigger.new[i].Id);    
        }  
    
        // now query the MIF to get all the record for which the MIF was created to handle un lock and submit scenario
        List<Medical_Inquiry_Fulfillment_vod__c> mIFRecords = new List<Medical_Inquiry_Fulfillment_vod__c >([SELECT Id, Medical_Inquiry_vod__c FROM Medical_Inquiry_Fulfillment_vod__c WHERE Medical_Inquiry_vod__c IN :medInqIds]);
        Set<Id> createdmedInqIds = new Set<Id> ();
        if (mIFRecords != null && mIFRecords.size() > 0) {
            for (Medical_Inquiry_Fulfillment_vod__c record : mIFRecords) {
                createdmedInqIds.add(record.Medical_Inquiry_vod__c);      
            }    
        } 
    
        system.debug(' medical inquiry records for which the MIF exists ' + createdmedInqIds);   
        // to update the status of medical inqury
        List<Medical_Inquiry_vod__c> medInqsUpdate = new List<Medical_Inquiry_vod__c>();  
        
        // get the record type map
        Map<String, String> MIFRTMap = new Map<String, String> ();
        
        for (RecordType recType : [Select Id, DeveloperName From RecordType Where SObjectType='Medical_Inquiry_Fulfillment_vod__c' and IsActive=true]) {
            MIFRTMap.put(recType.DeveloperName, recType.Id);     
        }
        
        // get the user name from the veeva settings
        Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();   
        String userNameInSettings = vsc.Medical_Inquiry_Fulfillment_Default_vod__c;
        system.debug('user id in the veeva setting is  ' + userNameInSettings); 
        
        // get the user id
        List<SObject> currentUserRec = null;
        if (userNameInSettings != null && userNameInSettings != '') {
            system.debug(' the user settings had the following value  ' + userNameInSettings);   
            String query = 'Select  Id, Name, Username from User where Username LIKE \'%' + userNameInSettings + '%\'';   
            currentUserRec = Database.query(query);
            system.debug(' after query with invalid value ' + currentUserRec);  
        } 
        
        // query to get account name        
       
        List<String> medInIds = new List <String> ();
        List<String> assignToUserIds = new List<String> ();
        for (Integer i = 0; i <Trigger.new.size(); i++) {
            medInIds.add(Trigger.new[i].Account_vod__c); 
            if (Trigger.new[i].Assign_To_User_vod__c!= null) {
                assignToUserIds.add(Trigger.new[i].Assign_To_User_vod__c);
            }                       
        }
        
        // add the user id from veeva setting 
        if (currentUserRec  != null && currentUserRec.size() > 0) {
            assignToUserIds.add(currentUserRec[0].Id);        
        }        
        
        List<Account> acts = [Select Id, Name From Account where Id =: medInIds ]; 
        Map<String, String> accountIdName = new Map<String, String> ();
        for (Account act: acts) {
            accountIdName.put(act.Id, act.Name);        
        }
        
        Set<String> activeUserIdsWithPermission = new Set<String>();
        for (PermissionSetAssignment assignment : [
              SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN
                        (SELECT ParentId FROM ObjectPermissions WHERE SObjectType = 'Medical_Inquiry_Fulfillment_vod__c' and PermissionsCreate = true)
                    AND AssigneeId IN
                        (SELECT Id FROM User WHERE Id in :assignToUserIds AND IsActive=true)]) {

            activeUserIdsWithPermission.add(assignment.AssigneeId);
        }
         
    
        for (Integer i = 0; i <Trigger.new.size(); i++) {
    
            Medical_Inquiry_vod__c medInqNew = Trigger.new[i];    
            //Medical_Inquiry_vod__c medInqUpdate = new Medical_Inquiry_vod__c ();             
            system.debug(' status new med inquiry ' + medInqNew.Status_vod__c);
        
            system.debug(' previously submitted value of medical inquiry ' + medInqNew.Previously_Submitted_vod__c);        
            if (createdmedInqIds.contains(medInqNew.Id)) { // if the medical inquiry was submitted already we will not create new MIF
                continue;
            } 
            // here create a medical inquiry fulfillment 
            if (medInqNew.Status_vod__c == 'Submitted_vod' && !medInqNew.Fulfillment_Created_vod__c) {
                
                String actName = accountIdName.get(medInqNew.Account_vod__c);
                system.debug(' the value of the account display name is ' + actName);
                Medical_Inquiry_Fulfillment_vod__c insMIF = new Medical_Inquiry_Fulfillment_vod__c (Account_vod__c= medInqNew.Account_vod__c,
                                              Address_Line_1_vod__c = medInqNew.Address_Line_1_vod__c,
                                              Address_Line_2_vod__c = medInqNew.Address_Line_2_vod__c,
                                              Account_Display_Name_vod__c = actName,
                                              City_vod__c = medInqNew.City_vod__c,
                                              Call_vod__c = medInqNew.Call2_vod__c,
                                              Country_vod__c = medInqNew.Country_vod__c,
                                              Delivery_Method_vod__c = medInqNew.Delivery_Method_vod__c,
                                              Email_vod__c = medInqNew.Email_vod__c,                                              
                                              Fax_Number_vod__c = medInqNew.Fax_Number_vod__c,
                                              Initiated_By_vod__c = currentUserId,
                                              Inquiry_Text_vod__c = medInqNew.Inquiry_Text__c,
                                              Medical_Inquiry_vod__c = medInqNew.Id,
                                              Phone_Number_vod__c = medInqNew.Phone_Number_vod__c,
                                              Product_vod__c = medInqNew.Product__c,
                                              Rush_Delivery_vod__c = medInqNew.Rush_Delivery__c,
                                              Initiated_Datetime_vod__c = Datetime.now(),
                                              State_vod__c = medInqNew.State_vod__c,
                                              Zip_vod__c = medInqNew.Zip_vod__c);       
                 
                
                // create only if the user is not null and has read permission
                // add a flag to see even if we are creating mif
                boolean isMIF = false;
                if (medInqNew.Assign_To_User_vod__c != null && activeUserIdsWithPermission.contains(medInqNew.Assign_To_User_vod__c)) {
                    insMIF.Status_vod__c = 'Assigned_vod';
                    insMIF.OwnerId = medInqNew.Assign_To_User_vod__c;
                    insMIF.Assigned_To_vod__c = medInqNew.Assign_To_User_vod__c;
                    isMIF = true;                    
                    system.debug(' added MIF ' + insMIF);                                            
                } else {
                  // check if there is a value exists in the veeva setting and the user has right access
                    if (currentUserRec  != null && currentUserRec.size() > 0 && activeUserIdsWithPermission.contains(currentUserRec[0].Id)) {
                        insMIF.Status_vod__c = 'New_vod';
                          insMIF.OwnerId = currentUserRec[0].Id;
                          insMIF.Assigned_To_vod__c = currentUserRec[0].Id;  
                          isMIF = true;                          
                          system.debug(' added MIF ' + insMIF);                                    
                    }                  
                }
                // add record type and add in the list
                if (isMIF) {
                    // update the record type id based on the pick list value of the delivery method                    
                    String mifRecordtypeId = null;
                    if (medInqNew.Delivery_Method_vod__c == 'Urgent_Mail_vod') {
                        mifRecordtypeId = MIFRTMap.get('Mail_vod');                                  
                    } else {                
                        mifRecordtypeId = MIFRTMap.get(medInqNew.Delivery_Method_vod__c);                    
                    }                    
                    if (mifRecordtypeId != null) {   
                        insMIF.RecordTypeId = mifRecordtypeId;
                    }                     
                    mIFList.add(insMIF);             
                }            
                                              
            } 
    
        }
    
        if (mIFList.size() > 0) {
            system.debug('the values before update med Inq' + mIFList);
            upsert mIFList;
            system.debug('the values after update med Inq' + mIFList);
            //update medInqsUpdate;
            
        }
    
    }
    
      

}