global class Veeva_Maintenance_Call_Address implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
/*****************************************************************************************************************************************
Data Recovery Apex Batch to restore Parent_Address_vod__c, Ship_To_Address_vod__c and DEA_Address_vod__c values for Call2_vod__c records
- Apex Batch will detect the list of Call2_vod__c records, where Parent_Address information was not populated
- Using related Accounts Information and Address text fields the correct Address Identificator will be detected
- Ship_To_Address_vod__c and DEA_Address_vod__c will be restored if Parent_Address_vod__c value was found
- Any current licence-, ship- and dea- components fo Addresses will be ignored here because we believe that all of them were OK once Address fields were populated there
- DataLodaer CSV file will be prepared for analysis, approval and fixing data
- This tool should be used by Salesforce Administrator only
For testing use Debug/Execute Anonymous Session (max query batch size for SELECT request - 2000 rows, max Apex batch size - 200 rows):
 Id batchJobId = Database.executeBatch(new Veeva_Maintenance_Call_Address(), 200);
Version 1.4, 2017-10-23 (extended CSV file output)
******************************************************************************************************************************************/
// DON'T CHANGE VALUES IN THIS SECTION - Salesforce limits
    global boolean DebugMode = false;

    integer APEX_BATCH_SIZE = 200;
    boolean Ship_Location_Used = true;

    global String log_content = '';
    global String csv_tofix = '';
    global String csv_notfound = '';

    global integer MAX_CSV_SIZE = 2000000;
    global integer Log_Index = 1;
    global integer ToFix_Index = 1;
    global integer NotFound_Index = 1;
    
    public String StartDate { get; set; }
    public String EndDate { get; set; }
