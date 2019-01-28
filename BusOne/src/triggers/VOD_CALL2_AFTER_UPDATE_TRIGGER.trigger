trigger VOD_CALL2_AFTER_UPDATE_TRIGGER on Call2_vod__c (after update) {
    if (VEEVA_SAMPLE_CANCEL.isSampleCancel || CallSampleManagement.inSampleManagement ||  VOD_CALL2_ATTACHMENT_CLASS.inCallAttachment) {
        return;
    }
    //System.debug ('Number of Transactions = ' + Trigger.new.size ());
    VOD_ERROR_MSG_BUNDLE msgBundle = new VOD_ERROR_MSG_BUNDLE ();
    if (VOD_CALL2_HEADER_CLASS.getInsertAction () == true)
        return;

    // If this is a Concur Update, then skip all Call trigger logic.
    if (VEEVA_CONCUR_UTILS.isConcurUpdate(Trigger.old, Trigger.new)) {
        return;
    }

    VOD_CALL2_ATTACHMENT_CLASS.updateReceiptAttachmentsPending(Trigger.newMap);

    if (VOD_CALL2_HEADER_CLASS.getUpdateAction () == true)
        return;

    VOD_CALL2_HEADER_CLASS.setUpdateAction (true);
    String userId = UserInfo.getUserId();
    List <Id> accountsList = new List<Id>();
    List <Call2_Key_Message_vod__c> keysToAdd = new List <Call2_Key_Message_vod__c> ();
    List <Call2_Detail_vod__c> detsToAdd = new List<Call2_Detail_vod__c> ();
    List <Call2_Key_Message_vod__c> delKeyMsg = new List <Call2_Key_Message_vod__c> ();
    List <Call2_Detail_vod__c> delDetails = new List <Call2_Detail_vod__c> ();
    List <String> callIds = new List<String> ();
    Set <String> callIdsForDets = new Set<String> ();
    Set <String> callIdsForKeys = new Set<String> ();
    List <Sample_Transaction_vod__c> newTrans = new List <Sample_Transaction_vod__c> ();
    List <Sample_Order_Transaction_vod__c> newOrders = new List <Sample_Order_Transaction_vod__c> ();
    Map <Id, Call2_vod__c> beforeMap = VOD_CALL2_HEADER_CLASS.getMap ();
    Map<Id,Account> accounts = null;
    Set <String> callsWithTrans = new Set <String> ();
    Set <String> callsWithOrders = new Set <String> ();
    Map<Id,Product_vod__c> products = null;
    List <Call2_vod__c> submitList  = new List <Call2_vod__c> ();
    Boolean realtimeCCEnabled = VEEVA_CYCLE_PLAN_REALTIME_CALC.isEnableRealTimeCC();


    RecordType[] recTypes = VOD_CALL2_HEADER_CLASS.getRecordTypes();

    String eventRecTypeId = '';
    String sampleRecTypeId = '';
    String sampleOrderRectypeId = '';
    for (RecordType recType : recTypes) {
        if (recType.SobjectType == 'Event')
            eventRecTypeId = recType.Id;
        else if (recType.SobjectType == 'Sample_Transaction_vod__c')
            sampleRecTypeId = recType.Id;
        else if (recType.SobjectType == 'Sample_Order_Transaction_vod__c')
            sampleOrderRectypeId = recType.Id;
    }

    // fetch the prodcut types which  has no lot vod and needs creation of No_Lot_vod
    Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
    Set<String> noLotproductTypes = new Set<String> ();
    if (vsc != null && vsc.Sample_Management_Product_Types_vod__c != null) {
        List<String> productTypesTemp = vsc.Sample_Management_Product_Types_vod__c.Split(';;');
        noLotproductTypes.addAll(productTypesTemp);
    }

    Map <Id, Call2_vod__c> callMap =
            new Map <Id, Call2_vod__c>(
                    [Select Id,
                            License_vod__c,
                            Parent_Address_vod__c,
                            Address_vod__c,
                            OwnerId,
                            (Select Id,
                                    User_vod__c,
                                    Account_vod__c,
                                    Contact_vod__c,
                                    Call_Date_vod__c
                                    from Call2_vod__r),
                            (Select Id
                                    from Events
                                    where RecordTypeId=:eventRecTypeId),

                            (Select Id,
                                    Name,
                                    Lot_vod__c,
                                    Product_vod__c,
                                    Quantity_vod__c,
                                    Distributor_vod__c,
                                    Delivery_Status_vod__c,
                                    Manufacturer_vod__c, Tag_Alert_Number_vod__c, Cold_Chain_Status_vod__c,Custom_Text_vod__c
                                    From Call2_Sample_vod__r )
                            from Call2_vod__c
                            Where Id in :Trigger.new]);

    Set<String> productIds = new Set<String>();
    Set<String> lotNums = new Set<String>();
    Set<String> ownerIDs = new Set<String>();

    for (Call2_vod__c call : callMap.values()) {
        // store away call names for later use by sample transaction
        ownerIDs.add (call.OwnerId);
        for (Call2_Sample_vod__c sample : call.Call2_Sample_vod__r) {
            if (sample.Lot_vod__c != '') {
                lotNums.add(sample.Lot_vod__c);
                productIds.add(sample.Product_vod__c);
            }
        }
    }

    // now add the name No_Lot_vod which will not be there in call sample
    lotNums.add('No_Lot_vod');

    List <String> parentIds = new List <String> ();
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


    // debug for lot names
    system.debug('the sample lot names ' +  lotNums);
    accounts = new Map<Id,Account>([Select Id,Name,Credentials_vod__c,Salutation,(Select License_vod__c,State_vod__c From Address_vod__r order by Primary_vod__c) From Account Where Id in :accountsList]);
    products = new Map<Id,Product_vod__c>([Select Id,Name,Product_Type_vod__c,Sample_U_M_vod__c, Manufacturer_vod__c From Product_vod__c Where Id In :productIds]);
    List<Sample_Lot_vod__c> sampleLots = [Select Id,Name, Sample_vod__c, Product_vod__c, Product_vod__r.Product_Type_vod__c, OwnerId From Sample_Lot_vod__c Where Name In :lotNums And OwnerId IN :ownerIDs];

    // debugging reasons
    system.debug(' from trigger the sample lots fetched are ' + sampleLots);

    Set<Sample_Transaction_vod__c> callSampleTrans = new Set<Sample_Transaction_vod__c> ();
    for (Sample_Transaction_vod__c samptrans : [Select Id,Call_Name_vod__c, Sample_vod__c, Lot_vod__c, Tag_Alert_Number_vod__c, Cold_Chain_Status_vod__c,Custom_Text_vod__c
            From Sample_Transaction_vod__c
            where Call_Name_vod__c in :callNames
    and RecordTypeId = :sampleRecTypeId
    and Lot_vod__r.OwnerId in :ownerIDs]) {
        callsWithTrans.add (samptrans.Call_Name_vod__c);
        callSampleTrans.add(samptrans);
    }

    for (Sample_Order_Transaction_vod__c sampords
            : [Select Id,Call_Name_vod__c
            From Sample_Order_Transaction_vod__c
            where Call_Name_vod__c in :callNames
    and OwnerId in :ownerIDs]) {

        callsWithOrders.add (sampords.Call_Name_vod__c);
    }

    Map<Id,set<String>> oldDetailProds = new Map<Id,set<String>>();
    Map<Id,set<String>> newDetailProds = new Map<Id,set<String>>();
    Map <Id, Call2_vod__c> parents =
            new Map <Id, Call2_vod__c>
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

    for (Integer i = 0; i < Trigger.new.size(); i++ ) {
        Call2_vod__c call2 = Trigger.new[i];
        Call2_vod__c call2old = Trigger.old[i];
        Call2_vod__c beforeCall2 = beforeMap.get (call2.Id);
        boolean bPushToChild = false;
        oldDetailProds.put(call2.Id,new set<String>());

        newDetailProds.put(call2.Id,new set<String>());

        // handle sample trans
        if (call2.Account_vod__c != null) {
            newTrans.addAll (VOD_CALL2_HEADER_CLASS.handleDisbursement(call2,
                    callMap,
                    accounts,
                    parents,
                    products,
                    sampleLots,
                    callsWithTrans,
                    sampleRecTypeId,
                    noLotproductTypes,
                    callSampleTrans,
                    beforeCall2));

            newOrders.addAll (VOD_CALL2_HEADER_CLASS.handleOrders (call2,
                    callMap,
                    accounts,
                    parents,
                    products,
                    sampleLots,
                    callsWithOrders,
                    sampleOrderRectypeId,
                    noLotproductTypes,
                    beforeCall2));
        }


        // If this a a parent call
        if (call2.Account_vod__c != call2old.Account_vod__c ||
                        call2.User_vod__c != call2old.User_vod__c ||
                        call2.Contact_vod__c != call2old.Contact_vod__c||
                        call2.Call_Date_vod__c != call2old.Call_Date_vod__c ||
                ( beforeCall2.Add_Key_Message_vod__c != null &&
                                'DELETE'.equals (beforeCall2.Add_Key_Message_vod__c) == false)) {
            bPushToChild = true;
            if ('DELETE'.equals (beforeCall2.Add_Key_Message_vod__c)) {
                beforeCall2.Add_Key_Message_vod__c = null;
                callIdsForKeys.add (call2.Id);
            }
        }

        if (beforeCall2.Add_Detail_vod__c != null ) {
            callIdsForDets.add (call2.Id);
            if ('DELETE'.equals (beforeCall2.Add_Detail_vod__c) == false) {
                //System.debug ('Dets - ' + beforeCall2.Add_Detail_vod__c);
                String [] dets = beforeCall2.Add_Detail_vod__c.split(',');

                for (Integer it = 0; it < dets.size(); it++) {
                    String [] detParts = dets[it].Split(';;');
                    String [] prodKey = detParts[0].Split('_');
                    String productId = null;
                    String prodGroupId = null;
                    if(prodKey.size() > 1)
                    {
                        productId = prodKey[1];
                        prodGroupId = prodKey[0];
                    }
                    else
                        productId = prodKey[0];
                    Double priority  = it + 1;
                    Call2_Detail_vod__c call_det;
                    if(detParts.size()>1)
                        call_det =
                        new Call2_Detail_vod__c (Detail_Priority_vod__c = priority,
                                Product_vod__c = productId,
                                Detail_Group_vod__c = prodGroupId,
                                Type_vod__c = detParts[1],
                                Call2_vod__c = call2.Id,
                                Override_Lock_vod__c = beforeCall2.Override_Lock_vod__c);
                    else
                        call_det =
                        new Call2_Detail_vod__c (Detail_Priority_vod__c = priority,
                                Product_vod__c = productId,
                                Detail_Group_vod__c = prodGroupId,
                                Type_vod__c = 'Paper_Detail_vod',
                                Call2_vod__c = call2.Id,
                                Override_Lock_vod__c = beforeCall2.Override_Lock_vod__c);
                    detsToAdd.add (call_det);
                    if(realtimeCCEnabled && detParts[0] != null)
                        newDetailProds.get(call2.Id).add(detParts[0]);
                }
            }
        }

        if (beforeCall2.Add_Key_Message_vod__c != null  ) {
            callIdsForKeys.add (call2.Id);
            if ('DELETE'.equals (beforeCall2.Add_Key_Message_vod__c) == false) {
                String [] lines = null;
                lines = beforeCall2.Add_Key_Message_vod__c.split(';;;');

                if (lines != null) {
                    //System.debug ('# of lines = ' + lines.size());
                    boolean error = false;
                    for (Integer l = 0; l < lines.size(); l++ ) {
                        //System.debug ('Line # = ' + l + ' = ' + lines[l]);
                        Call2_Key_Message_vod__c newKeyMsg =
                                new Call2_Key_Message_vod__c (Call2_vod__c  = call2.Id,
                                        Account_vod__c = call2.Account_vod__c,
                                        Contact_vod__c = call2.Contact_vod__c,
                                        Call_Date_vod__c = call2.Call_Date_vod__c,
                                        User_vod__c = call2.User_vod__c,
                                        Override_Lock_vod__c = beforeCall2.Override_Lock_vod__c);

                        String [] fields = lines[l].split('@@');

                        if (fields[0] != null && fields[0] != '')
                            newKeyMsg.Key_Message_vod__c = fields[0];
                        if (fields.size() > 1) {
                            if (fields[1] != null && fields[1] != '')
                            {
                                String[] prodKey = fields[1].Split('_');
                                String productId = null;
                                String prodGroupId = null;
                                if(prodKey.size() > 1)
                                {
                                    productId = prodKey[1];
                                    prodGroupId = prodKey[0];
                                }
                                else
                                    productId = prodKey[0];
                                newKeyMsg.Product_vod__c     = productId;
                                newKeyMsg.Detail_Group_vod__c = prodGroupId;
                            }
                        }
                        if (fields.size() > 2)
                            newKeyMsg.Reaction_vod__c    = fields[2];
                        if (fields.size() > 3)
                            newKeyMsg.Category_vod__c = fields[3];
                        if (fields.size() > 4)
                            newKeyMsg.Vehicle_vod__c = fields[4];
                        if (fields.size() > 5 && fields[5]!='')
                            newKeyMsg.Start_Time_vod__c    = DateTime.valueOfGmt(fields[5]);
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
    }

    // release memory
    parents.clear();
    accounts.clear();
    products.clear();


    List <Call2_Detail_vod__c> call2Det = new List <Call2_Detail_vod__c> ();
    List <Call2_Key_Message_vod__c> call2Key = new List <Call2_Key_Message_vod__c> ();
    if (callIdsForDets.size() > 0 || callIdsForKeys.size() > 0) {


        for (Call2_vod__c call2sForDelete :
        [Select Id, (Select Id,Call2_vod__c,Product_vod__c, Detail_Group_vod__c  From Call2_Detail_vod__r), (Select Id,Call2_vod__c From Call2_Key_Message_vod__r) from  Call2_vod__c where Id in :callIdsForDets or Id in :callIdsForKeys] ) {

            for (Call2_Detail_vod__c detToCheck : call2sForDelete.Call2_Detail_vod__r) {
                if (callIdsForDets.contains(detToCheck.Call2_vod__c)){
                    call2Det.add(detToCheck);
                    if(realtimeCCEnabled && detToCheck.Product_vod__c != null){
                        String prodKey = '';
                        if(detToCheck.Detail_Group_vod__c != null)
                            prodKey = detToCheck.Detail_Group_vod__c + '_' + detToCheck.Product_vod__c;
                        else
                            prodKey = detToCheck.Product_vod__c;

                        oldDetailProds.get(detToCheck.Call2_vod__c).add(prodKey);
                    }
                }

            }
            for (Call2_Key_Message_vod__c keyTotCheck : call2sForDelete.Call2_Key_Message_vod__r) {
                if (callIdsForKeys.contains(keyTotCheck.Call2_vod__c))
                    call2Key.add(keyTotCheck);
            }

        }

    }
    VOD_CHILD_SUBMIT.setSubmitCheck(false);

    if(call2Det.size() > 0) {
        try {
            //VOD_CALL2_DETAIL_TRIG.invoke = false;
            delete call2Det;
        }catch (System.DmlException e) {
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
        call2Det.clear();
    }
    if(call2Key.size() > 0) {
        try {
            delete call2Key;
        }catch (System.DmlException e) {
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
        call2Key.clear();
    }
    if (keysToAdd.size() > 0) {
        try {
            insert keysToAdd;
        }catch (System.DmlException e) {
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
        keysToAdd.clear();
    }

    if (detsToAdd.size() > 0) {
        try {
            //VOD_CALL2_DETAIL_TRIG.invoke = false;
            insert detsToAdd;
        }catch (System.DmlException e) {
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
        detsToAdd.clear();
    }

    if (newOrders.size () > 0) {
        try {
            insert newOrders;
        }catch (System.DmlException e) {
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
        newOrders.clear();
    }

    if (newTrans.size () > 0) {
        try {
            insert newTrans;
        }catch (System.DmlException e) {
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
        newTrans.clear();
    }
    VOD_CHILD_SUBMIT.setSubmitCheck(true);
    VOD_CALL2_HEADER_CLASS.updateEvent (Trigger.new, callMap, eventRecTypeId);
    callMap.clear();

    for (integer l = 0; l < Trigger.new.size(); l++) {
        Call2_vod__c bfCall= beforeMap.get (Trigger.new[l].Id);
        if (bfCall.Status_vod__c  == 'Submitted_vod') {
            Call2_vod__c nCall = new Call2_vod__c (Id = Trigger.new[l].Id,
                    Status_vod__c = 'Submitted_vod');
            submitList.add (nCall);
        }
    }

    if (submitList.size () > 0){
        try {
            update submitList;
        } catch (System.DmlException e) {
            for (Integer m = 0; m < submitList.size(); m++) {
                String ID = submitList[m].Id;
                if (ID != null) {
                    Call2_vod__c call = Trigger.newMap.get(ID);
                    if (call != null) {
                        if (e.getNumDml() > 0) {
                            System.Debug('Pulling Message from Exception');
                            call.addError( e.getDmlMessage(0), false);
                        }
                        else {
                            System.Debug('Defaulting Message ');
                            call.addError(msgBundle.getErrorMsg(System.Label.CANNOT_SUBMIT_CALL), false);
                        }
                    }
                }
            }
        }
    }
    submitList.clear();

    // find out call updates that affect TSF 
    List<Call2_vod__c> calls = new List<Call2_vod__c>();
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        Call2_vod__c call = Trigger.new[i];
        if (call.Account_vod__c == null || call.Territory_vod__c == null)
            continue;
        Call2_vod__c oldCall = Trigger.old[i];

        if ( (call.Call_Date_vod__c <= System.today()  && call.Status_vod__c != 'Planned_vod'
                && VOD_ProcessTSF.tsfProcessed.contains (call.Id) == false ) ||
                (oldCall.Status_vod__c != 'Planned_vod' && call.Status_vod__c == 'Planned_vod')
        ) {
            calls.add(call);
            VOD_ProcessTSF.tsfProcessed.contains (call.Id);
        }

    }



    String str = VOD_ProcessTSF.writeCalls(calls, true);
    if (str.indexOf('call2_vod') != -1)
        VOD_ProcessTSF.processTSF(str);

    //realtime calculation of cycle plan
    List<Call2_vod__c> callsRC = new List<Call2_vod__c>();
    if(realtimeCCEnabled){
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            Call2_vod__c call = Trigger.new[i];
            Call2_vod__c bfCall= beforeMap.get (Trigger.new[i].Id);
            Call2_vod__c oldCall = Trigger.old[i];

            set<String> oldProducts = oldDetailProds.get(oldCall.Id);
            set<String> newProducts = newDetailProds.get(call.Id);
            if(oldCall.Account_vod__c == null || oldCall.Territory_vod__c == null || call.Account_vod__c == null || call.Territory_vod__c == null)
                continue;

            set<String> missingProducts = new set<String>();
            set<String> addedProducts = new set<String>();

            for(String oldproduct : oldProducts){
                if(!newProducts.contains(oldproduct)){
                    missingProducts.add(oldproduct);
                }
            }

            for(String newProduct : newProducts){
                if(!oldProducts.contains(newProduct)){
                    addedProducts.add(newProduct);
                }
            }
            System.debug('missing products: ' + missingProducts.size());
            System.debug('added products: ' +  addedProducts.size());

            System.debug ('VEEVADEBUG: Processing : "' + call.Account_vod__c + '" for territrory = "'
                    + call.Territory_vod__c +'" Date ="'+ call.Call_Date_vod__c  + '" Status="' + bfCall.Status_vod__c + '"');

            System.debug ('VEEVADEBUG: Processing : "' +oldCall.Account_vod__c + '" for territrory = "'
                    + oldCall.Territory_vod__c +'" Date ="'+ oldCall.Call_Date_vod__c  + '" Status="' + oldCall.Status_vod__c + '"');

            //if no call detail change and no call account, date, territory and status change
            if((addedProducts.size() == 0) && (missingProducts.size() == 0) && (oldCall.Account_vod__c == call.Account_vod__c) && (oldCall.Territory_vod__c == call.Territory_vod__c) &&
                    (oldCall.Status_vod__c == bfCall.Status_vod__c) && (oldCall.Call_date_vod__c == call.Call_date_vod__c)) {
                if (!(oldCall.createddate == oldCall.lastmodifieddate && oldCall.last_device_vod__c == 'Online_vod')){
                    continue;
                }
            }

            // realtime cycle plan calculation

            //VEEVA_CYCLE_PLAN_REALTIME_CALC.calculateUpdate(oldCall.Account_vod__c,oldCall.Call_Date_vod__c,oldCall.territory_vod__c,call.Account_vod__c, call.Call_Date_vod__c, call.territory_vod__c);
            callsRC.add(oldCall);
            callsRC.add(call);
        }
        VEEVA_CYCLE_PLAN_REALTIME_CALC.invokeCalculation(callsRC);
    }
}