public class VOD_CALL2_HEADER_CLASS {
    private static Map <Id, Call2_vod__c> beforeCalls = null;
    private static boolean bInsertAction = false;
    private static boolean bUpdateAction = false;
    private static RecordType[] recTypes = [Select Id,toLabel(Name), SobjectType from RecordType where (SobjectType='Event' and Name='Call_vod') or (SobjectType='Sample_Transaction_vod__c' and Name='Disbursement_vod') or
    (SobjectType='Sample_Order_Transaction_vod__c' and Name='BRC') or (SobjectType='Call2_vod__c')];
    private static String myFirstTerr = null;
    private static boolean terrSet = false;

    public static String getMyFirstTerr() {
        if (terrSet == false) {
            terrSet = true;
            List <String> UserTerrIds = new List<String> ();
            List<UserTerritory> Userterr =
            [SELECT TerritoryId from UserTerritory where UserId = :UserInfo.getUserId() AND IsActive = true Limit 1];

            for (UserTerritory ut : Userterr) {
                UserTerrIds.add(ut.TerritoryId);
            }

            List<Territory> terr = null;

            if (UserTerrIds.size() > 0)
                terr = [Select Name From Territory where Id in :UserTerrIds];
            if (terr != null && terr.size() == 1) {
                Territory myTerr = terr.get(0);
                myFirstTerr = myTerr.Name;
            }
        }
        return myFirstTerr;
    }

    public static boolean getUpdateAction() {
        return bUpdateAction;
    }

    public static RecordType [] getRecordTypes() {
        return recTypes;
    }

    public static void setUpdateAction(boolean action) {
        bUpdateAction = action;
    }

    public static boolean getInsertAction() {
        return bInsertAction;
    }

    public static void setInsertAction(boolean action) {
        bInsertAction = action;
    }

    public static void setMap(Map <Id, Call2_vod__c> pMap) {
        beforeCalls = pMap;

    }

    public static Map<Id, Call2_vod__c> getMap() {
        return beforeCalls;
    }

    public static void insertEvent(Call2_vod__c [] calls,
            Map <Id, Account> accounts,
            String eventRecTypeId) {
        String callStubText = System.label.Call_Event_Display_Label;
        String useRecordTypeLabel = System.label.Call_Event_RecordType_Display;
        Boolean bUseRecordType = false;


        if (callStubText == null || callStubText.length() == 0)
            callStubText = 'Call';
        if ('true'.equalsIgnoreCase(useRecordTypeLabel))
            bUseRecordType = true;

        Set<Id> medEventIds = new Set<Id>();
        for (Call2_vod__c aCall : calls) {
            if (aCall.Medical_Event_vod__c != null)
                medEventIds.add(aCall.Medical_Event_vod__c);
        }
        Map<Id, Medical_Event_vod__c> medEvents = null;
        if (medEventIds.size() > 0)
            medEvents =
            new Map<Id, Medical_Event_vod__c>([Select Id,Name From Medical_Event_vod__c Where Id In :medEventIds]);

        List<Event> eveList = new List<Event>();
        Account acct = null;
        for (Call2_vod__c callHead : calls) {

            if (callHead.Parent_Call_vod__c != null || callHead.Call_Datetime_vod__c == null)
                continue;

            if (bUseRecordType == true) {

                for (RecordType rect : recTypes) {
                    if (rect.Id == callHead.RecordTypeId) {
                        callStubText = rect.Name;
                        break;
                    }
                }
            }


            acct = accounts.get(callHead.Account_vod__c);

            if (acct == null)
                continue;

            Event newEvent = new Event();
            //  newEvent.AccountId = callHead.Account_vod__c;
            newEvent.OwnerId = callHead.CreatedById;
            newEvent.WhatId = callHead.Id;
            newEvent.Subject = callStubText + '-';
            if (acct != null)
                newEvent.Subject += acct.Name;
            else if ((callHead.Medical_Event_vod__c != null) && (medEvents != null)) {
                Medical_Event_vod__c me = medEvents.get(callHead.Medical_Event_vod__c);
                if (me != null)
                    newEvent.Subject += me.Name;
            }
            newEvent.DurationInMinutes = 15;
            if (callHead.Duration_vod__c > 0) {
                newEvent.DurationInMinutes = callHead.Duration_vod__c.intValue();
            }
            system.debug('newEvent.DurationInMinutes=[' + newEvent.DurationInMinutes + ']');
            newEvent.Location = callHead.Address_vod__c;
            newEvent.RecordTypeId = eventRecTypeId;
            newEvent.ActivityDateTime = callHead.Call_Datetime_vod__c;
            eveList.add(newEvent);
        }
        try {
            if (eveList.size() > 0)
                insert eveList;
        } catch (System.DmlException e) {
            for (Integer er = 0; er < calls.size(); er++)
                calls[er].Id.addError('Unable_To_Add_Event', false);
        }
    }

