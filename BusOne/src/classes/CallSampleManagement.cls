public without sharing class CallSampleManagement {

    public static boolean inSampleManagement = false;
    public static List<Call2_Sample_vod__c> callSamples = new List<Call2_Sample_vod__c>();
    public static Map<Id, Sample_Limit_Transaction_vod__c> sampleLimitTrans = new Map<Id, Sample_Limit_Transaction_vod__c>();
    public static Set<String> productTypesToLock = new Set<String>{'Sample', 'BRC', 'Alternative Sample','High Value Promo Item'};

    public static void onSampleLimitTransactionCreated(List<Sample_Limit_Transaction_vod__c> transactions) {
        Set<String> callIds = new Set<String>();
        List<Call2_vod__c> calls = new List<Call2_vod__c>();
        for (Sample_Limit_Transaction_vod__c row : transactions) {
            if (row.Call2_Id_vod__c != null && !callIds.contains(row.Call2_Id_vod__c)) {
                callIds.add(row.Call2_Id_vod__c);
                calls.add(new Call2_vod__c(Id = row.Call2_Id_vod__c, Sample_Limit_Transaction_Created_vod__c = true));
            }
        }
        if (calls.size() > 0) {
            inSampleManagement = true;
            update calls;
            inSampleManagement = false;
        }
    }

    public static void onSampleDisbursementCreated(List<Sample_Transaction_vod__c> transactions) {
        Set<String> callNames = new Set<String>();
        for (Sample_Transaction_vod__c row : transactions) {
            if (row.Call_Name_vod__c != null) {
                callNames.add(row.Call_Name_vod__c);
            }
        }
        if (callNames.size() > 0) {
            List<Call2_vod__c> calls = new List<Call2_vod__c>();
            List<Call2_vod__c> rows = [select id from Call2_vod__c where name in :callNames and Disbursement_Order_Created_vod__c = false];
            for (Call2_vod__c call : rows) {
                calls.add(new Call2_vod__c(Id = call.id, Disbursement_Order_Created_vod__c = true));
            }
            if (calls.size() > 0) {
                inSampleManagement = true;
                update calls;
                inSampleManagement = false;
            }
        }
    }

    public static void onSampleOrderTransactionCreated(List<Sample_Order_Transaction_vod__c> transactions) {
        Set<String> callIds = new Set<String>();
        List<Call2_vod__c> calls = new List<Call2_vod__c>();
        for (Sample_Order_Transaction_vod__c row : transactions) {
            if (row.Call_Id_vod__c != null && !callIds.contains(row.Call_Id_vod__c) &&
                            row.Delivery_Status_vod__c != 'Cancel_Request_vod') {
                callIds.add(row.Call_Id_vod__c);
                calls.add(new Call2_vod__c(Id = row.Call_Id_vod__c, Disbursement_Order_Created_vod__c = true));
            }
        }
        if (calls.size() > 0) {
            inSampleManagement = true;
            update calls;
            inSampleManagement = false;
        }
    }

    public static void onDeleteCall(Map<Id, Call2_vod__c> toDelete) {
        if (toDelete.size() > 0) {
            List<Sample_Limit_Transaction_vod__c> rows =
            [select Id, Sample_Limit_vod__c, Quantity_To_Disperse_vod__c,Amount_To_Disburse_vod__c from Sample_Limit_Transaction_vod__c where Call2_vod__c in :toDelete.keySet()];
            for (Sample_Limit_Transaction_vod__c row: rows) {
                if (!sampleLimitTrans.containsKey(row.Id)) {
                    sampleLimitTrans.put(row.Id, row);
                }
            }
        }
    }

    public static void onCallSampleCancelled(Set<Id> callIds, Set<Id> callSampleIds) {
        Set<Id> sampleLimitIds = new Set<Id>();
        if (callIds.size() > 0) {
            List<Sample_Limit_Transaction_vod__c> rows =
            [select Id, Sample_Limit_vod__c, Quantity_To_Disperse_vod__c,Amount_To_Disburse_vod__c from Sample_Limit_Transaction_vod__c where Call2_vod__c in :callIds and Call2_Sample_Id_vod__c in :callSampleIds];
            
             for (Sample_Limit_Transaction_vod__c row: rows) {
                if (row.Sample_Limit_vod__c != null) {
                    sampleLimitIds.add(row.Sample_Limit_vod__c);
                }
                if (!sampleLimitTrans.containsKey(row.Id)) {
                    sampleLimitTrans.put(row.Id, row);
                }
            }
            if (sampleLimitIds.size() > 0) {
                UpdateLimits(sampleLimitIds, rows);
            }
        }
        sampleLimitTrans.clear();
    }

    public static void onDeleteCallSample(Map<Id, Call2_Sample_vod__c> toDelete) {

        inSampleManagement = true;
        sampleLimitTrans.clear();

        Set<Id> callIds = new Set<Id>();
        Set<Id> sampleLimitIds = new Set<Id>();

        // fetch related sample limits and calls
        List<Sample_Limit_Transaction_vod__c> rows =
            [select Id, Sample_Limit_vod__c, Quantity_To_Disperse_vod__c, Amount_To_Disburse_vod__c, Call2_vod__c
             from Sample_Limit_Transaction_vod__c where Call2_Sample_Id_vod__c in :toDelete.keySet()];
        for (Sample_Limit_Transaction_vod__c row : rows) {
            sampleLimitTrans.put(row.Id, row);
            if (row.Sample_Limit_vod__c != null) {
                sampleLimitIds.add(row.Sample_Limit_vod__c);
            }
            if (row.Call2_vod__c != null) {
                callIds.add(row.Call2_vod__c);
            }
        }
        if (sampleLimitTrans.size() > 0) {
            // revert limits
            UpdateLimits(sampleLimitIds, sampleLimitTrans.values());
            // delete sample limit transactions
            delete sampleLimitTrans.values();
            // update header field
            List<Call2_vod__c> calls = new List<Call2_vod__c>();
            for (Id id : callIds) {
                calls.add(new Call2_vod__c(Id = id, Sample_Limit_Transaction_Created_vod__c = false));
            }
            update calls;
        }

        sampleLimitTrans.clear();
        inSampleManagement = false;
    }

    private static void UpdateLimits(Set<Id> sampleLimitIds, List<Sample_Limit_Transaction_vod__c> transactions) {
        if (sampleLimitIds.size() > 0) {
            Map<Id, Sample_Limit_vod__c> sampleLimits = new Map<Id, Sample_Limit_vod__c>(
                [select id, Disbursed_Quantity_vod__c, Disbursed_Amount_vod__c from Sample_Limit_vod__c where id in :sampleLimitIds and Limit_Per_Call_vod__c = false]);
            for (Sample_Limit_Transaction_vod__c row : transactions) {
                Sample_Limit_vod__c sampleLimit = sampleLimits.get(row.Sample_Limit_vod__c);
                if (sampleLimit != null) {
                    if (sampleLimit.Disbursed_Quantity_vod__c != null && row.Quantity_To_Disperse_vod__c != null) {
                        sampleLimit.Disbursed_Quantity_vod__c -= row.Quantity_To_Disperse_vod__c;
                    }
                    if (sampleLimit.Disbursed_Amount_vod__c != null && row.Amount_To_Disburse_vod__c != null) {
                        sampleLimit.Disbursed_Amount_vod__c -= row.Amount_To_Disburse_vod__c;
                    }
                }
            }
            update sampleLimits.values();
        }
    }

    public static void applySampleLimit() {
        if (callSamples.size() == 0) {
            return;
        }

        Set<String> allIds = new Set<String> ();
        Map<String, List<Product_Group_vod__c>> productGroupMapping = new Map<String, List<Product_Group_vod__c>>();
        Map<String, List<String>> acctSamples = new Map<String, List<String>>();

        // variable to hold the multi currency
        Boolean isMultiCurrency = false;
        Map<String, String> productCurrenciesSGMap = new Map<String, String> (); // check for multicurrency
        String currCodeCSample = null;
        try {
            currCodeCSample = (String)callSamples[0].get('CurrencyIsoCode');
        } catch (System.SObjectException e) {
        }

        if (currCodeCSample != null) {
            isMultiCurrency = true;
        }

        for (Integer k = 0; k < callSamples.size(); k++) {
            Call2_vod__c myCall = callSamples[k].Call2_vod__r;
            String ownerId = myCall != null ? myCall.OwnerId : null;
            String AccountProd = VOD_CALL2_CHILD_COMMON.getLimitId(callSamples[k].Account_vod__c, callSamples[k].Product_vod__c, '');
            String AccountProdUser =
                    VOD_CALL2_CHILD_COMMON.getLimitId(callSamples[k].Account_vod__c, callSamples[k].Product_vod__c, ownerId);
            String UserProd = VOD_CALL2_CHILD_COMMON.getLimitId('', callSamples[k].Product_vod__c, ownerId);

            allIds.add(AccountProd);
            allIds.add(AccountProdUser);
            allIds.add(UserProd);

            // add for product group mapping
            List<String> samples = acctSamples.get(callSamples[k].Account_vod__c);
            if (samples == null) {
                samples = new List<String>();
                acctSamples.put(callSamples[k].Account_vod__c, samples);
            }
            samples.add(callSamples[k].Product_vod__c);

            if (!productGroupMapping.containsKey(callSamples[k].Product_vod__c)) {
                productGroupMapping.put(callSamples[k].Product_vod__c, new List<Product_Group_vod__c>());
            }
        }
        List<Product_Group_vod__c> rows =
        [Select Id,Start_Date_vod__c,End_Date_vod__c,Product_vod__c,Product_Catalog_vod__c From Product_Group_vod__c Where Product_vod__c
         In :productGroupMapping.keySet()];
        for (Product_Group_vod__c prodGrpObj:rows) {
            List<Product_Group_vod__c> pgs = productGroupMapping.get(prodGrpObj.Product_vod__c);
            pgs.add(prodGrpObj);
        }

        // generate group ids for sample product groups
        for (String acctId : acctSamples.keySet()) {
            List<String> sampleIds = acctSamples.get(acctId);
            for (String sampleId : sampleIds) {
                List<Product_Group_vod__c> prodGroups = productGroupMapping.get(sampleId);
                for (Product_Group_vod__c prodGroup : prodGroups) {
                    allIds.add(VOD_CALL2_CHILD_COMMON.getLimitId(acctId, prodGroup.Product_Catalog_vod__c, ''));
                }
            }
        }
        Map<String, List<Sample_Limit_vod__c>> mapSLbyExtId = new Map<String, List<Sample_Limit_vod__c>>();
        Map<String, Sample_Limit_vod__c> updateMap = new Map<String, Sample_Limit_vod__c> ();
        List<Sample_Limit_Transaction_vod__c> transactions = new List<Sample_Limit_Transaction_vod__c> ();

        String sampleLimitQuery;

        if (isMultiCurrency) {
            sampleLimitQuery = 'Select Name,External_Id_vod__c,Account_vod__c, Account_vod__r.Formatted_Name_vod__c,' +
                    'Disbursed_Quantity_vod__c, End_Date_vod__c, Enforce_Limit_vod__c, Group_Id_vod__c,' +
                    'Id, Limit_Per_Call_vod__c, Limit_Quantity_vod__c, Product_vod__c, Product_vod__r.Name,' +
                    'Remaining_Quantity_vod__c, Sample_Limit_Type_vod__c, Start_Date_vod__c, User_vod__c,' +
                    'Limit_Amount_vod__c, Disbursed_Amount_vod__c, Remaining_Amount_vod__c, Product_vod__r.CurrencyIsoCode,' +
                    'User_vod__r.Username, CurrencyIsoCode FROM Sample_Limit_vod__c Where Group_Id_vod__c in :allIds';

        } else {
            sampleLimitQuery = 'Select Name,External_Id_vod__c,Account_vod__c, Account_vod__r.Formatted_Name_vod__c,' +
                    'Disbursed_Quantity_vod__c, End_Date_vod__c, Enforce_Limit_vod__c, Group_Id_vod__c,' +
                    'Id, Limit_Per_Call_vod__c, Limit_Quantity_vod__c, Product_vod__c, Product_vod__r.Name,' +
                    'Remaining_Quantity_vod__c, Sample_Limit_Type_vod__c, Start_Date_vod__c, User_vod__c,' +
                    'Limit_Amount_vod__c, Disbursed_Amount_vod__c, Remaining_Amount_vod__c,' +
                    'User_vod__r.Username FROM Sample_Limit_vod__c Where Group_Id_vod__c in :allIds';
        }

        List<Sample_Limit_vod__c> sampleLimits = Database.query(sampleLimitQuery);
        for (Sample_Limit_vod__c limitObj : sampleLimits) {

            String acctId = limitObj.Account_vod__c;
            if (acctId != null && !limitObj.Group_Id_vod__c.startsWith(acctId.substring(0, 15))) {
                continue;
            }

            List<Sample_Limit_vod__c> thisLimit = mapSLbyExtId.get(limitObj.Group_Id_vod__c);
            if (thisLimit == null) {
                thisLimit = new List<Sample_Limit_vod__c> ();
            }
            thisLimit.add(limitObj);
            mapSLbyExtId.put(limitObj.Group_Id_vod__c, thisLimit);

            // add all product ids of product type sample product group to get the currencies
            if (isMultiCurrency) {
                SOBject pInterface = (SObject)limitObj.Product_vod__r;
                try {
                    productCurrenciesSGMap.put(limitObj.Product_vod__c, (String)pInterface.get('CurrencyIsoCode'));
                } catch (System.SObjectException e) {
                }
            }
        }

        system.debug(' the values of product group currencies are ' + productCurrenciesSGMap);

        CallSampleManagement.unlockPromoItemsWithoutLimits(mapSLbyExtId);

        if (mapSLbyExtId.size() > 0) {
            for (Integer k = 0; k < callSamples.size(); k++) {
                Call2_vod__c myCall = callSamples[k].Call2_vod__r;
                String ownerId = null;
                Date CallDate = null;

                if (myCall != null) {
                    ownerId = myCall.OwnerId;
                    CallDate = callSamples[k].Call_Date_vod__c;

                }
                System.Debug('cRow=' + callSamples[k]);
                String AccountProd = VOD_CALL2_CHILD_COMMON.getLimitId(callSamples[k].Account_vod__c, callSamples[k].Product_vod__c, '');
                String AccountProdUser =
                        VOD_CALL2_CHILD_COMMON.getLimitId(callSamples[k].Account_vod__c, callSamples[k].Product_vod__c, ownerId);
                String UserProd = VOD_CALL2_CHILD_COMMON.getLimitId('', callSamples[k].Product_vod__c, ownerId);

                List<Sample_Limit_vod__c> AccountProdLst = mapSLbyExtId.get(AccountProd);
                List<Sample_Limit_vod__c> AccountProdUserLst = mapSLbyExtId.get(AccountProdUser);
                List<Sample_Limit_vod__c> UserProdList = mapSLbyExtId.get(UserProd);

                Boolean isValueIgnore = false;

                if (AccountProdLst != null && AccountProdLst.size() > 0) {
                    for (Sample_Limit_vod__c myLimit : AccountProdLst) {
                        if (CallDate >= myLimit.Start_Date_vod__c && CallDate <= myLimit.End_Date_vod__c) {

                            // here check if the multicurrency org and skip the currencies that do not match
                            SObject slInterface = (SObject) myLimit;
                            System.debug(' value of my limit is  ' + myLimit);
                            String currCodeSL = null; // now get the currency for product
                            SOBject prodInterface = (SObject) callSamples[k];
                            String currCodeProd = null;
                            try {
                                currCodeSL = (String)slInterface.get('CurrencyIsoCode');
                                currCodeProd = (String)prodInterface.get('CurrencyIsoCode');
                            } catch (System.SObjectException e) {
                            }

                            // just for debugging purposes
                            System.debug('in the account product combination ');
                            System.debug('the sample limit currency value is   ' + currCodeSL);
                            System.debug('the product currency value is    ' + currCodeProd);

                            Sample_Limit_vod__c checkLimit = updateMap.get(myLimit.Id);
                            if (checkLimit != null) {
                                // check the currencies and continue is its not same
                                if (currCodeSL != null && currCodeProd != null) {
                                    // means multicurrency org
                                    if (!currCodeSL.equals(currCodeProd)) {
                                        isValueIgnore = true;
                                    }
                                }
                                System.debug('CheckLimit=' + checkLimit);
                                if (isValueIgnore) {
                                    // check if its only value limit or both
                                    if (checkLimit.Limit_Quantity_vod__c != null) {
                                        // both
                                        Sample_Limit_Transaction_vod__c slT =
                                                VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], checkLimit, myCall,
                                                        isValueIgnore);
                                        transactions.add(slT);
                                    } else {
                                        // only value limit
                                        continue;
                                    }
                                } else {
                                    // is value ignore is false either due to non multi currency org or the currencies matched
                                    Sample_Limit_Transaction_vod__c slT =
                                            VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], checkLimit, myCall, false);
                                    transactions.add(slT);
                                }
                                if (checkLimit.Limit_Amount_vod__c != null && checkLimit.Disbursed_Amount_vod__c == null) {
                                    checkLimit.Disbursed_Amount_vod__c = 0.0;
                                }
                                if (checkLimit.Disbursed_Quantity_vod__c == null) {
                                    checkLimit.Disbursed_Quantity_vod__c = 0;
                                }
                                if (checkLimit.Limit_Per_Call_vod__c == false) {
                                    checkLimit.Disbursed_Quantity_vod__c +=
                                            callSamples[k].Quantity_vod__c; // add condition if its only amount limit we need to update those amount fields
                                    if (checkLimit.Limit_Amount_vod__c != null && callSamples[k].Amount_vod__c != null &&
                                            !isValueIgnore) {
                                        checkLimit.Disbursed_Amount_vod__c += callSamples[k].Amount_vod__c;
                                    }
                                }
                                updateMap.put(checkLimit.Id, checkLimit);
                            } else {
                                System.debug('myLimit=' +
                                        myLimit); // check for the currencies and skip if there are not same
                                // check the currencies and continue is its not same
                                if (currCodeSL != null && currCodeProd != null) {
                                    // means multicurrency org
                                    if (!currCodeSL.equals(currCodeProd)) {
                                        isValueIgnore = true;
                                    }
                                }
                                if (myLimit.Disbursed_Quantity_vod__c == null) {
                                    myLimit.Disbursed_Quantity_vod__c = 0;
                                }

                                if (isValueIgnore) {
                                    // now check if its quantity, value or both
                                    if (myLimit.Limit_Quantity_vod__c != null) {
                                        // only quantity limit
                                        Sample_Limit_Transaction_vod__c slT =
                                                VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], myLimit, myCall,
                                                        isValueIgnore);
                                        transactions.add(slT);
                                    } else {
                                        // only value limit
                                        continue;
                                    }
                                } else {
                                    // either currency matched or non multi currency org
                                    Sample_Limit_Transaction_vod__c slT =
                                            VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], myLimit, myCall, false);
                                    transactions.add(slT);
                                }
                                if (myLimit.Limit_Amount_vod__c != null && myLimit.Disbursed_Amount_vod__c == null) {
                                    myLimit.Disbursed_Amount_vod__c = 0.0;
                                }
                                if (myLimit.Limit_Per_Call_vod__c == false) {
                                    myLimit.Disbursed_Quantity_vod__c += callSamples[k].Quantity_vod__c;
                                    if (myLimit.Limit_Amount_vod__c != null && callSamples[k].Amount_vod__c != null &&
                                            !isValueIgnore) {
                                        myLimit.Disbursed_Amount_vod__c += callSamples[k].Amount_vod__c;
                                    }
                                }
                                updateMap.put(myLimit.Id, myLimit);
                            }
                        }
                    }
                }
                if (AccountProdUserLst != null && AccountProdUserLst.size() > 0) {
                    for (Sample_Limit_vod__c myLimit : AccountProdUserLst) {
                        if (CallDate >= myLimit.Start_Date_vod__c && CallDate <= myLimit.End_Date_vod__c) {
                            // check for multicurrency and their corresponding values
                            SObject slInterface = (SObject)myLimit;
                            String currCodeSL = null; // now get the currency for product
                            SOBject prodInterface = (SObject) callSamples[k];
                            String currCodeProd = null;
                            try {
                                currCodeSL = (String)slInterface.get('CurrencyIsoCode');
                                currCodeProd = (String)prodInterface.get('CurrencyIsoCode');
                            } catch (System.SObjectException e) {
                            }

                            Sample_Limit_vod__c checkLimit = updateMap.get(myLimit.Id);
                            if (checkLimit != null) {
                                System.debug('CheckLimit=' + checkLimit);

                                // check the currencies and continue if its not same
                                if (currCodeSL != null && currCodeProd != null) {
                                    // means multicurrency org
                                    if (!currCodeSL.equals(currCodeProd)) {
                                        isValueIgnore = true;
                                    }
                                }
                                if (isValueIgnore) {
                                    // now check if its quantity, value or both
                                    if (checkLimit.Limit_Quantity_vod__c != null) {
                                        Sample_Limit_Transaction_vod__c slT =
                                                VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], checkLimit, myCall,
                                                        isValueIgnore);
                                        transactions.add(slT);
                                    } else {
                                        continue;
                                    }
                                } else {
                                    Sample_Limit_Transaction_vod__c slT =
                                            VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], checkLimit, myCall, false);
                                    transactions.add(slT);
                                }
                                if (checkLimit.Limit_Amount_vod__c != null &&
                                                checkLimit.Disbursed_Amount_vod__c == null) {
                                    checkLimit.Disbursed_Amount_vod__c = 0.0;
                                }
                                if (checkLimit.Disbursed_Quantity_vod__c == null) {
                                    checkLimit.Disbursed_Quantity_vod__c = 0;
                                }
                                if (checkLimit.Limit_Per_Call_vod__c == false) {
                                    checkLimit.Disbursed_Quantity_vod__c += callSamples[k].Quantity_vod__c;
                                    if (checkLimit.Limit_Amount_vod__c != null && callSamples[k].Amount_vod__c != null &&
                                            !isValueIgnore) {
                                        checkLimit.Disbursed_Amount_vod__c += callSamples[k].Amount_vod__c;
                                    }
                                }
                                updateMap.put(checkLimit.Id, checkLimit);
                            } else {
                                System.debug('myLimit=' + myLimit); // check the currencies and continue if its not same
                                if (currCodeSL != null && currCodeProd != null) {
                                    // means multicurrency org
                                    if (!currCodeSL.equals(currCodeProd)) {
                                        isValueIgnore = true;
                                    }
                                }
                                if (myLimit.Disbursed_Quantity_vod__c == null) {
                                    myLimit.Disbursed_Quantity_vod__c = 0;
                                } // add default to the disbursed amount field
                                if (myLimit.Limit_Amount_vod__c != null && myLimit.Disbursed_Amount_vod__c == null) {
                                    myLimit.Disbursed_Amount_vod__c = 0.0;
                                }
                                if (isValueIgnore) {
                                    // now check if its quantity, value or both
                                    if (myLimit.Limit_Quantity_vod__c != null) {
                                        Sample_Limit_Transaction_vod__c slT =
                                                VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], myLimit, myCall,
                                                        isValueIgnore);
                                        transactions.add(slT);
                                    } else {
                                        continue;
                                    }
                                } else {
                                    Sample_Limit_Transaction_vod__c slT =
                                            VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], myLimit, myCall, false);
                                    transactions.add(slT);
                                }
                                if (myLimit.Limit_Per_Call_vod__c == false) {
                                    myLimit.Disbursed_Quantity_vod__c += callSamples[k].Quantity_vod__c;
                                    if (myLimit.Limit_Amount_vod__c != null && callSamples[k].Amount_vod__c != null &&
                                            !isValueIgnore) {
                                        myLimit.Disbursed_Amount_vod__c += callSamples[k].Amount_vod__c;
                                    }
                                }
                                updateMap.put(myLimit.Id, myLimit);
                            }
                        }
                    }
                }
                if (UserProdList != null && UserProdList.size() > 0) {
                    for (Sample_Limit_vod__c myLimit : UserProdList) {
                        if (CallDate >= myLimit.Start_Date_vod__c && CallDate <= myLimit.End_Date_vod__c) {
                            Sample_Limit_vod__c checkLimit =
                                    updateMap.get(myLimit.Id); // check for multicurrency and their corresponding values
                            SObject slInterface = (SObject)myLimit;
                            String currCodeSL = null; // now get the currency for product
                            SOBject prodInterface = (SObject) callSamples[k];
                            String currCodeProd = null;
                            try {
                                currCodeSL = (String)slInterface.get('CurrencyIsoCode');
                                currCodeProd = (String)prodInterface.get('CurrencyIsoCode');
                            } catch (System.SObjectException e) {
                            }

                            System.debug('in the user product combination ');
                            System.debug('the sample limit currency value is   ' + currCodeSL);
                            System.debug('the product currency value is    ' + currCodeProd);
                            if (checkLimit != null) {
                                    System.debug('CheckLimit=' + checkLimit);
                                    // check the currencies and continue if its not same
                                if (currCodeSL != null && currCodeProd != null) {
                                    // means multicurrency org
                                    if (!currCodeSL.equals(currCodeProd)) {
                                        isValueIgnore = true;
                                    }
                                }
                                if (isValueIgnore) {
                                    // now check if its quantity, value or both
                                    if (checkLimit.Limit_Quantity_vod__c != null) {
                                        Sample_Limit_Transaction_vod__c slT =
                                                VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], checkLimit, myCall,
                                                        isValueIgnore);
                                        transactions.add(slT);
                                    } else {
                                        continue;
                                    }
                                } else {
                                    Sample_Limit_Transaction_vod__c slT =
                                            VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], checkLimit, myCall, false);
                                    transactions.add(slT);
                                }
                                if (checkLimit.Limit_Amount_vod__c != null &&
                                                checkLimit.Disbursed_Amount_vod__c == null) {
                                    checkLimit.Disbursed_Amount_vod__c = 0.0;
                                }
                                if (checkLimit.Disbursed_Quantity_vod__c == null) {
                                    checkLimit.Disbursed_Quantity_vod__c = 0;
                                }
                                if (checkLimit.Limit_Per_Call_vod__c == false) {
                                    checkLimit.Disbursed_Quantity_vod__c += callSamples[k].Quantity_vod__c;
                                    if (checkLimit.Limit_Amount_vod__c != null && callSamples[k].Amount_vod__c != null &&
                                            !isValueIgnore) {
                                        checkLimit.Disbursed_Amount_vod__c += callSamples[k].Amount_vod__c;
                                    }
                                }
                                updateMap.put(checkLimit.Id, checkLimit);
                            } else {
                                System.debug('myLimit=' + myLimit); // check the currencies and continue if its not same
                                if (currCodeSL != null && currCodeProd != null) {
                                    // means multicurrency org
                                    if (!currCodeSL.equals(currCodeProd)) {
                                        isValueIgnore = true;
                                    }
                                }
                                if (myLimit.Disbursed_Quantity_vod__c == null) {
                                    myLimit.Disbursed_Quantity_vod__c = 0;
                                } // set default to disbursed amount
                                if (myLimit.Limit_Amount_vod__c != null && myLimit.Disbursed_Amount_vod__c == null) {
                                    myLimit.Disbursed_Amount_vod__c = 0.0;
                                }
                                if (isValueIgnore) {
                                    // now check if its quantity, value or both
                                    if (myLimit.Limit_Quantity_vod__c != null) {
                                        Sample_Limit_Transaction_vod__c slT =
                                                VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], myLimit, myCall,
                                                        isValueIgnore);
                                        transactions.add(slT);
                                    } else {
                                        continue;
                                    }
                                } else {
                                    Sample_Limit_Transaction_vod__c slT =
                                            VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], myLimit, myCall, false);
                                    transactions.add(slT);
                                }
                                if (myLimit.Limit_Per_Call_vod__c == false) {
                                    myLimit.Disbursed_Quantity_vod__c += callSamples[k].Quantity_vod__c;
                                    if (myLimit.Limit_Amount_vod__c != null && callSamples[k].Amount_vod__c != null &&
                                            !isValueIgnore) {
                                        myLimit.Disbursed_Amount_vod__c += callSamples[k].Amount_vod__c;
                                    }
                                }
                                updateMap.put(myLimit.Id, myLimit);
                            }
                        }
                    }
                }

                // now determine which sample group limits need to be updated
                List<Product_Group_vod__c> prodGroups = productGroupMapping.get(callSamples[k].Product_vod__c);
                if (prodGroups != null) {
                    Set<Sample_limit_vod__c> acctGroupSet = new Set<Sample_limit_vod__c>();
                    for (Product_Group_vod__c prodGroup : prodGroups) {
                        // verify what active groups the product belongs to
                        if (CallDate >= prodGroup.Start_Date_vod__c && CallDate <= prodGroup.End_Date_vod__c) {
                            List<Sample_Limit_vod__c> acctGroupList = mapSLbyExtId.get(
                                    VOD_CALL2_CHILD_COMMON.getLimitId(callSamples[k].Account_vod__c, prodGroup.Product_Catalog_vod__c, ''));
                            if (acctGroupList != null) {
                                acctGroupSet.addAll(acctGroupList);
                            }
                        }
                    }
                    for (Sample_Limit_vod__c myLimit : acctGroupSet) {
                        if (CallDate >= myLimit.Start_Date_vod__c && CallDate <= myLimit.End_Date_vod__c) {
                            // here check if the multicurrency org and skip the currencies that do not match
                            SObject slInterface = (SObject)myLimit;
                            String currCodeSL = null; // now get the currency for product
                            String currCodeProd = null;
                            if (productCurrenciesSGMap != null && productCurrenciesSGMap.size() > 0) {
                                currCodeProd = productCurrenciesSGMap.get(myLimit.Product_vod__c);
                            }
                            try {
                                currCodeSL = (String)slInterface.get('CurrencyIsoCode');
                            } catch (System.SObjectException e) {
                            }

                            system.debug(' the group sample limit case the SL currency is ' + currCodeSL);
                            system.debug(' the group sample limit case the SL currency is ' + currCodeProd);

                            Sample_Limit_vod__c checkLimit = updateMap.get(myLimit.Id);
                            if (checkLimit != null) {
                                    System.debug('CheckLimit=' + checkLimit);
                                    // check the currencies and continue is its not same
                                if (currCodeSL != null && currCodeProd != null) {
                                    // means multicurrency org
                                    if (!currCodeSL.equals(currCodeProd)) {
                                        isValueIgnore = true;
                                    }
                                }
                                if (isValueIgnore) {
                                    // now check if its quantity, value or both
                                    if (checkLimit.Limit_Quantity_vod__c != null) {
                                        Sample_Limit_Transaction_vod__c slT =
                                                VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], checkLimit, myCall,
                                                        isValueIgnore);
                                        transactions.add(slT);
                                    } else {
                                        continue;
                                    }
                                } else {
                                    Sample_Limit_Transaction_vod__c slT =
                                            VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], checkLimit, myCall, false);
                                    transactions.add(slT);
                                }
                                if (checkLimit.Limit_Amount_vod__c != null &&
                                                checkLimit.Disbursed_Amount_vod__c == null) {
                                    checkLimit.Disbursed_Amount_vod__c = 0.0;
                                }
                                if (checkLimit.Disbursed_Quantity_vod__c == null) {
                                    checkLimit.Disbursed_Quantity_vod__c = 0;
                                }
                                if (checkLimit.Limit_Per_Call_vod__c == false) {
                                    checkLimit.Disbursed_Quantity_vod__c += callSamples[k].Quantity_vod__c;
                                    if (checkLimit.Limit_Amount_vod__c != null &&
                                                    callSamples[k].Amount_vod__c != null && !isValueIgnore) {
                                        checkLimit.Disbursed_Amount_vod__c += callSamples[k].Amount_vod__c;
                                    }
                                }
                                updateMap.put(checkLimit.Id, checkLimit);
                            } else {
                                System.debug('myLimit=' + myLimit); // check the currencies and continue is its not same
                                if (currCodeSL != null && currCodeProd != null) {
                                    // means multicurrency org
                                    if (!currCodeSL.equals(currCodeProd)) {
                                        isValueIgnore = true;
                                    }
                                }
                                if (isValueIgnore) {
                                    // now check if its quantity, value or both
                                    if (myLimit.Limit_Quantity_vod__c != null) {
                                        Sample_Limit_Transaction_vod__c slT =
                                                VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], myLimit, myCall,
                                                        isValueIgnore);
                                        transactions.add(slT);
                                    } else {
                                        continue;
                                    }
                                } else {
                                    Sample_Limit_Transaction_vod__c slT =
                                            VOD_CALL2_CHILD_COMMON.createTransactionRecord(callSamples[k], myLimit, myCall, false);
                                    transactions.add(slT);
                                }
                                if (myLimit.Disbursed_Quantity_vod__c == null) {
                                    myLimit.Disbursed_Quantity_vod__c = 0;
                                }
                                if (myLimit.Limit_Amount_vod__c != null &&
                                                myLimit.Disbursed_Amount_vod__c == null) {
                                    myLimit.Disbursed_Amount_vod__c = 0.0;
                                }
                                if (myLimit.Limit_Per_Call_vod__c == false) {
                                    myLimit.Disbursed_Quantity_vod__c += callSamples[k].Quantity_vod__c;
                                    if (myLimit.Limit_Amount_vod__c != null && callSamples[k].Amount_vod__c != null &&
                                            !isValueIgnore) {
                                        myLimit.Disbursed_Amount_vod__c += callSamples[k].Amount_vod__c;
                                    }
                                }
                                updateMap.put(myLimit.Id, myLimit);
                            }
                        }
                    }
                }
            }

            if (transactions.size() > 0) {
                inSampleManagement = true;
                insert transactions;
            }
            if (updateMap.size() > 0) {
                inSampleManagement = true;
                update updateMap.values();
            }
            callSamples.clear();
            inSampleManagement = false;
        }
    }

    public static void unlockPromoItemsWithoutLimits(Map<String, List<Sample_Limit_vod__c>> mapSLbyExtId) {
        List<Call2_Sample_vod__c> unlockSamples = new List<Call2_Sample_vod__c>();
        Set<Id> sampleProducts = new Set<Id>();
        for (Integer k = 0; k < callSamples.size(); k++) {
            sampleProducts.add(callSamples[k].Product_vod__c);
        }
        Map<Id, Product_vod__c> idToProductType = new Map<Id, Product_vod__c>([Select Id, Product_Type_vod__c from Product_vod__c where Id in :sampleProducts]);
        for (Integer k = 0; k < callSamples.size(); k++) {
            if (idToProductType.get(callSamples[k].Product_vod__c) == null || productTypesToLock.contains(idToProductType.get(callSamples[k].Product_vod__c).Product_Type_vod__c))
                continue;
            Date CallDate = null;
            Call2_vod__c myCall = callSamples[k].Call2_vod__r;
            String ownerId = myCall != null ? myCall.OwnerId : null;

            if (myCall != null) {
                ownerId = myCall.OwnerId;
                CallDate = callSamples[k].Call_Date_vod__c;
            }

            String AccountProd = VOD_CALL2_CHILD_COMMON.getLimitId(callSamples[k].Account_vod__c, callSamples[k].Product_vod__c, '');
            String AccountProdUser = VOD_CALL2_CHILD_COMMON.getLimitId(callSamples[k].Account_vod__c, callSamples[k].Product_vod__c, ownerId);
            String UserProd = VOD_CALL2_CHILD_COMMON.getLimitId('', callSamples[k].Product_vod__c, ownerId);

            List<Sample_Limit_vod__c> allLimits = new List<Sample_Limit_vod__c>();
            if (mapSLbyExtId.get(AccountProd) != null)
                allLimits.addAll(mapSLbyExtId.get(AccountProd));
            if (mapSLbyExtId.get(AccountProdUser) != null)
                allLimits.addAll(mapSLbyExtId.get(AccountProdUser));
            if (mapSLbyExtId.get(UserProd) != null)
                allLimits.addAll(mapSLbyExtId.get(UserProd));
            boolean validSampleLimit = false;
            if (allLimits.size() > 0) {
                for (Sample_Limit_vod__c myLimit : allLimits) {
                    if (CallDate >= myLimit.Start_Date_vod__c && CallDate <= myLimit.End_Date_vod__c) {
                        validSampleLimit = true;
                        break;
                    }
                }
            }
            if (validSampleLimit)
                continue;
            Call2_Sample_vod__c sample = callSamples[k];
            sample.Apply_Limit_vod__c = false;
            sample.Limit_Applied_vod__c = false;
            unlockSamples.add(sample);
        }
        if (unlockSamples.size() > 0) {
            inSampleManagement = true;
            update unlockSamples;
            inSampleManagement = false;
        }
    }
}