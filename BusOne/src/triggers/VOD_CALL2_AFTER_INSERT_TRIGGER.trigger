trigger VOD_CALL2_AFTER_INSERT_TRIGGER on Call2_vod__c (after insert) {
    System.debug ('Number of Insert Transactions = ' + Trigger.new.size ());
 
    Map <Id, Call2_vod__c> parents = null;
    Map<Id,Account> accounts = null;
    
    List <String> parentIds = new List <String> ();
    List <Call2_Detail_vod__c> detsToAdd = new List<Call2_Detail_vod__c> ();
    List <Call2_vod__c> hdrUpdList = new List <Call2_vod__c> ();
    List <Call2_Key_Message_vod__c> keysToAdd = new List <Call2_Key_Message_vod__c> ();
    List <Id> accountsList = new List<Id>();    
    
    Set <String> callsWithTrans = new Set <String> ();
    Set <String> callsWithOrders = new Set <String> ();
    Map<Id,Product_vod__c> products = null;
    List<Sample_Lot_vod__c> sampleLots = null;
    Set<String> productIds = new Set<String>();
    Set<String> lotNums = new Set<String>();
    Set<String> ownerIDs = new Set<String>();
    
    VOD_CALL2_HEADER_CLASS.setInsertAction (true); 
    Call2_vod__c [] triggerCalls =  Trigger.new;

    VOD_CALL2_ATTACHMENT_CLASS.updateReceiptAttachmentsPending(Trigger.newMap);
            
    // obtain the list of record type ids
    
    RecordType[] recTypes = VOD_CALL2_HEADER_CLASS.getRecordTypes();
       
    String eventRecTypeId = '';
    String sampleRecTypeId = '';
    for (RecordType recType : recTypes) {
        if (recType.SobjectType == 'Event')
            eventRecTypeId = recType.Id;
        else if (recType.SobjectType == 'Sample_Transaction_vod__c')
            sampleRecTypeId = recType.Id;
    }

    // Get a list of all the parent calls
    for (Integer i = 0; i < triggerCalls.size(); i++) {
        Call2_vod__c thisCall = triggerCalls[i];
        if (thisCall.Parent_Call_vod__c != null) {
            parentIds.add(thisCall.Parent_Call_vod__c);
        }
        
        if (thisCall.Account_vod__c != null) {
            accountsList.add (thisCall.Account_vod__c); 
        }
    }
    Map <Id, Call2_vod__c> callMap = null;
    
    List <String> callNames = new List <String> ();
     for (Integer i = 0; i < Trigger.new.size(); i++) {
        Call2_vod__c thisCall = Trigger.new[i];

        if (thisCall.Parent_Call_vod__c != null) {
            parentIds.add(thisCall.Parent_Call_vod__c);
        }
        
        if (thisCall.Account_vod__c != null) {
            accountsList.add (thisCall.Account_vod__c); 
        }       
        callNames.add (thisCall.Name);  
    }
            
    accounts = new Map<Id,Account>([Select Id,Name,Credentials_vod__c,Salutation,(Select License_vod__c,State_vod__c From Address_vod__r order by Primary_vod__c) From Account Where Id in :accountsList]);
                                            
    parents = new Map <Id, Call2_vod__c> 
                  ([Select Id, 
                        Address_vod__c,
                        License_vod__c,
                        Parent_Address_vod__c,
                        (Select Detail_Priority_vod__c, Product_vod__c
                        From Call2_Detail_vod__r), 
                        (Select Product_vod__c, Key_Message_vod__c,
                                Reaction_vod__c, Category_vod__c, Vehicle_vod__c  
                        From Call2_Key_Message_vod__r)
                   From Call2_vod__c where Id in :parentIds]);
                   
            
   
    for (Integer k = 0; k < triggerCalls.size (); k++) {
        Call2_vod__c mainCall = triggerCalls[k];
        // Parent Call just takes the values in the Add_Detail_vod__c field and populates the
        // details.
        String addDetails = mainCall.Add_Detail_vod__c;
        String addKeyMsg =  mainCall.Add_Key_Message_vod__c;
    
        // We have details to insert
        System.debug (addDetails);
        // Reset helper fields back to initial state
        Call2_vod__c updCallHdr = 
                new Call2_vod__c (Id = mainCall.Id,
                                Add_Detail_vod__c = null,
                                Add_Key_Message_vod__c = null,
                                Override_Lock_vod__c = false);
                                                       
        if ( addDetails != null || addKeyMsg != null || mainCall.Override_Lock_vod__c == true)                                                                  
            hdrUpdList.add (updCallHdr);
                                   
        if (addDetails != null) {
            String [] dets = addDetails.split(',');
                   
            for (Integer it = 0; it < dets.size(); it++) {
               Double priority  = it + 1;
               String [] detParts = dets[it].Split(';;');
               String[] prodKey = detParts[0].Split('_');               
               String productId = null;
               String prodGroupId = null;
               if(prodKey.size() > 1)
               {
                   productId = prodKey[1];
                   prodGroupId = prodKey[0];
                   System.Debug(prodGroupId);
                   System.Debug(productId);
               }
               else
               {                                  
                   productId = prodKey[0];
                   System.Debug(productId);
                   System.Debug(prodGroupId);
               }
               Call2_Detail_vod__c call_det;
               if(detParts.size()>1)
                    call_det =
                        new Call2_Detail_vod__c (Detail_Priority_vod__c = priority,
                                            Product_vod__c = productId ,
                                            Detail_Group_vod__c = prodGroupId,
                                            Type_vod__c = detParts[1],
                                            Call2_vod__c = mainCall.Id,
                                            Override_Lock_vod__c = mainCall.Override_Lock_vod__c);
                else
                     call_det =
                        new Call2_Detail_vod__c (Detail_Priority_vod__c = priority,
                                            Product_vod__c = productId ,
                                            Detail_Group_vod__c = prodGroupId,
                                            Type_vod__c = 'Paper_Detail_vod',
                                            Call2_vod__c = mainCall.Id,
                                            Override_Lock_vod__c = mainCall.Override_Lock_vod__c);                                               
                detsToAdd.add (call_det);  
            }  
        }
                
        if (addKeyMsg != null) {
            System.debug ('Key Message = ' + addKeyMsg);
            String [] lines = addKeyMsg.split(';;;');
            System.debug ('# of lines = ' + lines.size());
            if (lines != null) {
                boolean error = false;
                                            
                for (Integer l = 0; l < lines.size(); l++ ) {
                    System.debug ('Line # = ' + l + ' = ' + lines[l]);
                    Call2_Key_Message_vod__c newKeyMsg = 
                            new Call2_Key_Message_vod__c (Call2_vod__c  = mainCall.Id,
                                                   Account_vod__c = mainCall.Account_vod__c,
                                                   Contact_vod__c = mainCall.Contact_vod__c,
                                                   Call_Date_vod__c = mainCall.Call_Date_vod__c,
                                                   User_vod__c = mainCall.User_vod__c,
                                                   Override_Lock_vod__c = mainCall.Override_Lock_vod__c);
                
                    String [] fields = lines[l].split('@@');
                    if(fields[0] != null  && fields[0] != '')
                        newKeyMsg.Key_Message_vod__c = fields[0];   
                    if (fields.size() > 1) { 
                        if ( fields[1] != null && fields[1] != '') {
                           String[] prodKey = fields[1].Split('_');
                            String productId = '';
                            String prodGroupId = null;
                            if(prodKey.size() > 1)
                            {
                                productId = prodKey[1];
                                prodGroupId = prodKey[0];
                                System.Debug(productId);
                                System.Debug(prodGroupId);
                            }
                            else
                            {
                                productId = prodKey[0];
                                System.Debug(productId);
                            }
                            newKeyMsg.Product_vod__c     = productId;
                            newKeyMsg.Detail_Group_vod__c = prodGroupId;
                         }
                    }
                    if (fields.size() > 2)   
                        newKeyMsg.Reaction_vod__c = fields[2];
                    if (fields.size() > 3)
                        newKeyMsg.Category_vod__c = fields[3];
                    if (fields.size() > 4)
                        newKeyMsg.Vehicle_vod__c = fields[4];                       
                    if (fields.size() > 5 && fields[5]!='')
                        newKeyMsg.Start_Time_vod__c = DateTime.valueOfGmt(fields[5]);
                    if (fields.size() > 6 && fields[6]!='')
                        newKeyMsg.Duration_vod__c = Double.valueOf(fields[6]);
                    if (fields.size() > 7)
                        newKeyMsg.CLM_ID_vod__c = fields[7];
                    if (fields.size() > 8)
                        newKeyMsg.Presentation_ID_vod__c = fields[8];
                    if (fields.size() > 9)
                        newKeyMsg.Slide_Version_vod__c = fields[9];                        
                    if (fields.size() > 10)
                        newKeyMsg.Segment_vod__c = fields[10];
                    if (fields.size() > 11 && fields[11]!='')
                        newKeyMsg.Display_Order_vod__c = Double.valueOf(fields[11]);
                    if (fields.size() > 12 && fields[12]!='')
                        newKeyMsg.Clm_Presentation_vod__c = fields[12];
                    if (fields.size() > 13)
                        newKeyMsg.Clm_Presentation_Name_vod__c = fields[13];
                    if (fields.size() > 14)
                        newKeyMsg.Clm_Presentation_Version_vod__c = fields[14];
                    if (fields.size() > 15)
                        newKeyMsg.Key_Message_Name_vod__c = fields[15];
                    keysToAdd.add(newKeyMsg);
                            
                }
            }
        }
    }
     VOD_CHILD_SUBMIT.setSubmitCheck(false);        
    if (detsToAdd.size () > 0) {
        try {
            insert  detsToAdd;
        } catch (System.DmlException e) {
            Integer numErrors = e.getNumDml();
            String error = '';
             System.debug('Error has occured: ' + numErrors);
            System.debug('Error has occured: ' + e);
            for (Integer i = 0; i < numErrors; i++) {

                Id thisId = e.getDmlId(i);
                System.debug ('Error info : ' + e.getDmlMessage(i));
                if (thisId != null)
                   error += thisId + ' - ';
                error += e.getDmlMessage(i) + '\n';
            }

            for (Call2_vod__c errorRec : Trigger.new) {
                errorRec.Id.addError(error, false);
            }
            return;
        }
    }
    if (keysToAdd.size () > 0) {
        try {
            insert  keysToAdd;
        } catch (System.DmlException e) {
            Integer numErrors = e.getNumDml();
            String error = '';
            System.debug('Error has occured: ' + numErrors);
            System.debug('Error has occured: ' + e);
            for (Integer i = 0; i < numErrors; i++) {

                Id thisId = e.getDmlId(i);
                System.debug ('Error info : ' + e.getDmlMessage(i));
                if (thisId != null)
                   error += thisId + ' - ';
                error += e.getDmlMessage(i) + '\n';
            }

            for (Call2_vod__c errorRec : Trigger.new) {
                errorRec.Id.addError(error, false);
            }
            return;
        }
    }
    VOD_CHILD_SUBMIT.setSubmitCheck(true);
    
    if ( hdrUpdList.size () > 0)        
        update  hdrUpdList;
        
    // release memory
    detsToAdd.clear();
    keysToAdd.clear();
    hdrUpdList.clear(); 
        
    // Now handle events
    VOD_CALL2_HEADER_CLASS.insertEvent (Trigger.new, accounts, eventRecTypeId);
    String str = VOD_ProcessTSF.writeCalls(Trigger.new, false);
    if (str.indexOf('call2_vod') != -1)
        VOD_ProcessTSF.processTSF(str);  
    if(VEEVA_CYCLE_PLAN_REALTIME_CALC.isEnableRealTimeCC()){ 
    	List<Call2_vod__c> calls = new List<Call2_vod__c>();  
	    for (Integer i = 0; i < triggerCalls.size(); i++) {
	    	Call2_vod__c call = Trigger.new[i];
	        if(call.Account_vod__c == null || call.Call_Date_vod__c == null || call.Territory_vod__c == null)
		        	continue;
		        calls.add(call);
	    }
	    VEEVA_CYCLE_PLAN_REALTIME_CALC.invokeCalculation(calls);
    }

}