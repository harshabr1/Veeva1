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

/* Apex Class used to provide a list of sample transactions that will be displayed by a Visualforce page */
public with sharing class VOD_PackageLabelController {

    private Sample_Transaction_vod__c samTran = null;
    private List<TransactionRow> theTransactions = null;

    /* Loads sample transaction record passed in through id query parameter */
    private void loadTransaction() {
        if (samTran != null)
            return;

        String tranId = ApexPages.currentPage().getParameters().get('id');
        if ((tranId == null) || (tranId == '')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Sample transaction id is not specified'));
            return;
        }

        try {
            samTran = [Select Id,Address_Line_1_vod__c,Address_Line_2_vod__c,Adjust_For_vod__c,Adjusted_Date_vod__c, Lot_vod__r.Name,
                    City_vod__c,CreatedDate,RecordType.Name,Return_To_vod__c,State_vod__c,Transfer_To_vod__c,Transferred_From_vod__c,Zip_vod__c
                    From Sample_Transaction_vod__c Where Id=:tranId];
        }
        catch (System.QueryException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Sample transaction cannot be found'));
            return;
        }
    }

    /*
     *  Retrieves sample transactions that share the same two parties, addresses and record type within a certain time period
     *  (-14 days, +1 day from source sample transaction's created date)
     */
    private void loadHistory() {
        if (theTransactions != null)
            return;

        theTransactions = new List<TransactionRow>();

        loadTransaction();

        if (samTran == null)
            return;

        Datetime fromDate = samTran.CreatedDate.addDays(-14);
        Datetime toDate = samTran.CreatedDate.addDays(1);

        List<Sample_Transaction_vod__c> results = null;
        if (getIsTransfer()) {
            results = [Select Id,Name,Adjusted_Date_vod__c,Lot_Name_vod__c,Lot_vod__r.Name,Quantity_vod__c,Return_To_vod__c,Sample_vod__c,
                            Submitted_Date_vod__c,Transfer_To_vod__c,Transferred_Date_vod__c,CreatedDate
                    From Sample_Transaction_vod__c
                    Where RecordType.Name=:samTran.RecordType.Name And Address_Line_1_vod__c=:samTran.Address_Line_1_vod__c And
                            Address_Line_2_vod__c=:samTran.Address_Line_2_vod__c And City_vod__c=:samTran.City_vod__c And
                            State_vod__c=:samTran.State_vod__c And Zip_vod__c=:samTran.Zip_vod__c And
                            Transfer_To_vod__c=:samTran.Transfer_To_vod__c And Transferred_From_vod__c=:samTran.Transferred_From_vod__c And
                            CreatedDate>:fromDate And CreatedDate<=:toDate Order By CreatedDate desc];
        }
        else if (getIsReturn())  {
            results = [Select Id,Name,Adjusted_Date_vod__c,Lot_Name_vod__c,Lot_vod__r.Name,Quantity_vod__c,Return_To_vod__c,Sample_vod__c,
                            Submitted_Date_vod__c,Transfer_To_vod__c,Transferred_Date_vod__c,CreatedDate
                    From Sample_Transaction_vod__c
                    Where RecordType.Name=:samTran.RecordType.Name And Address_Line_1_vod__c=:samTran.Address_Line_1_vod__c And
                        Address_Line_2_vod__c=:samTran.Address_Line_2_vod__c And City_vod__c=:samTran.City_vod__c And
                        State_vod__c=:samTran.State_vod__c And Zip_vod__c=:samTran.Zip_vod__c And
                        Return_To_vod__c=:samTran.Return_To_vod__c And Adjust_For_vod__c=:samTran.Adjust_For_vod__c And
                            CreatedDate>:fromDate And CreatedDate<=:toDate Order By CreatedDate desc];
        }

        if ((results != null) && (results.size() > 0)) {
            for (Sample_Transaction_vod__c result : results) {
                TransactionRow row = new TransactionRow();
                row.samTran = result;
                if ('No_Lot_vod'.equals(result.Lot_vod__r.Name)) {
                    result.Lot_vod__r.Name = '';
                }
                if (result.Id == samTran.Id)
                    row.selected = true;
                else
                    row.selected = false;
                theTransactions.add(row);
            }
        }
    }

    /* Action associated to clicking Create Package Label button */
    public PageReference create() {
        String idList = '';
        for (TransactionRow trxn : theTransactions) {
            if (trxn.selected) {
                if (idList.length() > 0)
                    idList += ',';
                idList += trxn.samTran.Id;
            }
        }
        if (idList.length() > 0) {
            return new PageReference('/apex/PackageLabel2_vod?ids='+idList);
        }

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select a sample transaction'));

        return null;
    }

    /* Retrieve historical data */
    public List<TransactionRow> getHistory() {
        loadHistory();

        String show = ApexPages.currentPage().getParameters().get('show');
        if (show == 'all')
            return theTransactions;
        else {
            // only show the day's results
            List<TransactionRow> shortList = new List<TransactionRow>();
            for (TransactionRow aTrxn : theTransactions) {
                if (aTrxn.samTran.CreatedDate.isSameDay(samTran.CreatedDate))
                    shortList.add(aTrxn);
            }
            return shortList;
        }
    }

    /* Transfer type? */
    public boolean getIsTransfer() {
        loadTransaction();

        if (samTran == null)
            return false;

        return (samTran.RecordType.Name == 'Transfer_vod');
    }

    /* Return type? */
    public boolean getIsReturn() {
        loadTransaction();

        if (samTran == null)
            return false;

        return (samTran.RecordType.Name == 'Return_vod');
    }

    /* Javascript include */
    public String getInclude() {
        SControl vsession = [Select HtmlWrapper From Scontrol Where Name = 'VSESSION'];

        String vod_server_url = null;
        String vod_version = null;
        String[] lines = vsession.HtmlWrapper.split(';');
        for (Integer i = 0; i < lines.size(); i++) {
            String[] splits = lines[i].split('=');
            String name = '';
            if (splits != null && splits.size() >= 2) {
                Integer index = splits[0].indexOf('var ');
                if (index >= 0) {
                    name = splits[0].substring(index + 4);
                }
            }
            if (name == 'VOD_SERVER_URL')
                vod_server_url = splits[1].replaceAll('"', '');
            else if (name == 'VOD_VERSION') {
                vod_version = splits[1].replaceAll('"', '');
            }
        }

        return vod_server_url + '/' + vod_version + '/js/vodvfcommon.js';
    }

    // Helper class to represent a Sample Transaction row
    public class TransactionRow {
        public boolean selected{get;set;}
        public Sample_Transaction_vod__c samTran{get;set;}
    }

}