    public static void updateEvent(Call2_vod__c [] calls,
            Map <Id, Call2_vod__c> callMap,
            String eventRecTypeId) {
        String eveID = null;

        if (VOD_CALL_TO_CALENDAR.getCalendarTrig() == true)
            return;

        VOD_CALL_TO_CALENDAR.setCallTrig(true);

        List<Event> updEveList = new List<Event>();

        for (Call2_vod__c callHead : calls) {

            if (callHead.Call_Datetime_vod__c == null || callHead.Parent_Call_vod__c != null)
                continue;
            eveID = null;
            for (Event eve : callMap.get(callHead.Id).Events) {
                eveID = eve.Id;
                System.debug('eve.ID = ' + eve.Id);
            }

            if (eveID != null) {
                integer duration = 15;
                if (callHead.Duration_vod__c > 0) {
                    duration = callHead.Duration_vod__c.intValue();
                }
                system.debug('updateEvent : Call Duration = [' + callHead.Duration_vod__c + ']; Event duration = [' +
                        duration + ']');
                Event updEve = new Event(Id = eveID, ActivityDateTime = callHead.Call_Datetime_vod__c,
                        DurationInMinutes = duration);
                updEveList.add(updEve);
            }
        }

        if (updEveList.size() > 0)
            update updEveList;
    }

