trigger VOD_CALL2_BEFORE_INSUPD_TRIGGER on Call2_vod__c ( before insert, before update) {
    if (VEEVA_SAMPLE_CANCEL.isSampleCancel || CallSampleManagement.inSampleManagement || VOD_CALL2_ATTACHMENT_CLASS.inCallAttachment) {
        return;
    }

    // If this is a Concur Update, then skip all Call trigger logic.
    if (Trigger.isUpdate && VEEVA_CONCUR_UTILS.isConcurUpdate(Trigger.old, Trigger.new)) {
        // This is a Concur update. Set the Override Lock to false
        for(Call2_vod__c call : Trigger.new) {
            if(call.Override_Lock_vod__c) {
                call.Override_Lock_vod__c = false;
            }
        }
        return;
    }

   // Mark off Calls as either needing a Concur Sync or not
   for (Call2_vod__c call : Trigger.new) {
       if(VEEVA_CONCUR_UTILS.concurSyncPending(call)) {
            call.Expense_Post_Status_vod__c = 'Pending';
       }
   }

    boolean isSaveTransaction = VeevaSettings.isEnableSamplesOnSave();

    List <Call2_vod__c> updCallList = new List <Call2_vod__c> ();
    VOD_ERROR_MSG_BUNDLE msgBundle = new VOD_ERROR_MSG_BUNDLE ();  
    if (Trigger.isUpdate) {
        Map<Id,Call2_vod__c> copyMap = new Map<Id,Call2_vod__c>();
        for (Integer i=0; i<Trigger.new.size(); i++) {
            Call2_vod__c copyCall = new Call2_vod__c(Id = Trigger.new[i].Id,
                    Add_Key_Message_vod__c = Trigger.new[i].Add_Key_Message_vod__c,
                    Add_Detail_vod__c = Trigger.new[i].Add_Detail_vod__c,
                    Status_vod__c = Trigger.new[i].Status_vod__c,
                    No_Disbursement_vod__c = Trigger.new[i].No_Disbursement_vod__c,
                    Override_Lock_vod__c = Trigger.new[i].Override_Lock_vod__c);
            copyMap.put(Trigger.new[i].Id, copyCall);
        }
        VOD_CALL2_HEADER_CLASS.setMap(copyMap);
    }
            
    Map <Id, Call2_vod__c> calls = new Map <Id, Call2_vod__c> ([Select Id,Override_Lock_vod__c, 
                                                 (Select Name, Id from Call2_vod__r)
                                                  From Call2_vod__c 
                                                  Where Id in :Trigger.new]);
            
    for (Integer i = 0 ;  i < Trigger.new.size(); i++)  {
        
         if (Trigger.new[i].Territory_vod__c == null || Trigger.new[i].Territory_vod__c == '') {
                String terr = VOD_CALL2_HEADER_CLASS.getMyFirstTerr ();
                if (terr != null) {
                    Trigger.new[i].Territory_vod__c = terr;
                }
            }
       
        if (Trigger.isInsert || Trigger.isUpdate) {
            if (Trigger.new[i].Attendee_Type_vod__c != null && Trigger.new[i].Attendee_Type_vod__c.length() > 0 &&  
                Trigger.new[i].Entity_Reference_Id_vod__c != null && Trigger.new[i].Entity_Reference_Id_vod__c.length() > 0) {
                if ('Person_Account_vod' == Trigger.new[i].Attendee_Type_vod__c  || 'Group_Account_vod' == Trigger.new[i].Attendee_Type_vod__c ) {
                    Trigger.new[i].Account_vod__c = Trigger.new[i].Entity_Reference_Id_vod__c;
                    Trigger.new[i].Entity_Reference_Id_vod__c = null;                   
                } else if ('Contact_vod' == Trigger.new[i].Attendee_Type_vod__c) {
                    Trigger.new[i].Contact_vod__c = Trigger.new[i].Entity_Reference_Id_vod__c;
                    Trigger.new[i].Entity_Reference_Id_vod__c = null;  
                } else if ('User_vod' == Trigger.new[i].Attendee_Type_vod__c) {
                    Trigger.new[i].User_vod__c = Trigger.new[i].Entity_Reference_Id_vod__c;
                    Trigger.new[i].Entity_Reference_Id_vod__c = null;  
                }
                else if ('Event_vod' == Trigger.new[i].Attendee_Type_vod__c) {
                    Trigger.new[i].Medical_Event_vod__c = Trigger.new[i].Entity_Reference_Id_vod__c;
                    Trigger.new[i].Entity_Reference_Id_vod__c = null;  
                }       
            }
            Trigger.new[i].Location_Name_vod__c = Trigger.new[i].Location_Id_vod__c;
            Trigger.new[i].Child_Account_vod__c = Trigger.new[i].Child_Account_Id_vod__c;
            //Stamp new offline ship to location fields
            VOD_CALL2_HEADER_CLASS.stampShipToLocation(Trigger.new[i]);
        }
        
        if (Trigger.new[i].Call_Datetime_vod__c != null) {
            // We have the datetime so we must populate date
            DateTime dt =Trigger.new[i].Call_Datetime_vod__c;   
            Trigger.new[i].Call_Date_vod__c = Date.newInstance(dt.year(), dt.month(), dt.day());    
        }
        else if (Trigger.new[i].Call_Datetime_vod__c == null && Trigger.new[i].Call_Date_vod__c == null) {
            Trigger.new[i].Call_Date_vod__c = System.today();
        }
        
        Date today = System.today();
        if (Trigger.new[i].Status_vod__c == 'Submitted_vod' && Trigger.new[i].Call_Date_vod__c > today)  {
            Trigger.new[i].Status_vod__c.addError(msgBundle.getErrorMsg('NO_FUTURE_SUBMIT'), false);
        } 
        
        if (Trigger.isInsert) {
            //Clean out temp fields
            if (Trigger.new[i].Add_Detail_vod__c == 'DELETE') {
                Trigger.new[i].Add_Detail_vod__c = null;
            }
            if (Trigger.new[i].Add_Key_Message_vod__c == 'DELETE') {
                Trigger.new[i].Add_Key_Message_vod__c = null;
            }
        }
        if (Trigger.new[i].Unlock_vod__c == true) {
            VOD_CALL2_HEADER_CLASS.setUpdateAction (true);
            Call2_vod__c callParent = calls.get (Trigger.new[i].Id);
            Trigger.new[i].Status_vod__c = 'Saved_vod';
            Trigger.new[i].Unlock_vod__c = false;
            Trigger.new[i].Submitted_By_Mobile_vod__c = false;
    
            for (Call2_vod__c childCall : callParent.Call2_vod__r) {
                Call2_vod__c updCall = new Call2_vod__c (Id = childCall.Id,
                                                    Submitted_By_Mobile_vod__c = false,
                                                     Unlock_vod__c = true);
                updCallList.add(updCall);
            }
            continue;
        } 
        if (Trigger.isUpdate) {
         Call2_vod__c callHead = Trigger.old[i];
            
            // If a call is Save on Sample and has a sample, dont let the OwnerId change.
            if (isSaveTransaction == true && callHead.Status_vod__c == 'Saved_vod' && (
                    callHead.Signature_vod__c != null || 
                    callHead.Sample_Card_vod__c != null || 
                    callHead.Sample_Send_Card_vod__c != null
                 ))  {
            
                    if (Trigger.new[i].OwnerId != Trigger.old[i].OwnerId)
                        Trigger.new[i].OwnerId = Trigger.old[i].OwnerId;
            }
                  
            Call2_vod__c callParent = calls.get(Trigger.new[i].Id);
            if ((Trigger.old[i].Status_vod__c == 'Submitted_vod')  &&
                    (Trigger.new[i].Override_Lock_vod__c == false) &&
                    (callParent.Override_Lock_vod__c == false)) {
                Trigger.new[i].Status_vod__c.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_UPD_SUB','TriggerError'), false);
                continue;
            }
            Trigger.new[i].Add_Detail_vod__c = null;
            Trigger.new[i].Add_Key_Message_vod__c = null;
            Trigger.new[i].No_Disbursement_vod__c = false;
            Trigger.new[i].Override_Lock_vod__c = false;
            if (Trigger.new[i].Status_vod__c == 'Submitted_vod' &&  VOD_CALL2_HEADER_CLASS.getUpdateAction () == false &&
                    VOD_CALL2_HEADER_CLASS.getInsertAction () == false) {
                Trigger.new[i].Status_vod__c = 'Saved_vod';
            }
        }
        
          
    }
    if (updCallList.size () > 0) {
        System.debug ('# of headers - ' + updCallList.size ());
        update (updCallList);
    }
}