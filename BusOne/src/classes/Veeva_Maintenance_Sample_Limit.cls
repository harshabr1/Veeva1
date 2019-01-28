global class Veeva_Maintenance_Sample_Limit implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
/*****************************************************************************************************************************************
Data Recovery Apex Batch to restore Sample_Limit disbursement information
- Apex Batch will check the list of Sample_Limit_vod__c records (where Enforce_Limit_vod__c = true AND Limit_Per_Call_vod__c = false) to find incorrect disbursements
- Using related Call and Call_Sample Information the correct disbursement value will be detected
- DataLodaer CSV file will be prepared for analysis, approval and fixing data
- This tool should be used by Salesforce Administrator only
For testing use Debug/Execute Anonymous Session (max query batch size for SELECT request - 2000 rows, max Apex batch size - 100 rows):
 Id batchJobId = Database.executeBatch(new Veeva_Maintenance_Sample_Limit(), 100);
Version 1.4, 2017-10-23
******************************************************************************************************************************************/
// DON'T CHANGE VALUES IN THIS SECTION - Salesforce limits
    global boolean DebugMode = false;

    global integer APEX_BATCH_SIZE = 100;
    global integer MAX_CSV_SIZE = 2000000;
    global integer Log_Index = 1;
    global integer ToFix_Index = 1;

    global String log_content = '';
    global String csv_tofix = '';
    
    public String StartDate { get; set; }
    public String EndDate { get; set; }