// DON'T CHANGE VALUES IN THIS SECTION - Salesforce limits
    
    /*** Entry point ***/
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
        SaveToLog('Call Address analysis was started'); 
        
        // Prepare the set of Unique AccountIds from Call information
        Set<ID> AccountIds = new Set<ID>();
        for (sObject oneCall :batch) {
            // Call Account
            ID oneAccount = (ID)oneCall.get('Account_vod__c');
            if (oneAccount != null) AccountIds.add(oneAccount);

            // Parent Call Account
            sObject PCAccount = (sObject)oneCall.getSobject('Parent_Call_vod__r');
            if (PCAccount != null) {
                ID onePCAccount = (ID)oneCall.getSobject('Parent_Call_vod__r').get('Account_vod__c');
                if (onePCAccount != null) AccountIds.add(onePCAccount);
            }

            // Ship Location Account
            if (Ship_Location_Used) {
                ID oneSAccount = (ID)oneCall.get('Ship_To_Location_vod__c');
                if (oneSAccount != null) AccountIds.add(oneSAccount);
            }
        }
        SaveToLog('Number of Accounts = ' +  AccountIds.size() + ' for ' + batch.size() + ' Broken Calls'); 
        
        // Create Addresses Map for the extracted AccountIds (including deleted rows)
        Map<ID, Address_vod__c> AddressMap = new Map<ID, Address_vod__c>([SELECT Id, Primary_vod__c, IsDeleted, Inactive_vod__c, Account_vod__c, Account_vod__r.IsPersonAccount, Name, Address_Line_2_vod__c, City_vod__c, State_vod__c, Zip_vod__c FROM Address_vod__c WHERE Account_vod__c IN :AccountIds ALL ROWS]);
        if (AddressMap.size() > 0) {
            // Start Address detection for each broken Call
            SaveToLog('Number of available Addresses = ' + AddressMap.size()); 
            Set<ID> Address_Set = AddressMap.keySet();
            for (sObject oneCall :batch) {
                // Read Account information from the Call
                ID theCall = (ID)oneCall.get('Id');
                Boolean IsParentCall = false;
                ID ParentCallId = (ID)oneCall.get('Parent_Call_vod__c');
                if (ParentCallId == null) IsParentCall = true;
                ID AccountId = (ID)oneCall.get('Account_vod__c');
                String AccountType = (String)oneCall.get('Attendee_Type_vod__c');
                // Read Parent_Address Information
                String Parent_Address = (String)oneCall.get('Parent_Address_vod__c');
                String Address_Line_1 = (String)oneCall.get('Address_Line_1_vod__c');
                String Address_Line_2 = (String)oneCall.get('Address_Line_2_vod__c');
                String City_vod = (String)oneCall.get('City_vod__c');
                String State_vod = (String)oneCall.get('State_vod__c');
                String Zip_vod = (String)oneCall.get('Zip_vod__c');
                // Read Ship_Address Information
                ID ShipAccountId = null;
                if (Ship_Location_Used) ShipAccountId = (ID)oneCall.get('Ship_To_Location_vod__c');
                String Ship_Address = (String)oneCall.get('Ship_To_Address_vod__c');
                String Ship_Address_Line_1 = (String)oneCall.get('Ship_Address_Line_1_vod__c');
                String Ship_Address_Line_2 = (String)oneCall.get('Ship_Address_Line_2_vod__c');
                String Ship_City_vod = (String)oneCall.get('Ship_City_vod__c');
                String Ship_State_vod = (String)oneCall.get('Ship_State_vod__c');
                String Ship_Zip_vod = (String)oneCall.get('Ship_Zip_vod__c');
                // Read DEA_Address Information
                String DEA_Address = (String)oneCall.get('DEA_Address_vod__c');
                String DEA_Address_Line_1 = (String)oneCall.get('DEA_Address_Line_1_vod__c');
                String DEA_Address_Line_2 = (String)oneCall.get('DEA_Address_Line_2_vod__c');
                String DEA_City_vod = (String)oneCall.get('DEA_City_vod__c');
                String DEA_State_vod = (String)oneCall.get('DEA_State_vod__c');
                String DEA_Zip_vod = (String)oneCall.get('DEA_Zip_vod__c');
                // Get parent Call information
                ID ParentAccountId = null;
                sObject ParentCall = (sObject)oneCall.getSobject('Parent_Call_vod__r');
                if (ParentCall != null) ParentAccountId = (ID)oneCall.getSobject('Parent_Call_vod__r').get('Account_vod__c');
                // Get additional info from the Call for CSV output
                String Call_Name = (String)oneCall.get('Name');
                String Call_Type = (String)oneCall.get('Call_Type_vod__c');
                String Call_Datetime = DatetimeToString((Datetime)oneCall.get('Call_Datetime_vod__c'));
        		String Call_Status = (String)oneCall.get('Status_vod__c');
        		String Call_LastDevice = (String)oneCall.get('Last_Device_vod__c');
	       		String Call_Created = DatetimeToString((Datetime)oneCall.get('CreatedDate'));
        		String Call_Modified = DatetimeToString((Datetime)oneCall.get('LastModifiedDate'));
        		String Call_MCreated = DatetimeToString((Datetime)oneCall.get('Mobile_Created_Datetime_vod__c'));
        		String Call_MModified = DatetimeToString((Datetime)oneCall.get('Mobile_Last_Modified_Datetime_vod__c'));
        		String Call_Signature = DatetimeToString((Datetime)oneCall.get('Signature_Date_vod__c'));

                // Try to find Parent_Address in AddressMap
                Boolean Address_Found = false;
                String Address_Status = 'Not Found';
                for (ID oneAddress :Address_Set) {
                    // Compare Address Information
                    Address_Found = StringComparing(Address_Line_1,AddressMap.get(oneAddress).Name);
                    Address_Found &= StringComparing(Address_Line_2,AddressMap.get(oneAddress).Address_Line_2_vod__c);
                    Address_Found &= StringComparing(City_vod,AddressMap.get(oneAddress).City_vod__c);
                    Address_Found &= StringComparing(State_vod,AddressMap.get(oneAddress).State_vod__c);
                    Address_Found &= StringComparing(Zip_vod,AddressMap.get(oneAddress).Zip_vod__c);
                    if (Address_Found && AccountId != null) {
                        // Let's check if this is the proper Address
                        if (IsParentCall) {
                            // Parent Call = take Primary Address from Call Account
                            if (AccountId.equals(AddressMap.get(oneAddress).Account_vod__c)) {
                                // Support multi-addresses case
                                if (Parent_Address == null) {
                                    // Just save because it is the first time
                                    Parent_Address = oneAddress;
                                    SaveToLog('Parent Call=' +  theCall + ', Possible Address (' + Parent_Address + ') was detected');
                                } else { // if (!AddressMap.get(Parent_Address).Primary_vod__c) {
                                    // Can be replaced because it was not Primary Address yet
                                    Parent_Address = oneAddress;
                                    SaveToLog('Parent Call=' +  theCall + ', Possible Address (' + Parent_Address + ') was replaced');
                                    // we will inform about multi-addresses case 
                                    Address_Status = 'Multi';
                                }
                            }
                        } else if (ParentAccountId != null) {
                            // Child Call = take Primary Address from Parent Call Account
                            if (ParentAccountId.equals(AddressMap.get(oneAddress).Account_vod__c)) {
                                // Support multi-addresses case
                                if (Parent_Address == null) {
                                    // Just save because it is the first time
                                    Parent_Address = oneAddress;
                                    SaveToLog('Child Call=' +  theCall + ', Possible Address (' + Parent_Address + ') was detected');
                                } else { // if (!AddressMap.get(Parent_Address).Primary_vod__c) {
                                    // Can be replaced because it was not Primary Address yet
                                    Parent_Address = oneAddress;
                                    SaveToLog('Child Call=' +  theCall + ', Possible Address (' + Parent_Address + ') was replaced');
                                    // we will inform about multi-addresses case 
                                    Address_Status = 'Multi';
                                }
                            }
                        }
                    }
                }
                // Define Parent_Address status
                if (Parent_Address != null) {
                    if (Address_Status == 'Multi') {
                        // Multi-addresses case = clean Parent_Address value and let the Customer decide what to do
                        Parent_Address = '';
                    } else if (AddressMap.get(Parent_Address).IsDeleted) {
                        Address_Status = 'Deleted';
                    } else if (AddressMap.get(Parent_Address).Inactive_vod__c) {
                        Address_Status = 'Inactive';
                    } else {
                        Address_Status = 'Active';
                    }
                    SaveToLog('Result: Call=' +  theCall + ', Detected Parent_Address = ' + Parent_Address + ', Address Status = ' + Address_Status);

                    // Now try to find Ship_Address in AddressMap
                    Boolean Ship_Found = false;
                    String Ship_Status = 'Not Found';
                    if (Ship_Address != null && Ship_Address.length() > 0) {
                        // Ship_Address already exists = Detection is not necessary
                        Ship_Status = 'Current';
                        SaveToLog('Result: Call=' +  theCall + ', Ship_Address exists');
                    } else if (Ship_Address_Line_1 == null || Ship_Address_Line_1.length() == 0) {
                        // Ship_Address is not used = Detection is not necessary
                        Ship_Status = 'Not Used';
                        Ship_Address = '';
                        SaveToLog('Result: Call=' +  theCall + ', Ship_Address is not used');
                    } else {
                        // Detection is necessary
                        for (ID oneAddress :Address_Set) {
                            // Compare Address Information
                            Ship_Found = StringComparing(Ship_Address_Line_1,AddressMap.get(oneAddress).Name);
                            Ship_Found &= StringComparing(Ship_Address_Line_2,AddressMap.get(oneAddress).Address_Line_2_vod__c);
                            Ship_Found &= StringComparing(Ship_City_vod,AddressMap.get(oneAddress).City_vod__c);
                            Ship_Found &= StringComparing(Ship_State_vod,AddressMap.get(oneAddress).State_vod__c);
                            Ship_Found &= StringComparing(Ship_Zip_vod,AddressMap.get(oneAddress).Zip_vod__c);
                            if (Ship_Found) {
                                // Let's check if this is the proper Address
                                if (ShipAccountId != null) {
                                    // Ship_To_Location is populated = take Ship Address from that
                                    if (ShipAccountId.equals(AddressMap.get(oneAddress).Account_vod__c)) {
                                        // Support multi-addresses case
                                        if (Ship_Address == null) {
                                            // Just save because it is the first time
                                            Ship_Address = oneAddress;
                                            SaveToLog('Ship Call=' +  theCall + ', Possible Address from Ship_To_Location (' + Ship_Address + ') was detected');
                                        } else { // if (!AddressMap.get(Ship_Address).Primary_vod__c) {
                                            // Can be replaced because it was not Primary Address yet
                                            Ship_Address = oneAddress;
                                            SaveToLog('Ship Call=' +  theCall + ', Possible Address from Ship_To_Location (' + Ship_Address + ') was replaced');
                                            // we will inform about multi-addresses case 
                                            Ship_Status = 'Multi';
                                        }
                                    }
                                } else {
                                    // Ship_To_Location is NOT populated = take Primary Address from Call Account
                                    if (AccountId.equals(AddressMap.get(oneAddress).Account_vod__c)) {
                                        // Support multi-addresses case
                                        if (Ship_Address == null) {
                                            // Just save because it is the first time
                                            Ship_Address = oneAddress;
                                            SaveToLog('Ship Call=' +  theCall + ', Possible Address from Account (' + Ship_Address + ') was detected');
                                        } else { // if (!AddressMap.get(Ship_Address).Primary_vod__c) {
                                            // Can be replaced because it was not Primary Address yet
                                            Ship_Address = oneAddress;
                                            SaveToLog('Ship Call=' +  theCall + ', Possible Address from Account (' + Ship_Address + ') was replaced');
                                            // we will inform about multi-addresses case 
                                            Ship_Status = 'Multi';
                                        }
                                    }
                                }
                            }
                        }
                        if (Ship_Address != null) {
                            // Check status
                            if (Ship_Status == 'Multi') {
                                // Multi-addresses case = clean Ship_Address value and let the Customer decide what to do
                                Ship_Address = '';
                            } else if (AddressMap.get(Ship_Address).IsDeleted) {
                                Ship_Status = 'Deleted';
                            } else if (AddressMap.get(Ship_Address).Inactive_vod__c) {
                                Ship_Status = 'Inactive';
                            } else {
                                Ship_Status = 'Active';
                            }
                            SaveToLog('Result: Call=' +  theCall + ', Detected Ship_Address = ' + Ship_Address + ', Address Status = ' + Ship_Status);
                        } else {
                            SaveToLog('Result: Call=' +  theCall + ', Ship_Address was not detected');
                            // Convert "null" to empty for CSV
                            Ship_Address = '';
                        }
                    }
                    
                    // Now try to find DEA_Address in AddressMap
                    Boolean DEA_Found = false;
                    String DEA_Status = 'Not Found';
                    if (DEA_Address != null && DEA_Address.length() > 0) {
                        // DEA_Address already exists = Detection is not necessary
                        DEA_Status = 'Current';
                        SaveToLog('Result: Call=' +  theCall + ', DEA_Address exists');
                    } else if (DEA_Address_Line_1 == null || DEA_Address_Line_1.length() == 0) {
                        // DEA_Address is not used = Detection is not necessary
                        DEA_Status = 'Not Used';
                        DEA_Address = '';
                        SaveToLog('Result: Call=' +  theCall + ', DEA_Address is not used');
                    } else {
                        // Detection is necessary
                        for (ID oneAddress :Address_Set) {
                            // Compare Address Information
                            DEA_Found = StringComparing(DEA_Address_Line_1,AddressMap.get(oneAddress).Name);
                            DEA_Found &= StringComparing(DEA_Address_Line_2,AddressMap.get(oneAddress).Address_Line_2_vod__c);
                            DEA_Found &= StringComparing(DEA_City_vod,AddressMap.get(oneAddress).City_vod__c);
                            DEA_Found &= StringComparing(DEA_State_vod,AddressMap.get(oneAddress).State_vod__c);
                            DEA_Found &= StringComparing(DEA_Zip_vod,AddressMap.get(oneAddress).Zip_vod__c);
                            if (DEA_Found && AccountId != null) {
                                    // Ship_To_Location + Controlled BRC without any other Controlled_Substancies = take Address from Call Account for that
                                    // Child Call with UGA = take Address from Call Account for that
                                    // Just Person Call = take Address from Call Account for that
                                    // Group Call = take Address from Call Account for that
                                    if (AccountId.equals(AddressMap.get(oneAddress).Account_vod__c)) {
                                        // Support multi-addresses case
                                        if (DEA_Address == null) {
                                            // Just save because it is the first time
                                            DEA_Address = oneAddress;
                                            SaveToLog('DEA Call=' +  theCall + ', Possible Address for BRC case from Call Account (' + DEA_Address + ') was detected');
                                        } else { // if (!AddressMap.get(Ship_Address).Primary_vod__c) {
                                            // Can be replaced because it was not Primary Address yet
                                            DEA_Address = oneAddress;
                                            SaveToLog('DEA Call=' +  theCall + ', Possible Address for BRC case from Call Account (' + DEA_Address + ') was replaced');
                                            // we will inform about multi-addresses case 
                                            DEA_Status = 'Multi';
                                        }
                                    }
                            }
                        }
                        if (DEA_Address != null) {
                            // Check status
                            if (DEA_Address.length() == 0) {
                                // Unfortunately, Address was not found because of Ship_To_Address was empty
                                DEA_Status = 'Not Found';
                            } else if (DEA_Status == 'Multi') {
                                // Multi-addresses case = clean DEA_Address value and let the Customer decide what to do
                                DEA_Address = '';
                            } else if (AddressMap.get(DEA_Address).IsDeleted) {
                                DEA_Status = 'Deleted';
                            } else if (AddressMap.get(DEA_Address).Inactive_vod__c) {
                                DEA_Status = 'Inactive';
                            } else {
                                DEA_Status = 'Active';
                            }
                            SaveToLog('Result: Call=' +  theCall + ', Detected DEA_Address = ' + DEA_Address + ', Address Status = ' + DEA_Status);
                        } else {
                            SaveToLog('Result: Call=' +  theCall + ', DEA_Address was not detected');
                            // Convert "null" to empty for CSV
                            DEA_Address = '';
                        }
                    }
                    
                    // Save results to CSV content
                    String csv_output = '"' + AccountId + '",';
                    csv_output += '"' + AccountType + '",';
                    csv_output += '"' + Call_Name + '",';
                    csv_output += '"' + Call_Type + '",';
                    csv_output += '"' + ParentCallId + '",';
                    csv_output += '"' + Call_Datetime + '",';
                    csv_output += '"' + Call_Status + '",';
                    csv_output += '"' + Call_LastDevice + '",';
                    csv_output += '"' + Call_Created + '",';
                    csv_output += '"' + Call_Modified + '",';
                    csv_output += '"' + Call_MCreated + '",';
                    csv_output += '"' + Call_MModified + '",';
                    csv_output += '"' + Call_Signature + '",';
                    SaveToFix('"' + theCall + '",' + csv_output + '"' + Parent_Address + '","' + Address_Status + '","' + Ship_Address + '","' + Ship_Status + '","' + DEA_Address + '","' + DEA_Status + '"');
                } else {
                    // Address was not found - stop processing for this Call
                    SaveToLog('Result: Call=' +  theCall + ', Parent_Address was not detected');
                    SaveNotFound('"' + theCall + '","' + IsParentCall + '","' + AccountId + '","' + Address_Line_1 + '"');
                }
            }
        } else {
            SaveToLog('INFO - No one of Addresses, related with the requested Accounts, were found!'); 
        }
        SaveToLog('Call Address analysis was completed'); 
    }
    
    /*** Interface components ***/
    global void execute(SchedulableContext SC) {
        Database.Batchable<SObject> B = new Veeva_Maintenance_Call_Address();
        Database.executeBatch(B, APEX_BATCH_SIZE);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Check Data Scope properties
        if (StartDate == null) StartDate = '2017-08-01T00:00:00.000Z';
        if (EndDate == null) EndDate = '2100-12-31T00:00:00.000Z';
        
        // Check current User Profile = we only support "System Administrator"
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:UserInfo.getProfileId() LIMIT 1];
        
        // Initialize content for result files (CSV output)
        log_content += '"' + System.now().format('yyyy-MM-dd HH:mm:ss') + '","VEEVA_MAINTENANCE","Log initialization for ' + UserInfo.getUserName() + ' (' + PROFILE[0].Name + ') with Data Scope from ' + StartDate + ' to ' + EndDate + '"\r\n';
        csv_tofix += '"Call2_vod__c","Account_vod__c","Attendee_Type_vod__c","Name","Call_Type_vod__c","Parent_Call_vod__c","Call_Datetime_vod__c","Status_vod__c","Last_Device_vod__c","CreatedDate","LastModifiedDate","Mobile_Created_Datetime_vod__c","Mobile_Last_Modified_Datetime_vod__c","Signature_Date_vod__c","NEW_Parent_Address","Parent_Address_Status","NEW_Ship_To_Address","Ship_Address_Status","NEW_DEA_Address","DEA_Address_Status","Override_Lock_vod__c"\r\n';
        csv_notfound += '"Call2_vod__c","Is_Parent_Call_vod__c","Account_vod__c","Address_Line_1_vod__c"\r\n';

        // This is the query to get the list of broken Calls. We will execute this batch if at least one the Broken Call exists.
        String calls_soql = 'SELECT';
        calls_soql += ' Id,';
        calls_soql += ' Call_Type_vod__c,';
        calls_soql += ' Is_Parent_Call_vod__c,';
        calls_soql += ' Parent_Call_vod__c,';
        calls_soql += ' Attendee_Type_vod__c,';
        calls_soql += ' Account_vod__c,';
        if (Ship_Location_Used) calls_soql += ' Ship_To_Location_vod__c,';
        calls_soql += ' Parent_Call_vod__r.Account_vod__c,';
        // Request additional info from the Call for CSV output
        calls_soql += ' Name,';
        calls_soql += ' Call_Datetime_vod__c,';
        calls_soql += ' Status_vod__c,';
        calls_soql += ' Last_Device_vod__c,';
        calls_soql += ' CreatedDate,';
        calls_soql += ' LastModifiedDate,';
        calls_soql += ' Mobile_Created_Datetime_vod__c,';
        calls_soql += ' Mobile_Last_Modified_Datetime_vod__c,';
        calls_soql += ' Signature_Date_vod__c,';
        // Request Address information
        calls_soql += ' Parent_Address_vod__c,';
        calls_soql += ' Address_Line_1_vod__c,';
        calls_soql += ' Address_Line_2_vod__c,';
        calls_soql += ' City_vod__c,';
        calls_soql += ' State_vod__c,';
        calls_soql += ' Zip_vod__c,';
        calls_soql += ' Ship_To_Address_vod__c,';
        calls_soql += ' Ship_Address_Line_1_vod__c,';
        calls_soql += ' Ship_Address_Line_2_vod__c,';
        calls_soql += ' Ship_City_vod__c,';
        calls_soql += ' Ship_State_vod__c,';
        calls_soql += ' Ship_Zip_vod__c,';
        calls_soql += ' DEA_Address_vod__c,';
        calls_soql += ' DEA_Address_Line_1_vod__c,';
        calls_soql += ' DEA_Address_Line_2_vod__c,';
        calls_soql += ' DEA_City_vod__c,';
        calls_soql += ' DEA_State_vod__c,';
        calls_soql += ' DEA_Zip_vod__c ';
        calls_soql += 'FROM Call2_vod__c ';
        calls_soql += 'WHERE LastModifiedDate >= ' + StartDate + ' AND LastModifiedDate < ' + EndDate;
        calls_soql += '  AND Parent_Address_vod__c = null';
        calls_soql += '  AND Address_Line_1_vod__c != null';
        
        // Last check for User Profile = don't run that for non-admin users
        if (PROFILE[0].Name != 'System Administrator') calls_soql = 'SELECT Id, Name FROM User WHERE IsActive=true AND IsActive=false';
        return Database.getQueryLocator(calls_soql);
    }

    global void finish(Database.BatchableContext BC) {
        // Batch Finalizing - save result files
        log_content += '"' + System.now().format('yyyy-MM-dd HH:mm:ss') + '","VEEVA_MAINTENANCE","Results were saved in CSV files (DebugMode=' + DebugMode + ')"\r\n';
        FileToLog();
        FileToFix();
        FileNotFound();
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
        String fn = 'VM_Call_Address_Log_' + getFileIndex(Log_Index) + '_' + System.now().format('yyyyMMddHHmmss') + '.csv';
        ContentVersion log_file = new ContentVersion(
            title = fn,
            VersionData = Blob.valueOf(log_content),
            PathOnClient = '/' + fn
        );
        insert log_file;
    }
    
    private void SaveToFix(String d) {
        // Check SFDC limitations
        String new_csv_content = d + ',"true"\r\n';
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
        String fn = 'VM_Call_Address_ToFix_' + getFileIndex(ToFix_Index) + '_' + System.now().format('yyyyMMddHHmmss') + '.csv';
        ContentVersion csv_tofix_file = new ContentVersion(
            title = fn,
            VersionData = Blob.valueOf(csv_tofix),
            PathOnClient = '/' + fn
        );
        insert csv_tofix_file;
    }
    
    private void SaveNotFound(String d) {
        // Check SFDC limitations
        String new_csv_content = d + '\r\n';
        if ((csv_notfound.length() + new_csv_content.length()) > MAX_CSV_SIZE) {
            // Split file
            FileNotFound();
            NotFound_Index += 1;
            csv_notfound = new_csv_content;
        } else {
            // Keep going
            csv_notfound += new_csv_content;
        }
    }
    
    private void FileNotFound() {
        String fn = 'VM_Call_Address_NotFound_' + getFileIndex(NotFound_Index) + '_' + System.now().format('yyyyMMddHHmmss') + '.csv';
        ContentVersion csv_notfound_file = new ContentVersion(
            title = fn,
            VersionData = Blob.valueOf(csv_notfound),
            PathOnClient = '/' + fn
        );
        insert csv_notfound_file;
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
}