    public static List <Sample_Transaction_vod__c> handleDisbursement(
            Call2_vod__c callHead,
            Map <Id, Call2_vod__c> calls,
            Map <Id, Account> accounts,
            Map <Id, Call2_vod__c> parents,
            Map <Id, Product_vod__c> products,
            List<Sample_Lot_vod__c> sampleLots,
            Set <String> callsWithTrans,
            String sampleRecTypeId,
            Set<String> noLotProductTypes,
            Set<Sample_Transaction_vod__c> callSampleTrans,
            Call2_vod__c beforeCall) {

        List <Sample_Transaction_vod__c> trans = new List <Sample_Transaction_vod__c> ();
        Call2_vod__c parentCall = null;
        Account recByAcct = accounts.get(callHead.Account_vod__c);
        if (recByAcct == null)
            return trans;

        // system debug to check if its inside the handle disbursement
        system.debug('inside the handle disbursement method');

        boolean createSampleTransactions = false;
        boolean enableSampleOnSaveAndSave = false;

        if (!beforeCall.No_Disbursement_vod__c) {
            if (beforeCall.Status_vod__c == 'Submitted_vod' ||
                    (callHead.Status_vod__c == 'Saved_vod' && (
                                    callHead.Signature_vod__c != null || callHead.Sample_Card_vod__c != null ||
                                    callHead.Sample_Send_Card_vod__c != null) && VeevaSettings.isEnableSamplesOnSave()))
            {
                createSampleTransactions = true;
            }
        }
        if (!createSampleTransactions) {
            boolean isEnableSamplesOnSaveSign = VeevaSettings.isEnableSamplesOnSaveSign();
            if (isEnableSamplesOnSaveSign &&
                    (callHead.Signature_vod__c != null) &&
                    ((callHead.Status_vod__c == 'Saved_vod') || (callHead.Status_vod__c == 'Submitted_vod'))) {
                //#11953
                createSampleTransactions = true;
            }
        }

        // if enable sample on save and status is save then set the variable to skip promo and others
        if (beforeCall.Status_vod__c == 'Saved_vod') {
            system.debug('the test inside the if loop and the value of variable is  ' + enableSampleOnSaveAndSave);
            enableSampleOnSaveAndSave = true;
        }

        if (createSampleTransactions) {
            if (callHead.Parent_Call_vod__c != null) {
                system.debug('inside the if loop where createSampleTransactions is true ');
                parentCall = parents.get(callHead.Parent_Call_vod__c);
            }

            Call2_vod__c call = calls.get(callHead.Id);

            String state = '';
            String Location = '';
            String licCode = '';


            if (parentCall != null) {
                // Get the address from the parent
                Location = parentCall.Address_vod__c; // Grab the formatted Address from parent
                // Need to get the state so we can look up the lic. code for the Call Attendee.
                licCode = parentCall.License_vod__c;
            } else {
                // This is a Group header or an indvidual call.
                Location = callHead.Address_vod__c;
                licCode = callHead.License_vod__c;
            }

            system.debug(' the value of call sample received are ' + call.Call2_Sample_vod__r);
            // for debugging
            for (Call2_Sample_vod__c sample : call.Call2_Sample_vod__r) {
                system.debug(' the value of call sample received are inside debug test' + sample) ;
            }
            for (Call2_Sample_vod__c sample : call.Call2_Sample_vod__r) {
                System.debug('Sample Id: ' + sample.Product_vod__c);
                Product_vod__c prodItem = products.get(sample.Product_vod__c);
                // skip it for promo and others when enable_sample_on_save and save
                if (enableSampleOnSaveAndSave) {
                    // here if the product types are not sample, alternative sample and high value promo
                    if ((prodItem.Product_Type_vod__c != 'Sample') &&
                            (prodItem.Product_Type_vod__c != 'Alternative Sample') &&
                            (prodItem.Product_Type_vod__c != 'High Value Promotional')) {
                        System.debug(
                                'inside the if loop and the products are not sample, aletrnative sample, high value promo');
                        continue;
                    }
                }
                // skip it for product types of BRC
                if (prodItem != null && prodItem.Product_Type_vod__c != null &&
                        !prodItem.Product_Type_vod__c.equals('BRC')) {

                    // do not create sample transaction of type disbursement for non sample if the type is not in the settings
                    if (prodItem.Product_Type_vod__c != 'Sample' &&
                            !noLotProductTypes.contains(prodItem.Product_Type_vod__c)) {
                        continue;
                    }

                    system.debug('inside the prod type check the value is  ' + prodItem.Product_Type_vod__c);
                    Sample_Transaction_vod__c disb = new Sample_Transaction_vod__c();
                    disb.Call_Name_vod__c = callHead.Name;
                    disb.Disclaimer_vod__c = callHead.Disclaimer_vod__c;
                    disb.Signature_vod__c = callHead.Signature_vod__c;
                    disb.Sample_Card_vod__c = callHead.Sample_Card_vod__c;
                    disb.Sample_Card_Reason_vod__c = callHead.Sample_Card_Reason_vod__c;
                    disb.Call_Date_vod__c = callHead.Call_Date_vod__c;
                    disb.Call_Datetime_vod__c = callHead.Call_Datetime_vod__c;
                    disb.Account_vod__c = callHead.Account_vod__c;
                    disb.Request_Receipt_vod__c = callHead.Request_Receipt_vod__c;
                    disb.License_vod__c = callHead.License_vod__c;
                    // here add the license expiration date and license status from call to sample transaction object
                    disb.License_Expiration_Date_vod__c = callHead.License_Expiration_Date_vod__c;
                    disb.License_Status_vod__c = callHead.License_Status_vod__c;
                    // add the state distributor license information
                    disb.State_Distributor_vod__c = callHead.State_Distributor_vod__c;
                    disb.State_Distributor_Expiration_Date_vod__c = callHead.State_Distributor_Expiration_Date_vod__c;
                    // end of changes for license stauts and license expiration date
                    disb.Group_Transaction_Id_vod__c = callHead.Name;
                    disb.Signature_Page_Display_Name_vod__c = callHead.Signature_Page_Display_Name_vod__c;
                    disb.Manufacturer_vod__c = sample.Manufacturer_vod__c;
                    System.debug('Sample Values ' + callHead.Sample_Card_vod__c + ' AND ' +
                            callHead.Sample_Send_Card_vod__c);
                    if (callHead.Sample_Card_vod__c != null) {
                        System.debug('Setting Salutation and Credentials_vod__c on Sample Transaction record.');
                        disb.Credentials_vod__c = recByAcct.Credentials_vod__c;
                        disb.Salutation_vod__c = recByAcct.Salutation;
                    } else {
                        disb.Credentials_vod__c = callHead.Credentials_vod__c;
                        disb.Salutation_vod__c = callHead.Salutation_vod__c;
                    }

                    if (callHead.DEA_Address_Line_1_vod__c != null && callHead.DEA_Address_Line_1_vod__c.length() > 0) {
                        disb.ASSMCA_vod__c = callHead.ASSMCA_vod__c;
                        disb.DEA_Expiration_Date_vod__c = callHead.DEA_Expiration_Date_vod__c;
                        disb.DEA_vod__c = callHead.DEA_vod__c;
                        disb.Address_Line_1_vod__c = callHead.DEA_Address_Line_1_vod__c;
                        disb.Address_Line_2_vod__c = callHead.DEA_Address_Line_2_vod__c;
                        disb.City_vod__c = callHead.DEA_City_vod__c;
                        disb.State_vod__c = callHead.DEA_State_vod__c;
                        disb.Zip_vod__c = callHead.DEA_Zip_vod__c;
                        disb.Zip_4_vod__c = callHead.DEA_Zip_4_vod__c;

                    } else {

                        disb.Address_Line_1_vod__c = callHead.Address_Line_1_vod__c;
                        disb.Address_Line_2_vod__c = callHead.Address_Line_2_vod__c;
                        disb.City_vod__c = callHead.City_vod__c;
                        disb.State_vod__c = callHead.State_vod__c;
                        disb.Zip_vod__c = callHead.Zip_vod__c;
                        disb.Zip_4_vod__c = callHead.Zip_4_vod__c;
                    }

                    if (callHead.Signature_Date_vod__c != null)
                        disb.Signature_Date_vod__c = callHead.Signature_Date_vod__c;

                    disb.Sample_vod__c = products.get(sample.Product_vod__c).Name;
                    disb.Distributor_vod__c = sample.Distributor_vod__c;
                    disb.Lot_Name_vod__c = sample.Lot_vod__c;
                    disb.Tag_Alert_Number_vod__c = sample.Tag_Alert_Number_vod__c;
                    disb.Cold_Chain_Status_vod__c = sample.Cold_Chain_Status_vod__c;
                    disb.Custom_Text_vod__c = sample.Custom_Text_vod__c;

                    // now based on the product type see if No_Lot_vod need to be checked or it has to be lot vod
                    Boolean bUseSamp = false;
                    System.debug('Looking for lot =' + sample.Lot_vod__c + ' Owner=' + callHead.OwnerId +
                            ' Sample_vod__c=' + disb.Sample_vod__c);
                    String label = System.label.USE_MULTI_SAMPLE_vod;
                    if (label != null && label != 'false') {
                        bUseSamp = true;
                    }
                    System.debug('bUSeSamp=' + bUseSamp);

                    for (Sample_Lot_vod__c slot : sampleLots) {
                        if (prodItem.Product_Type_vod__c.equals('Sample')) {
                            System.debug('this lot =' + slot.Name + ' Owner=' + slot.OwnerId + ' Sample_vod__c =' +
                                    slot.Sample_vod__c);
                            if (slot.Name == sample.Lot_vod__c && callHead.OwnerId == slot.OwnerId &&
                                    (!bUseSamp || slot.Sample_vod__c == disb.Sample_vod__c)) {
                                disb.Lot_vod__c = slot.Id;
                                System.debug('Found  lot =' + slot.Name + ' Owner=' + slot.OwnerId);
                                break;
                            }

                        } else {
                            // rest of the product types check the No_Lot_only
                            // check only the no lot vod condition and create sample transaction for only No_Lot_vod lots
                            system.debug('inside the for loop for lots in handle disbursement ' +
                                    slot.Product_vod__r.Product_Type_vod__c);
                            system.debug('inside the for loop for lots in handle disbursement ' +
                                    slot.Product_vod__r.Product_Type_vod__c);
                            // here if the product tyope not in the veeva setting then do not create disbursement record
                            if (slot.Name.equals('No_Lot_vod') && callHead.OwnerId == slot.OwnerId &&
                                    (!bUseSamp || slot.Sample_vod__c == disb.Sample_vod__c) &&
                                    (slot.Product_vod__r.Product_Type_vod__c == prodItem.Product_Type_vod__c)) {
                                disb.Lot_vod__c = slot.Id;
                                System.debug('Found  lot =' + slot.Name + ' Owner=' + slot.OwnerId);
                                break;
                            }

                        }
                    }

                    // here once the lot id is also fetched check if sample transaction already exists for sample , lot combination
                    boolean sampleTransactionExists = false;
                    if (callsWithTrans.contains(callHead.Name) == true) {
                        // check the sample and lot
                        for (Sample_Transaction_vod__c sampTrans : callSampleTrans) {
                            if (sampTrans.Call_Name_vod__c == callHead.Name &&
                                            sampTrans.Sample_vod__c == disb.Sample_vod__c &&
                                            sampTrans.Lot_vod__c == disb.Lot_vod__c) {
                                sampleTransactionExists = true;
                            }
                        }

                    }

                    if (sampleTransactionExists) {
                        // do not create again
                        continue;
                    }

                    if (callHead.Submitted_By_Mobile_vod__c == true &&
                                    callHead.Mobile_Last_Modified_Datetime_vod__c != null) {
                        Integer day = callHead.Mobile_Last_Modified_Datetime_vod__c.day();
                        Integer month = callHead.Mobile_Last_Modified_Datetime_vod__c.month();
                        Integer year = callHead.Mobile_Last_Modified_Datetime_vod__c.year();
                        disb.Submitted_Date_vod__c = Date.newInstance(year, month, day);
                    } else
                        disb.Submitted_Date_vod__c = System.today();

                    disb.Quantity_vod__c = sample.Quantity_vod__c;
                    disb.Type_vod__c = 'Disbursement_vod';
                    disb.RecordTypeId = sampleRecTypeId;
                    disb.Status_vod__c = 'Submitted_vod';
                    disb.Disbursed_To_vod__c = recByAcct.Name;
                    if (!((recByAcct.Salutation == null) || (recByAcct.Salutation == '')))
                        disb.Disbursed_To_vod__c += ',' + recByAcct.Salutation;

                    if (recByAcct.Credentials_vod__c != null && recByAcct.Credentials_vod__c.length() > 0)
                        disb.Disbursed_To_vod__c += ',' + recByAcct.Credentials_vod__c;
                    if (Location != null && Location != '')
                        disb.Disbursed_To_vod__c += ',' + Location;
                    if (licCode != null && licCode != '')
                        disb.Disbursed_To_vod__c += ',' + licCode;

                    disb.CDS_vod__c = callHead.CDS_vod__c;
                    disb.CDS_Expiration_Date_vod__c = callHead.CDS_Expiration_Date_vod__c;
                    trans.add(disb);
                }
            }
        }
        return trans;
    }

