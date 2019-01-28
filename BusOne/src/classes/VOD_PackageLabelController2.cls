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
 * Copyright (c) 2009 Verticals onDemand, Inc.  All Rights Reserved.
 *
 ******************************************************************************/

/* Apex Class used to provide data for a package label that will be displayed by a Visualforce page */
public with sharing class VOD_PackageLabelController2 {

    private List<TransactionRow> theTransactions = null;
    private Rep_Roster_vod__c sender = null;
    private Rep_Roster_vod__c recipient = null;

    /*
     * Retrieve sample transaction records for each id passed in.  Modify this method if any custom data from
     * Sample_Transaction_vod__c and Product_vod__c should be included in the package label.
     */
    private void loadTransactions() {
        if (theTransactions != null)
            return;

        theTransactions = new List<TransactionRow>();

        String ids = ApexPages.currentPage().getParameters().get('ids');
        if ((ids == null) || (ids == '')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Sample transaction id is not specified'));
            return;
        }

        String[] idList = ids.split(',');
        try {
            // Sample_Transaction_vod__c query.  Add custom fields here.
            List<Sample_Transaction_vod__c> samTrans = [Select Id,Name,Adjusted_Date_vod__c,Lot_Name_vod__c,Lot_vod__r.Name,Lot_vod__r.OwnerId,
                            Quantity_vod__c,RecordTypeId,RecordType.Name,Return_To_vod__c,Sample_vod__c,Submitted_Date_vod__c,Transfer_To_vod__c,
                            Transferred_Date_vod__c,CreatedDate,toLabel(Reason_vod__c),toLabel(U_M_vod__c)
                    From Sample_Transaction_vod__c Where Id In :idList];

            for (Sample_Transaction_vod__c samTran : samTrans) {
                if ('No_Lot_vod'.equals(samTran.Lot_vod__r.Name)) {
                    samTran.Lot_vod__r.Name = '';
                }
            }

            Set<String> prodList = new Set<String>();
            for (Sample_Transaction_vod__c samTran : samTrans) {
                prodList.add(samTran.Sample_vod__c);
            }

            Map<String,Product_vod__c> samples = new Map<String,Product_vod__c>();
            // Product_vod__c query.  Add custom fields here.
            for (Product_vod__c sample : [Select Id,Name,Description_vod__c,toLabel(Manufacturer_vod__c) From Product_vod__c Where Name In :prodList]) {
                samples.put(sample.Name, sample);
            }

            // Constructs list of sample transactions, matching data in product catalog to the product specified in the sample transaction record.
            for (Sample_Transaction_vod__c samTran : samTrans) {
                TransactionRow aRow = new TransactionRow();
                aRow.samTran = samTran;
                aRow.sample = samples.get(samTran.Sample_vod__c);
                theTransactions.add(aRow);
            }
        }
        catch (System.QueryException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Sample transaction(s) cannot be found'));
            return;
        }
    }

    /*
     * Retrieves additional information about user from Rep_Roster_vod__c object.  Modify this method if any custom
     * data from Rep_Roster_vod__c needs to be displayed in the package label.
     */
    private Rep_Roster_vod__c loadRepRoster(String userName) {
        try {
            // Rep_Roster_vod__c query.  Add custom fields here.
            Rep_Roster_vod__c repRoster = [Select Id,Name,Address_Line_1_vod__c,Address_Line_2_vod__c,City_vod__c,State_vod__c,
                    Username_External_Id_vod__c,Zip_vod__c,Territory_vod__c,Home_Phone__c
                    From Rep_Roster_vod__c Where Username_External_Id_vod__c=:userName];
            return repRoster;
        }
        catch (System.QueryException e) {
        }
        return null;
    }

    /* The sender is the owner of the sample lot specified in the sample transaction record */
    public Rep_Roster_vod__c getSender() {
        if (sender != null)
            return sender;

        loadTransactions();
        if (theTransactions.size() == 0)
            return new Rep_Roster_vod__c();

        String lotOwnerId = theTransactions[0].samTran.Lot_vod__r.OwnerId;
        try {
            User usr = [Select Username From User Where Id=:lotOwnerId];
            sender = loadRepRoster(usr.Username);
            if (sender != null)
                return sender;
        }
        catch (System.QueryException e) {
        }

        sender = new Rep_Roster_vod__c();
        return sender;
    }

    /*
     * The recipient is dependent on the record type of the sample transaction record.  If this is a transfer,
     * look at the Transfer_To_vod__c field in the sample transaction.  If this is a return, look at the
     * Return_To_vod__c field in the sample transaction.
     */
    public Rep_Roster_vod__c getRecipient() {
        if (recipient != null)
            return recipient;

        loadTransactions();
        if (theTransactions.size() == 0)
            return new Rep_Roster_vod__c();

        String rName = null;
        if (theTransactions[0].samTran.RecordType.Name == 'Transfer_vod') {
            String rId = theTransactions[0].samTran.Transfer_To_vod__c;
            try {
                User usr = [Select Username From User Where Id=:rId];
                rName = usr.Username;
            }
            catch (System.QueryException e) {
            }
        }
        else if (theTransactions[0].samTran.RecordType.Name == 'Return_vod')
            rName = theTransactions[0].samTran.Return_To_vod__c;

        recipient = loadRepRoster(rName);
        if (recipient != null)
            return recipient;

        recipient = new Rep_Roster_vod__c();
        return recipient;
    }

    /* The number of sample transaction records */
    public Integer getTotalLineItems() {
        loadTransactions();
        return theTransactions.size();
    }

    /* The list of sample transactions used in package label */
    public List<TransactionRow> getTransactions() {
        loadTransactions();
        return theTransactions;
    }

    /* Retrieves the first sample transaction record for any "header" information */
    public Sample_Transaction_vod__c getTransaction() {
        loadTransactions();
        if (theTransactions.size() == 0)
            return new Sample_Transaction_vod__c();
        return theTransactions[0].samTran;
    }

    /* Transfer type? */
    public boolean getIsTransfer() {
        loadTransactions();
        if (theTransactions.size() == 0)
            return false;
        return (theTransactions[0].samTran.RecordType.Name == 'Transfer_vod');
    }

    /* Return type? */
    public boolean getIsReturn() {
        loadTransactions();
        if (theTransactions.size() == 0)
            return false;
        return (theTransactions[0].samTran.RecordType.Name == 'Return_vod');
    }

    /* Helper method to retrieve record type label from metadata */
    public String getTransactionRecordTypeLabel() {
        loadTransactions();
        if (theTransactions.size() == 0)
            return '';

        List<Schema.RecordTypeInfo> rts = Schema.SObjectType.Sample_Transaction_vod__c.recordTypeInfos;
        for (Schema.RecordTypeInfo rt : rts) {
            if (theTransactions[0].samTran.RecordTypeId == rt.getRecordTypeId())
                return rt.getName();
        }

        return '';
   }

    // Helper class to represent a sample transaction row */
    public class TransactionRow {
        public Sample_Transaction_vod__c samTran{get;set;}
        public Product_vod__c sample{get;set;}
    }

}