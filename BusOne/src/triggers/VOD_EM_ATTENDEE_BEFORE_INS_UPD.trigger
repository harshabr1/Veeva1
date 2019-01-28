trigger VOD_EM_ATTENDEE_BEFORE_INS_UPD on EM_Attendee_vod__c (before insert , before update) {           
    Set<ID> contactIds = new Set<ID>();
    Set<ID> userIds = new Set<ID>();
    Set<ID> accountIds = new Set<ID>();
    for(EM_Attendee_vod__c attendee: Trigger.new) {
        contactIds.add(attendee.Contact_vod__c);
        userIds.add(attendee.User_vod__c);
        if (attendee.Entity_Reference_Id_vod__c != null) {
            attendee.Account_vod__c = attendee.Entity_Reference_Id_vod__c;
            attendee.Entity_Reference_Id_vod__c = null;
        }
        accountIds.add(attendee.Account_vod__c);
    }
    
    Map<String, List<String>> emailMap = new Map<String, List<String>>();		          
    String[] types = new String[]{'Account','Address_vod__c', 'User'};
    Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
    for(Schema.DescribeSobjectResult res : results) {
        List<String> emailFields = new List<String>();
        SObjectType currType = res.getSObjectType();
        Map<String,Schema.SObjectField> mfields = currType.getDescribe().fields.getMap();
        for(Schema.SObjectField field: mfields.values()) {
            if(field.getDescribe().getType().equals(Schema.DisplayType.EMAIL)) {
                emailFields.add(field.getDescribe().getName());
            }
        }
        emailMap.put(res.getName(), emailFields);
    }
    
    Map<Id, Contact> contacts = new Map<Id, Contact>([Select Id, FirstName, LastName, Name FROM Contact WHERE Id in :contactIds]);
    Map<Id, User> users = new Map<Id, User>([Select Id, FirstName, LastName, Name FROM User WHERE Id in :userIds]);
    Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Formatted_Name_vod__c, FirstName, LastName, PersonTitle, Credentials_vod__c, Name, Furigana_vod__c FROM Account WHERE Id in :accountIds]);

    Events_Management_Settings_vod__c emSetting = [SELECT Attendee_Automatch_Mode_vod__c FROM Events_Management_Settings_vod__c];
    Integer autoMatchMode = 1;

    if(emSetting.Attendee_Automatch_Mode_vod__c != null) {
        autoMatchMode = emSetting.Attendee_Automatch_Mode_vod__c.intValue();
    }

    for (EM_Attendee_vod__c emAtt : Trigger.new) {
        String lastName = '';
        String firstName = '';
        if(Trigger.isInsert && autoMatchMode == 1 && (emAtt.Walk_In_Status_vod__c == 'Needs_Reconciliation_vod' || emAtt.Online_Registration_Status_vod__c == 'Needs_Reconciliation_vod')) {
            //Find Matching Accounts
            List<sObject> matchAccounts = new List<sObject>();
            List<String> accountEmails = emailMap.get('Account');
            List<String> addressEmails = emailMap.get('Address_vod__c');
            String accountQuery = 'SELECT Id, LastName, FirstName';
            boolean hasAccountEmail = false;
            boolean hasAccountName = false;
            boolean hasAddressEmail = false;
            String attendeeLastName = emAtt.Last_Name_vod__c;
            String accountClause = '';
            if(attendeeLastName != null) {
                if(attendeeLastName.length() <= 2) {
                    accountClause += ' LastName = \'' + String.escapeSingleQuotes(attendeeLastName) + '\' AND (';
                } else {
                    accountClause += ' LastName Like \'' + String.escapeSingleQuotes(attendeeLastName.subString(0,3)) + '%\' AND (';
                }
            } else {
                continue;
            }

            if(!accountEmails.isEmpty()) {
                if(emAtt.Email_vod__c != null) {
                	hasAccountEmail = true;
                }
                for(Integer i = 0; i < accountEmails.size(); i++) {
                    String fieldName = accountEmails.get(i);
                    accountQuery += ',' + fieldName;
                    if(hasAccountEmail) {
                    	accountClause += '(' + fieldName + '=\'' + emAtt.Email_vod__c + '\')';
                        if(i+1 != accountEmails.size()) {
                            accountClause += ' OR ';
                        }
                    }
                }
            }

            accountQuery += ' FROM Account WHERE ' + accountClause;

            if(emAtt.First_Name_vod__c != null && emAtt.Last_Name_vod__c != null) {
                if(hasAccountEmail) {
                	accountQuery += ' OR ';
                }
                hasAccountName = true;
            	accountQuery += '(FirstName = \'' + String.escapeSingleQuotes(emAtt.First_Name_vod__c) + '\' AND LastName = \'' + String.escapeSingleQuotes(emAtt.Last_Name_vod__c) + '\')';
            }

            if(!addressEmails.isEmpty()) {
                List<sObject> matchAddresses = new List<sObject>();
                String addressQuery = 'SELECT Account_vod__c FROM Address_vod__c WHERE';
                if(attendeeLastName.length() <= 2) {
                    addressQuery += ' Account_vod__c IN (SELECT Id From Account WHERE LastName = \'' + String.escapeSingleQuotes(attendeeLastName) + '\') AND (';
                } else {
                    addressQuery += ' Account_vod__c IN (SELECT Id From Account WHERE LastName LIKE \'' + String.escapeSingleQuotes(attendeeLastName.subString(0,3)) + '%\') AND (';
                }

                for(Integer i = 0; i < addressEmails.size(); i++) {
                    addressQuery += ' (' + addressEmails.get(i) + '=\'' + emAtt.Email_vod__c + '\')';
                    if(i+1 != addressEmails.size()) {
                        addressQuery += ' OR ';
                    }
                }
				addressQuery += ')';
                matchAddresses = Database.query(addressQuery);
                if(!matchAddresses.isEmpty()) {
                    hasAddressEmail = true;
                    String addressIds = '(';
                    for(Integer i = 0; i < matchAddresses.size(); i++) {
                        SObject match = matchAddresses.get(i);
                        addressIds += '\'' + match.get('Account_vod__c') + '\'';
                        if(i+1 != matchAddresses.size()) {
                            addressIds += ',';
                        }
                    }
                    addressIds += ')';

                	if(hasAccountName || hasAccountEmail) {
                        accountQuery += ' OR ';
                    }
                    accountQuery += '(Id IN ' + addressIds + ')';
                }
            }

            if(hasAccountName || hasAccountEmail || hasAddressEmail) {
                accountQuery += ')';
				matchAccounts = DataBase.query(accountQuery);
            }

            List<sObject> accountEmailMatches = new List<sObject>();
            List<sObject> accountNameMatches = new List<sObject>();
            for(SObject match: matchAccounts) {
                boolean emailFound = false;
                for(String email : accountEmails) {
                    if(match.get(email) == emAtt.Email_vod__c) {
                        accountEmailMatches.add(match);
                        emailFound = true;
                        break;
                    }
                }
                if(!emailFound){
                    accountNameMatches.add(match);
                }
            }

            //Find Matching Users
            List<sObject> matchUsers = new List<sObject>();
            List<String> userEmails = emailMap.get('User');
            boolean hasUserEmail = false;
            boolean hasUserName = false;
            String userQuery = 'SELECT Id, LastName, FirstName';
            String userClause = '';
            if(!userEmails.isEmpty()) {
                if(emAtt.Email_vod__c != null) {
                	hasUserEmail = true;
                }
                for(Integer i = 0; i < userEmails.size(); i++) {
                    String fieldName = userEmails.get(i);
                    userQuery += ',' + fieldName;
                    if(hasUserEmail) {
                    	userClause += ' (' + fieldName  + '=\'' + emAtt.Email_vod__c + '\')';
                        if(i+1 != userEmails.size()) {
                            userClause += ' OR';
                        }
                    }
                }
            }

            userQuery += ' FROM User WHERE ' + userClause;
            if(emAtt.First_Name_vod__c != null && emAtt.Last_Name_vod__c != null) {
                hasUserName = true;
                if(hasUserEmail) {
                	userQuery += ' OR ';
                }
                userQuery += '(FirstName =\'' + String.escapeSingleQuotes(emAtt.First_Name_vod__c) + '\' AND LastName = \'' + String.escapeSingleQuotes(emAtt.Last_Name_vod__c) + '\')';
            }

            if(hasUserEmail || hasUserName) {
				matchUsers = DataBase.query(userQuery);
            }

            List<sObject> userEmailMatches = new List<sObject>();
            List<sObject> userNameMatches = new List<sObject>();
            for(SObject match: matchUsers) {
                boolean emailFound = false;
                for(String email : userEmails) {
                    if(match.get(email) == emAtt.Email_vod__c) {
                        userEmailMatches.add(match);
                        emailFound = true;
                        break;
                    }
                }
                if(!emailFound){
                    userNameMatches.add(match);
                }
            }

            sobject match = null;

            //Associate match if strong
            if(accountEmailMatches.size() == 1 && userEmailMatches.isEmpty()) {
                match = accountEmailMatches.get(0);
            	emAtt.Walk_In_Reference_ID_vod__c = (Id)match.get('Id');
            	if(emAtt.Walk_In_Status_vod__c != null){
            	    emAtt.Walk_In_Status_vod__c = 'Reconciled_To_Existing_Account_vod';
            	} else if (emAtt.Online_Registration_Status_vod__c != null) {
            	    emAtt.Online_Registration_Status_vod__c = 'Reconciled_To_Existing_Account_vod';
            	}
            } else if(userEmailMatches.size() == 1 && accountEmailMatches.isEmpty()) {
                match = userEmailMatches.get(0);
                emAtt.Walk_In_Reference_ID_vod__c = (Id)match.get('Id');
                if(emAtt.Walk_In_Status_vod__c != null){
                    emAtt.Walk_In_Status_vod__c = 'Reconciled_To_Existing_User_vod';
                } else if (emAtt.Online_Registration_Status_vod__c != null) {
                    emAtt.Online_Registration_Status_vod__c = 'Reconciled_To_Existing_User_vod';
                }
            } else if(accountNameMatches.size() == 1 && userNameMatches.isEmpty()) {
                match = accountNameMatches.get(0);
                emAtt.Walk_In_Reference_ID_vod__c = (Id)match.get('Id');
                if(emAtt.Walk_In_Status_vod__c != null){
                    emAtt.Walk_In_Status_vod__c = 'Reconciled_To_Existing_Account_vod';
                } else if (emAtt.Online_Registration_Status_vod__c != null) {
                    emAtt.Online_Registration_Status_vod__c = 'Reconciled_To_Existing_Account_vod';
                }
            } else if(userNameMatches.size() == 1 && accountNameMatches.isEmpty()) {
                match = userNameMatches.get(0);
                emAtt.Walk_In_Reference_ID_vod__c = (Id)match.get('Id');
                if(emAtt.Walk_In_Status_vod__c != null){
                    emAtt.Walk_In_Status_vod__c = 'Reconciled_To_Existing_User_vod';
                } else if (emAtt.Online_Registration_Status_vod__c != null) {
                    emAtt.Online_Registration_Status_vod__c = 'Reconciled_To_Existing_User_vod';
                }
            } else {
                if(emAtt.First_Name_vod__c != null) {
                    firstName = emAtt.First_Name_vod__c;
                }
                if(emAtt.Last_Name_vod__c != null) {
                    lastName = emAtt.Last_Name_vod__c;
                }
            }

            if(match != null) {
                if(match.get('LastName') != null) {
                    lastName = (String)match.get('LastName');
                }
                if(match.get('firstName') != null) {
                    firstName = (String)match.get('FirstName');
                }
            }
        } else {
            if(emAtt.First_Name_vod__c != null) {
                firstName = emAtt.First_Name_vod__c;
            }
            if(emAtt.Last_Name_vod__c != null) {
                lastName = emAtt.Last_Name_vod__c;
            }
        }

        if(emAtt.Stub_Mobile_Id_vod__c == null) {
            emAtt.Stub_Mobile_Id_vod__c = GuidUtil.NewGuid();
        }

        if((emAtt.Walk_In_Status_vod__c == 'Reconciled_To_Existing_Account_vod' || emAtt.Walk_In_Status_vod__c == 'Reconciled_To_New_Account_vod' ||
            emAtt.Online_Registration_Status_vod__c == 'Reconciled_To_Existing_Account_vod' || emAtt.Online_Registration_Status_vod__c == 'Reconciled_To_New_Account_vod')
             && emAtt.Walk_In_Reference_ID_vod__c != null) {
        	emAtt.Account_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
        } else if((emAtt.Walk_In_Status_vod__c == 'Reconciled_To_Existing_User_vod' || emAtt.Online_Registration_Status_vod__c == 'Reconciled_To_Existing_User_vod')  && emAtt.Walk_In_Reference_Id_vod__c != null) {
        	emAtt.User_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
        } else if (emAtt.Walk_In_Status_vod__c == 'Needs_Reconciliation_vod' && (emAtt.Walk_In_Reference_Id_vod__c == null || emAtt.Walk_In_Reference_Id_vod__c == '')) {
        	emAtt.User_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
            emAtt.Account_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
        }

        String name = lastName + ', ' + firstName;
        if(emAtt.Account_vod__c != null) {
            Account account = accounts.get(emAtt.Account_vod__c);
            if(account != null) {
				if(account.Formatted_Name_vod__c != null) {
                name = account.Formatted_Name_vod__c;
                } else if(account.FirstName != null && account.LastName != null) {
                    name = account.LastName + ', ' + account.FirstName;
                } else {
                    name = account.Name;
                }
                emAtt.Title_vod__c = account.PersonTitle;
                emAtt.Credentials_vod__c = account.Credentials_vod__c;
                if (emAtt.Walk_In_Status_vod__c == null && emAtt.Online_Registration_Status_vod__c == null) {
                    if(account.Furigana_vod__c != null) {
                        emAtt.Furigana_vod__c = account.Furigana_vod__c;
                    }
                    emAtt.First_Name_vod__c = account.FirstName;
                    emAtt.Last_Name_vod__c = account.LastName;
                }
            }
        }
        
        if(emAtt.Contact_vod__c != null) {
            Contact contact = contacts.get(emAtt.Contact_vod__c);
            if(contact != null) {
				if(contact.FirstName != null && contact.LastName != null) {
                name = contact.LastName + ', ' + contact.FirstName;
                } else {
                    name = contact.Name;
                }
				if (emAtt.Walk_In_Status_vod__c == null && emAtt.Online_Registration_Status_vod__c == null) {
                    emAtt.First_Name_vod__c = contact.FirstName;
                    emAtt.Last_Name_vod__c = contact.LastName;
                }
            }        
        }            
        
        if(emAtt.User_vod__c != null) {
            User user = users.get(emAtt.User_vod__c);
            if(user != null) {
				if(user.FirstName != null && user.LastName != null) {
                name = user.LastName + ', ' + user.FirstName;
                } else {
                    name = user.Name;
                }
				if (emAtt.Walk_In_Status_vod__c == null && emAtt.Online_Registration_Status_vod__c == null) {
                    emAtt.First_Name_vod__c = user.FirstName;
                    emAtt.Last_Name_vod__c = user.LastName;
            	}
            }
        }
        
        if(name != null) {
            emAtt.Attendee_Name_vod__c = name;
        }
    }
	 
}