    public static List <Sample_Order_Transaction_vod__c> handleOrders(
            Call2_vod__c callHead,
            Map <Id, Call2_vod__c> calls,
            Map <Id, Account> accounts,
            Map <Id, Call2_vod__c> parents,
            Map <Id, Product_vod__c> products,
            List<Sample_Lot_vod__c> sampleLots,
            Set <String> callsWithOrders,
            String sampleOrderRecTypeId,
            Set<String> noLotProductTypes,
            Call2_vod__c beforeCall) {

        List <Sample_Order_Transaction_vod__c> trans = new List <Sample_Order_Transaction_vod__c> ();
        Call2_vod__c parentCall = null;
        Account recByAcct = accounts.get(callHead.Account_vod__c);

        if (recByAcct == null)
            return trans;

        boolean createSampleOrderTransactions = false;
        if (!beforeCall.No_Disbursement_vod__c) {
            if (beforeCall.Status_vod__c == 'Submitted_vod' ||
                    (callHead.Status_vod__c == 'Saved_vod' && (
                                    callHead.Signature_vod__c != null || callHead.Sample_Card_vod__c != null ||
                                    callHead.Sample_Send_Card_vod__c != null) && VeevaSettings.isEnableSamplesOnSave()))
            {
                createSampleOrderTransactions = true;
            }
        }
        if (!createSampleOrderTransactions) {
            boolean isEnableSamplesOnSaveSign = VeevaSettings.isEnableSamplesOnSaveSign();
            if (isEnableSamplesOnSaveSign &&
                    (callHead.Signature_vod__c != null) &&
                    ((callHead.Status_vod__c == 'Saved_vod') || (callHead.Status_vod__c == 'Submitted_vod'))) {
                //#11953
                createSampleOrderTransactions = true;
            }
        }

        if (createSampleOrderTransactions) {
            if (callHead.Parent_Call_vod__c != null)
                parentCall = parents.get(callHead.Parent_Call_vod__c);

            Call2_vod__c call = calls.get(callHead.Id);

            if (callsWithOrders.contains(callHead.Name) == true)
                return trans;

            for (Call2_Sample_vod__c sample : call.Call2_Sample_vod__r) {
                if (sample.Delivery_Status_vod__c == 'Cancel_Request_vod' ||
                                sample.Delivery_Status_vod__c == 'Cancelled_vod')
                    continue;
                System.debug('Sample Id: ' + sample.Product_vod__c);
                Product_vod__c prodItem = products.get(sample.Product_vod__c);
                if (prodItem.Product_Type_vod__c == 'BRC') {
                    // CRM-34936 check if the field is blank and then use the old values
                    String deaValue = callHead.Ship_DEA_vod__c;
                    String assmca = callHead.Ship_ASSMCA_vod__c;
                    Date deaExpirationDate = callHead.Ship_DEA_Expiration_Date_vod__c;
                    if (String.isBlank(deaValue)) {
                        deaValue = callHead.DEA_vod__c;
                    }

                    if (String.isBlank(assmca)) {
                        assmca = callHead.ASSMCA_vod__c;
                    }

                    if (deaExpirationDate == null) {
                        deaExpirationDate = callHead.DEA_Expiration_Date_vod__c;
                    }

                    Sample_Order_Transaction_vod__c order = new Sample_Order_Transaction_vod__c (
                            Account_Name_vod__c = recByAcct.Name,
                            Account_Id_vod__c = recByAcct.Id,
                            Account_vod__c = recByAcct.Id,
                            Call_Name_vod__c = callHead.Name,
                            Call_Id_vod__c = callHead.Id,
                            Call_Sample_Name_vod__c = sample.Name,
                            Call_Sample_Id_vod__c = sample.Id,
                            Disclaimer_vod__c = callHead.Disclaimer_vod__c,
                            Signature_Date_vod__c = callHead.Signature_Date_vod__c,
                            Signature_vod__c = callHead.Signature_vod__c,
                            ASSMCA_vod__c = assmca,
                            DEA_Expiration_Date_vod__c = deaExpirationDate,
                            DEA_vod__c = deaValue,
                            Call_Date_vod__c = callHead.Call_Date_vod__c,
                            Call_Datetime_vod__c = callHead.Call_Datetime_vod__c,
                            Ship_Address_Line_1_vod__c = callHead.Ship_Address_Line_1_vod__c,
                            Ship_Address_Line_2_vod__c = callHead.Ship_Address_Line_2_vod__c,
                            Ship_City_vod__c = callHead.Ship_City_vod__c,
                            Ship_Country_vod__c = callHead.Ship_Country_vod__c,
                            Ship_License_Expiration_Date_vod__c = callHead.Ship_License_Expiration_Date_vod__c,
                            Ship_License_Status_vod__c = callHead.Ship_License_Status_vod__c,
                            Ship_License_vod__c = callHead.Ship_License_vod__c,
                            Ship_Location_vod__c = callHead.Ship_Location_vod__c,
                            Ship_State_vod__c = callHead.Ship_State_vod__c,
                            Ship_Zip_vod__c = callHead.Ship_Zip_vod__c,
                            Ship_Zip_4_vod__c = callHead.Ship_Zip_4_vod__c,
                            Status_vod__c = 'Submitted_vod',
                            Distributor_vod__c = sample.Distributor_vod__c,
                            Quantity_vod__c = sample.Quantity_vod__c,
                            Custom_Text_vod__c = sample.Custom_Text_vod__c,
                            Sample_vod__c = prodItem.Name,
                            Sample_U_M__c = prodItem.Sample_U_M_vod__c,
                            Territory_vod__c = callHead.Territory_vod__c,
                            Request_Receipt_vod__c = callHead.Request_Receipt_vod__c,
                            Sample_Send_Card_vod__c = callHead.Sample_Send_Card_vod__c,
                            Sample_Card_Reason_vod__c = callHead.Sample_Card_Reason_vod__c,
                            Manufacturer_vod__c = sample.Manufacturer_vod__c,
                            OwnerId = callHead.OwnerId,
                            Ship_CDS_vod__c = callHead.Ship_CDS_vod__c,
                            Signature_Page_Display_Name_vod__c = callHead.Signature_Page_Display_Name_vod__c,
                            Ship_CDS_Expiration_Date_vod__c = callHead.Ship_CDS_Expiration_Date_vod__c,
                            Ship_State_Distributor_vod__c = callHead.Ship_State_Distributor_vod__c,
                            Ship_State_Distributor_Exp_Date_vod__c = callHead.Ship_State_Distributor_Exp_Date_vod__c
                            
                    );
                    order.RecordTypeId = [Select Id, SobjectType, Name from RecordType where Name='BRC' and SobjectType='Sample_Order_Transaction_vod__c' limit 1].Id;
                    if (callHead.Sample_Send_Card_vod__c != null) {
                        System.debug('Setting Salutation and Credentials_vod__c on Sample Order record.');
                        order.Credentials_vod__c = recByAcct.Credentials_vod__c;
                        order.Salutation_vod__c = recByAcct.Salutation;
                    } else {
                        order.Credentials_vod__c = callHead.Credentials_vod__c;
                        order.Salutation_vod__c = callHead.Salutation_vod__c;
                    }

                    // now if a no lot vod exists for this product then
                    // add the reference to the lot for this sample order trasanction
                    // now based on the product type see if No_Lot_vod need to be checked or it has to be lot vod
                    Boolean bUseSamp = false;
                    System.debug('Looking for lot =' + 'No_Lot_vod' + ' Owner=' + callHead.OwnerId + ' Sample_vod__c=' +
                            order.Sample_vod__c);
                    String label = System.label.USE_MULTI_SAMPLE_vod;
                    if (label != null && label != 'false') {
                        bUseSamp = true;
                    }
                    System.debug('bUSeSamp=' + bUseSamp);

                    for (Sample_Lot_vod__c slot : sampleLots) {
                        system.debug('inside the lot for loop in creating sample order transaction');
                        system.debug(' the value of lot type from sample lot is ' +
                                slot.Product_vod__r.Product_Type_vod__c);
                        // if its not No_Lot_Vod and if the BRC is not in the veeva setting then do not copy the lot
                        if ('No_Lot_vod'.equals(slot.Name) && noLotProductTypes.contains('BRC')) {
                            if (slot.Name == 'No_Lot_vod' && callHead.OwnerId == slot.OwnerId &&
                                    (!bUseSamp || slot.Sample_vod__c == order.Sample_vod__c) &&
                                    (slot.Product_vod__r.Product_Type_vod__c == prodItem.Product_Type_vod__c)) {
                                order.Lot_vod__c = slot.Id;
                                order.RecordTypeId = sampleOrderRecTypeId;
                                order.Type_vod__c = 'BRC_vod';
                                System.debug('Found  lot =' + slot.Name + ' Owner=' + slot.OwnerId);
                                break;
                            }
                        } else {
                            order.Lot_vod__c = null;
                        }
                    }

                    trans.add(order);
                }
            }
        }
        return trans;
    }


    public static void stampShipToLocation(Call2_vod__c call) {
        if (call.Mobile_ID_vod__c != null && call.Ship_Location_Id_vod__c != null) {
            call.Ship_To_Location_vod__c = call.Ship_Location_Id_vod__c;
        }
    }

}