// DON'T CHANGE VALUES IN THIS SECTION - Salesforce limits

    /*** Entry point ***/
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
        SaveToLog('Sample_Limit analysis was started for ' + batch.size() + ' records'); 
        
        // Use the same method to check Disbursement for each Sample_Limit 
        for (sObject oneSL :batch) {
			// Read Sample_Limit information
			ID SL_ID = (ID)oneSL.get('Id');
            String SL_Name = (String)oneSL.get('Name');
            String SL_Group = (String)oneSL.get('Group_Id_vod__c');
            String SL_Start = DateToString((Date)oneSL.get('Start_Date_vod__c'));
            String SL_End = DateToString((Date)oneSL.get('End_Date_vod__c'));
			ID SL_Account = (ID)oneSL.get('Account_vod__c');
			ID SL_Product = (ID)oneSL.get('Product_vod__c');
			ID SL_User = (ID)oneSL.get('User_vod__c');
            Decimal SL_Limit_Quantity = (Decimal)oneSL.get('Limit_Quantity_vod__c');
            Decimal SL_Disbursed_Quantity = (Decimal)oneSL.get('Disbursed_Quantity_vod__c');
            Decimal SL_Remaining_Quantity = (Decimal)oneSL.get('Remaining_Quantity_vod__c');
			SaveToLog('Current SL:' + SL_ID + ' (' + SL_Group +') [' + SL_Limit_Quantity + '/' + SL_Disbursed_Quantity + '/' + SL_Remaining_Quantity + ' between ' + SL_Start + ' and ' + SL_End + ']');

			// Prepare control parameters
			String SL_Fix_Status = '';
            String SL_New_Group = SL_Group;
            Decimal SL_New_Disbursed_Quantity = SL_Disbursed_Quantity;
            String SL_Group_Expected = '';
            if (SL_Account != null) {
                SL_Group_Expected = (String)SL_Account;
                SL_Group_Expected = SL_Group_Expected.substring(0,15);
            }
            SL_Group_Expected += '__' + (String)SL_Product + '__';
            if (SL_User != null) {
                SL_Group_Expected += (String)SL_User;
            }
            SL_Group_Expected += '__';
            Decimal SL_Quantity_Expected = 0;
            
            // Check Group_ID_vod__c value
            if (!StringComparing(SL_Group,SL_Group_Expected)) {
                // Incorrect Group value
                SL_Fix_Status = 'Bad GID';
                SL_New_Group = SL_Group_Expected;
			    SaveToLog('Bad SL:' + SL_ID + ' [Bad GID=' + SL_Group + ' was detected. Expected value=' + SL_New_Group + ']');
            }
            
            // Re-calculate Disbursed_Quantity_vod__c value for Product_Group settings
            String CS1_Request = 'SELECT Sum(Quantity_vod__c) Expected_Disbursed_Quantity_vod__c ';
            CS1_Request += 'FROM Call2_Sample_vod__c ';
            CS1_Request += 'WHERE Limit_Applied_vod__c = true';
            CS1_Request += ' AND Product_vod__c IN (SELECT Product_vod__c FROM Product_Group_vod__c WHERE Product_Catalog_vod__c = \'' + SL_Product + '\')';
            if (SL_Account != null) {
                CS1_Request += ' AND Account_vod__c = \'' + SL_Account + '\'';
            }
            if (SL_User != null) {
                CS1_Request += ' AND Call2_vod__r.OwnerId = \'' + SL_User + '\'';
            }
            CS1_Request += ' AND Call_Date_vod__c >= ' + SL_Start + ' AND Call_Date_vod__c <= ' + SL_End;
            CS1_Request += ' AND Delivery_Status_vod__c != \'Cancel_Request_vod\''; // exclude the cancelled BRC sampling
            AggregateResult[] CS1_Data = Database.query(CS1_Request);
            for (AggregateResult CS1_Result :CS1_Data)
            {
            	Decimal Product_Group_Quantity = (Decimal)CS1_Result.get('Expected_Disbursed_Quantity_vod__c');
                if (Product_Group_Quantity == null) Product_Group_Quantity = 0;
                SL_Quantity_Expected += Product_Group_Quantity;
        	}
            
            // Re-calculate Disbursed_Quantity_vod__c value for Product_Only settings
            String CS2_Request = 'SELECT Sum(Quantity_vod__c) Expected_Disbursed_Quantity_vod__c ';
            CS2_Request += 'FROM Call2_Sample_vod__c ';
            CS2_Request += 'WHERE Limit_Applied_vod__c = true';
            CS2_Request += ' AND Product_vod__c = \'' + SL_Product + '\'';
            if (SL_Account != null) {
                CS2_Request += ' AND Account_vod__c = \'' + SL_Account + '\'';
            }
            if (SL_User != null) {
                CS2_Request += ' AND Call2_vod__r.OwnerId = \'' + SL_User + '\'';
            }
            CS2_Request += ' AND Call_Date_vod__c >= ' + SL_Start + ' AND Call_Date_vod__c <= ' + SL_End;
            CS2_Request += ' AND Delivery_Status_vod__c != \'Cancel_Request_vod\''; // exclude the cancelled BRC sampling
            AggregateResult[] CS2_Data = Database.query(CS2_Request);
            for (AggregateResult CS2_Result :CS2_Data)
            {
            	Decimal Product_Only_Quantity = (Decimal)CS2_Result.get('Expected_Disbursed_Quantity_vod__c');
                if (Product_Only_Quantity == null) Product_Only_Quantity = 0;
                SL_Quantity_Expected += Product_Only_Quantity;
        	}

            // Check Disbursed_Quantity_vod__c value
            if (SL_Disbursed_Quantity != SL_Quantity_Expected) {
                // Incorrect Disburesement
                If (SL_Fix_Status.length() > 0) {
                    SL_Fix_Status += ' and DQ';
                }
                else {
                	SL_Fix_Status = 'Bad DQ';
                }
                SL_New_Disbursed_Quantity = SL_Quantity_Expected;
			    SaveToLog('Bad SL:' + SL_ID + ' [Bad DQ=' + SL_Disbursed_Quantity + ' was detected. Expected value=' + SL_New_Disbursed_Quantity + ']');
            }
            
            // Update ToFix file if it is necessary
            if (SL_Fix_Status.length() > 0) {
            	// Save results to CSV content
                SaveToFix('"' + SL_ID + '","' + SL_Name + '","' + SL_Fix_Status + '","' + SL_Group + '","' + SL_New_Group + '","' + SL_Disbursed_Quantity + '","' + SL_New_Disbursed_Quantity + '"');
            }
        }
        
        SaveToLog('Sample_Limit analysis was completed'); 
    }
    
    /*** Interface components ***/
    global void execute(SchedulableContext SC) {
        Database.Batchable<SObject> B = new Veeva_Maintenance_Sample_Limit();
        Database.executeBatch(B, APEX_BATCH_SIZE);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Check Data Scope properties - by default, we will check only records, modified in the current month
        Datetime RunDate = System.now();
        if (StartDate == null) StartDate = RunDate.format('yyyy-MM') + '-01T00:00:00.000Z';
        if (EndDate == null) EndDate = RunDate.format('yyyy-MM-dd') + 'T00:00:00.000Z';
        
        // Check current User Profile = we only support "System Administrator"
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:UserInfo.getProfileId() LIMIT 1];
        
        // Initialize content for result files (CSV output)
        log_content += '"' + System.now().format('yyyy-MM-dd HH:mm:ss') + '","VEEVA_MAINTENANCE","Log initialization for ' + UserInfo.getUserName() + ' (' + PROFILE[0].Name + ') with Data Scope from ' + StartDate + ' to ' + EndDate + '"\r\n';
        csv_tofix += '"Sample_Limit_vod__c","Name","Type_Of_Issue","OLD_Group_ID_value","NEW_Group_ID_value","OLD_Disbursed_Quantity","NEW_Disbursed_Quantity"\r\n';

        // This is the query to get the list of Sample_Limits to analyze. We will execute this batch if at least one the Sample_Limit exists.
        String sl_soql = 'SELECT';
        sl_soql += ' Id,';
        sl_soql += ' Name,';
        sl_soql += ' Group_Id_vod__c,';
        sl_soql += ' Start_Date_vod__c,';
        sl_soql += ' End_Date_vod__c,';
        sl_soql += ' Account_vod__c,';
        sl_soql += ' Product_vod__c,';
        sl_soql += ' User_vod__c,';
        sl_soql += ' Limit_Quantity_vod__c,';
        sl_soql += ' Disbursed_Quantity_vod__c,';
        sl_soql += ' Remaining_Quantity_vod__c ';
        sl_soql += 'FROM Sample_Limit_vod__c ';
        sl_soql += 'WHERE Enforce_Limit_vod__c = true AND Limit_Per_Call_vod__c = false';
        sl_soql += ' AND LastModifiedDate >= ' + StartDate + ' AND LastModifiedDate < ' + EndDate;
		sl_soql += ' AND Account_Types_vod__c = null AND Product_vod__c != null';
        
        // Last check for User Profile = don't run that for non-admin users
        if (PROFILE[0].Name != 'System Administrator') sl_soql = 'SELECT Id, Name FROM User WHERE IsActive=true AND IsActive=false';
        return Database.getQueryLocator(sl_soql);
    }

    global void finish(Database.BatchableContext BC) {
        // Batch Finalizing - save result files
        log_content += '"' + System.now().format('yyyy-MM-dd HH:mm:ss') + '","VEEVA_MAINTENANCE","Results were saved in CSV files (DebugMode=' + DebugMode + ')"\r\n';
        FileToLog();
        FileToFix();
    }    
    
    private Boolean StringComparing(String S1, String S2) {
        if (S1 != null && S1.length() > 0 && S2 != null && S2.length() > 0) {
            if (S2.equals(S1)) {
                return true;
            } else {
                return false;
            }
        } else if ((S1 == null || S1.length() == 0) && (S2 == null || S2.length() == 0)) {
            return true;
        } else {
            return false;
        }
    }
    
    private void SaveToLog(String R) {
        if (DebugMode) {
            String LogMessage = '"VEEVA_MAINTENANCE","' + R + '"';
            System.Debug(LogMessage);
            // Check SFDC limitations
            String new_csv_content = '"' + System.now().format('yyyy-MM-dd HH:mm:ss') + '",' + LogMessage + '\r\n';
            if ((log_content.length() + new_csv_content.length()) > MAX_CSV_SIZE) {
                // Split file
                FileToLog();
                Log_Index += 1;
                log_content = new_csv_content;
            } else {
                // Keep going
                log_content += new_csv_content;
            }
        }
    }
    
    private void FileToLog() {
        String fn = 'VM_Sample_Limit_Log_' + getFileIndex(Log_Index) + '_' + System.now().format('yyyyMMddHHmmss') + '.csv';
        ContentVersion log_file = new ContentVersion(
            title = fn,
            VersionData = Blob.valueOf(log_content),
            PathOnClient = '/' + fn
        );
        insert log_file;
    }
    
    private void SaveToFix(String d) {
        // Check SFDC limitations
        String new_csv_content = d + '\r\n';
        if ((csv_tofix.length() + new_csv_content.length()) > MAX_CSV_SIZE) {
            // Split file
            FileToFix();
            ToFix_Index += 1;
            csv_tofix = new_csv_content;
        } else {
            // Keep going
            csv_tofix += new_csv_content;
        }
    }
    
    private void FileToFix() {
        String fn = 'VM_Sample_Limit_ToFix_' + getFileIndex(ToFix_Index) + '_' + System.now().format('yyyyMMddHHmmss') + '.csv';
        ContentVersion csv_tofix_file = new ContentVersion(
            title = fn,
            VersionData = Blob.valueOf(csv_tofix),
            PathOnClient = '/' + fn
        );
        insert csv_tofix_file;
    }
    
    private String getFileIndex(Integer i) {
        String is = '00000';
        if (i <= 0) {
            is = '00000';
        } else if (i < 10) {
            is = '0000' + i.format();
        } else if (i < 100) {
            is = '000' + i.format();
        } else if (i < 1000) {
            is = '00' + i.format();
        } else if (i < 10000) {
            is = '0' + i.format();
        } else {
            is = i.format();
        }
        return is;
    }
    
    private String DatetimeToString(Datetime cdt) {
        String cds = '';
        if (cdt != null) {
            cds = cdt.format('yyyy-MM-dd HH:mm:ss');
        }
        return cds;
    }

    private String DateToString(Date cd) {
        String cs = '';
        cs += cd.year() + '-';
        if (cd.month() < 10) {
            cs += '0';
        }
        cs += cd.month() + '-';
        if (cd.day() < 10) {
            cs += '0';
        }
        cs += cd.day();
        return cs;
    }
}