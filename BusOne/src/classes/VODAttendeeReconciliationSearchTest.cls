global class VODAttendeeReconciliationSearchTest {

    webService static String searchAccounts(List<String> accountEmailFields, List<String> accountPhoneFields, String lastName, String email, String firstName, String phone, String userId) {
        Set<String> visibleAccountIds = getVisibleAccounts(userId);

        String query = 'SELECT FirstName, LastName, Primary_Parent_vod__r.Name, Id, ( SELECT Id,Name,Address_line_2_vod__c,City_vod__c,toLabel (State_vod__c),toLabel(Country_vod__c),Zip_vod__c,Zip_4_vod__c FROM Address_vod__r )';

        for(String accountField : accountEmailFields) {
            query+= ', ' + String.escapeSingleQuotes(accountField);
        }

        for(String accountField : accountPhoneFields) {
            query+= ', ' + String.escapeSingleQuotes(accountField);
        }

        query += ' FROM Account';

        if(lastName == null) {
        	lastName = '';
        }
        lastName = String.escapeSingleQuotes(lastName);

        if(email != null) {
        	 email = String.escapeSingleQuotes(email);
        }

        if(firstName != null) {
        	firstName = String.escapeSingleQuotes(firstName);
        }

        if(phone != null) {
        	phone = String.escapeSingleQuotes(phone);
        }

        if(lastName.length() <= 2) {
            query += ' WHERE LastName = \'' + lastName + '\'';
        } else {
            query += ' WHERE LastName Like \'' + lastName.subString(0,3) + '%\'';
        }
        query += 'AND ((LastName = \'' + lastName + '\')';


        boolean hasEmail = email != null;
        boolean hasFirstName = firstName != null;
        boolean hasPhone = phone != null;

        if(hasEmail) {
            query += ' OR (';
            for(Integer i=0; i < accountEmailFields.size(); i++) {
                query += String.escapeSingleQuotes(accountEmailFields.get(i)) + '=\'' + email +'\'';
                if(i+1 != accountEmailFields.size()) {
                    query +=' OR ';
                }
            }

            query +=')';
        }

        if(hasFirstName) {
            query +=' OR (FirstName =\'' + firstName + '\' AND LastName = \''+ lastName + '\')';
        }

        if(hasPhone) {
            query += ' OR (';
            for(Integer i=0; i < accountPhoneFields.size(); i++) {
                query += String.escapeSingleQuotes(accountPhoneFields.get(i)) + '=\'' + phone + '\'';
                if(i+1 != accountPhoneFields.size()) {
                    query += ' OR ';
                }
            }

            query += ')';
        }
        query += ')';

        List<sObject> accountQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();
        for(sObject account: accountQueryResults) {
            SearchResult currentResult = new SearchResult();
            currentResult.Id = account.Id;
            sObject parentAccount = account.getSObject('Primary_Parent_vod__r');
            if(parentAccount != null) {
            	currentResult.parentName = (String)parentAccount.get('Name');
            }
            currentResult.firstName = (String)account.get('FirstName');
            currentResult.lastName = (String)account.get('LastName');
            currentResult.inTerritory = visibleAccountIds.contains(currentResult.Id);

            List<String> phoneNumbers = new List<String>();
            for(String phoneField : accountPhoneFields) {
                if(account.get(phoneField) != null) {
                    phoneNumbers.add((String) account.get(phoneField));
                }
            }
            currentResult.phoneNumbers = phoneNumbers;

            List<String> emails = new List<String>();
            for(String emailField : accountEmailFields) {
                if(account.get(emailField) != null) {
                    emails.add((String) account.get(emailField));
                }
            }
            currentresult.emails = emails;

            List<AddressResult> addresses = new List<AddressResult>();
            for(sObject addressRow :account.getSObjects('Address_vod__r')) {
                AddressResult addressResult = new AddressResult();
                addressResult.addressLine1 = (String)addressRow.get('Name');
                addressResult.addressLine2 = (String)addressRow.get('Address_line_2_vod__c');
                addressResult.city = (String)addressRow.get('City_vod__c');
                addressResult.state = (String)addressRow.get('State_vod__c');
                addressResult.zip = (String)addressRow.get('Zip_vod__c');
                addressResult.country = (String)addressRow.get('Country_vod__c');
                addressResult.Id = (String)addressRow.get('Id');

                addresses.add(addressResult);
            }
            currentResult.addresses = addresses;
            searchResults.add(currentResult);
        }

        return JSON.serialize(searchResults);
    }

    webService static String searchAddresses(List<String> addressEmailFields, List<String> addressPhoneFields, List<String> accountEmailFields, List<String> accountPhoneFields,
                                             String lastName, String email, String phone, String zip, String city, String userId) {
        Set<String> visibleAccountIds = getVisibleAccounts(userId);

        String query = 'SELECT Id,Name,Address_line_2_vod__c,City_vod__c,toLabel (State_vod__c),toLabel(Country_vod__c),Zip_vod__c,Zip_4_vod__c';

        if(lastName == null) {
        	lastName = '';
        }
		lastName = String.escapeSingleQuotes(lastName);

        if(email != null) {
        	 email = String.escapeSingleQuotes(email);
        }

        if(phone != null) {
        	phone = String.escapeSingleQuotes(phone);
        }

        if(city != null) {
        	city = String.escapeSingleQuotes(city);
        }

        if(zip != null) {
        	zip = String.escapeSingleQuotes(zip);
        }


        for(String addressField : addressEmailFields) {
            query+= ', ' + String.escapeSingleQuotes(addressField);
        }

        for(String addressField : addressPhoneFields) {
            query+= ', ' + String.escapeSingleQuotes(addressField);
        }

        query += ', Account_vod__r.Primary_Parent_vod__r.Name, Account_vod__r.FirstName, Account_vod__r.LastName';

        for(String accountField : accountEmailFields) {
            query+= ', Account_vod__r.' + String.escapeSingleQuotes(accountField);
        }

        for(String accountField : accountPhoneFields) {
            query+= ', Account_vod__r.' + String.escapeSingleQuotes(accountField);
        }

        query += ' FROM Address_vod__c';



        if(lastName.length() <= 2) {
            query += ' WHERE Account_vod__c IN (SELECT Id From Account WHERE LastName = \'' + lastName + '\')';
        } else {
            query += ' WHERE Account_vod__c IN (SELECT Id From Account WHERE LastName LIKE \'' + lastName.subString(0,3) + '%\')';
        }

        boolean hasEmail = email != null;
        boolean hasPhone = phone != null;
        boolean hasZip = zip != null;
        boolean hasCity = city != null;

        if(hasEmail || hasPhone || hasZip || hasCity) {
            query += ' AND (';

            if(hasEmail) {
                query += '(';
                for(Integer i=0; i < addressEmailFields.size(); i++) {
                    String currentField = String.escapeSingleQuotes(addressEmailFields.get(i));
                    query += currentField + '=\'' + email + '\'';
                    if(i+1 != addressEmailFields.size()) {
                        query += ' OR ';
                    }
                }

                query += ')';
            }

            if(hasPhone) {
                if(hasEmail) {
                    query += ' OR ';
                }
                query += '(';
                for(Integer i=0; i < addressPhoneFields.size(); i++) {
                    String currentField = String.escapeSingleQuotes(addressPhoneFields.get(i));
                    query += currentField + '=\'' + phone + '\'';
                    if(i+1 != addressPhoneFields.size()) {
                        query += ' OR ';
                    }
                }

                query += ')';
            }

            if(hasZip) {
                if(hasEmail || hasPhone) {
                    query += ' OR ';
                }
                query += '((Account_vod__r.LastName = \'' + lastName + '\') AND (Zip_vod__c = \'' + zip  + '\' OR Zip_4_vod__c = \'' + zip + '\'))';
            }

            if(hasCity) {
                if(hasZip || hasEmail || hasPhone) {
                    query += ' OR ';
                }
                query += '(Account_vod__r.LastName = \'' + lastName + '\' AND (City_vod__c = \'' + city + '\'))';
            }

            query += ')';
        } else {
            return JSON.serialize(new List<SearchResult>());
        }

        List<sObject> addressQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();
        Map<String, SearchResult> resultRowMap = new Map<String, SearchResult>();
        for(sObject addressRow: addressQueryResults) {

            sObject account = addressRow.getsObject('Account_vod__r');
            SearchResult resultRow = new SearchResult();
            List<AddressResult> currentAddresses = new List<AddressResult>();
            if(resultRowMap.containsKey((String)account.get('Id'))) {
                resultRow = resultRowMap.get((String) account.get('Id'));
                currentAddresses =  resultRow.addresses;
            } else {
                resultRow.Id = account.Id;
                sObject parentAccount = account.getSObject('Primary_Parent_vod__r');
                if(parentAccount != null) {
                    resultRow.parentName = (String)parentAccount.get('Name');
                }
                resultRow.firstName = (String)account.get('FirstName');
                resultRow.lastName = (String)account.get('LastName');

                List<String> phoneNumbers = new List<String>();
                for(String phoneField : accountPhoneFields) {
                    if(account.get(phoneField) != null) {
                        phoneNumbers.add((String) account.get(phoneField));
                    }
                }
                resultRow.phoneNumbers = phoneNumbers;

                List<String> emails = new List<String>();
                for(String emailField : accountEmailFields) {
                    if(account.get(emailField) != null) {
                        emails.add((String) account.get(emailField));
                    }
                }
                resultRow.emails = emails;
                resultRow.inTerritory = visibleAccountIds.contains(resultRow.Id);
            }


            AddressResult addressResult = new AddressResult();
            addressResult.addressLine1 = (String)addressRow.get('Name');
            addressResult.addressLine2 = (String)addressRow.get('Address_line_2_vod__c');
            addressResult.city = (String)addressRow.get('City_vod__c');
            addressResult.state = (String)addressRow.get('State_vod__c');
            addressResult.zip = (String)addressRow.get('Zip_vod__c');
            addressResult.country = (String)addressRow.get('Country_vod__c');
            addressResult.Id = (String)addressRow.get('Id');

            currentAddresses.add(addressResult);
            resultRow.addresses = currentAddresses;
            resultRowMap.put((String)account.get('Id'), resultRow);
        }

        for(SearchResult result: resultRowMap.values()) {
            searchResults.add(result);
        }
        return JSON.serialize(searchResults);
    }

    webService static String searchUsers(List<String> userEmailFields, List<String> userPhoneFields, String lastName, String email, String firstName, String phone, String zip, String city, String userId) {
        Set<String> visibleAccountIds = getVisibleAccounts(userId);

        String query = 'SELECT Id,FirstName,LastName,City,Country,PostalCode,State,Street';

        if(lastName == null) {
        	lastName = '';
        }
		lastName = String.escapeSingleQuotes(lastName);

        if(firstName != null) {
        	firstName = String.escapeSingleQuotes(firstName);
        }

        if(email != null) {
        	 email = String.escapeSingleQuotes(email);
        }

        if(phone != null) {
        	phone = String.escapeSingleQuotes(phone);
        }

        if(city != null) {
        	city = String.escapeSingleQuotes(city);
        }

        if(zip != null) {
        	zip = String.escapeSingleQuotes(zip);
        }


        for(String userField : userEmailFields) {
            query+= ', ' + String.escapeSingleQuotes(userField);
        }

        for(String userField : userPhoneFields) {
            query+= ', ' + String.escapeSingleQuotes(userField);
        }

        query += ' FROM User';

        if(lastName.length() <= 2) {
            query += ' WHERE LastName = \'' + lastName + '\'';
        } else {
            query += ' WHERE LastName Like \'' + lastName.subString(0,3) + '%\'';
        }

        query += 'AND ((LastName = \'' + lastName + '\')';

        boolean hasEmail = email != null;
        boolean hasFirstName = firstName != null;
        boolean hasPhone = phone != null;
        boolean hasZip = zip != null;
        boolean hasCity = city != null;


        if(hasEmail) {
            query += ' OR (';
            for(Integer i=0; i < userEmailFields.size(); i++) {
                query += String.escapeSingleQuotes(userEmailFields.get(i)) + '=\'' + email +'\'';
                if(i+1 != userEmailFields.size()) {
                    query +=' OR ';
                }
            }

            query +=')';
        }

        if(hasFirstName) {
            query +=' OR (FirstName =\'' + firstName + '\' AND LastName = \''+ lastName + '\')';
        }

        if(hasPhone) {
            query += ' OR (';
            for(Integer i=0; i < userPhoneFields.size(); i++) {
                query += String.escapeSingleQuotes(userPhoneFields.get(i)) + '=\'' + phone + '\'';
                if(i+1 != userPhoneFields.size()) {
                    query += ' OR ';
                }
            }

            query += ')';
        }

        if(hasZip) {
            query += ' OR (PostalCode =\'' + zip + '\' AND LastName = \''+ lastName + '\')';
        }

        if(hasCity) {
            query += ' OR (City =\'' + city + '\' AND LastName = \''+ lastName + '\')';
        }
        query += ')';

        List<sObject> userQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();
        for(sObject user: userQueryResults) {
            SearchResult currentResult = new SearchResult();
            currentResult.Id = user.Id;
            currentResult.isUser = true;
            currentResult.firstName = (String)user.get('FirstName');
            currentResult.lastName = (String)user.get('LastName');
            currentResult.inTerritory = visibleAccountIds.contains(currentResult.Id);

            List<String> phoneNumbers = new List<String>();
            for(String phoneField : userPhoneFields) {
                if(user.get(phoneField) != null) {
                    phoneNumbers.add((String) user.get(phoneField));
                }
            }
            currentResult.phoneNumbers = phoneNumbers;

            List<String> emails = new List<String>();
            for(String emailField : userEmailFields) {
                if(user.get(emailField) != null) {
                    emails.add((String) user.get(emailField));
                }
            }
            currentresult.emails = emails;

            List<AddressResult> addresses = new List<AddressResult>();
            AddressResult addressResult = new AddressResult();
            addressResult.addressLine1 = (String)user.get('Street');
            addressResult.city = (String)user.get('City');
            addressResult.state = (String)user.get('State');
            addressResult.zip = (String)user.get('PostalCode');
            addressResult.country  = (String)user.get('Country');
            addressResult.Id = (String)user.get('Id');

            addresses.add(addressResult);
            currentResult.addresses = addresses;
            searchResults.add(currentResult);
        }
        return JSON.serialize(searchResults);
    }

    webService static String findAccountResult(String Id, List<String> accountEmailFields, List<String> accountPhoneFields) {
        String query = 'SELECT FirstName, LastName, Primary_Parent_vod__r.Name, Id, ( SELECT Id,Name,Address_line_2_vod__c,City_vod__c,toLabel (State_vod__c),toLabel(Country_vod__c),Zip_vod__c,Zip_4_vod__c FROM Address_vod__r )';

        if(Id == null) {
        	Id = '';
        }

        Id = String.escapeSingleQuotes(Id);

        for(String accountField : accountEmailFields) {
            query+= ', ' + String.escapeSingleQuotes(accountField);
        }

        for(String accountField : accountPhoneFields) {
            query+= ', ' + String.escapeSingleQuotes(accountField);
        }

        query += ' FROM Account WHERE Id =\'' + Id + '\'';

        List<sObject> accountQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();
        for(sObject account: accountQueryResults) {
            SearchResult currentResult = new SearchResult();
            currentResult.Id = account.Id;
            sObject parentAccount = account.getSObject('Primary_Parent_vod__r');
            if(parentAccount != null) {
                currentResult.parentName = (String)parentAccount.get('Name');
            }
            currentResult.firstName = (String)account.get('FirstName');
            currentResult.lastName = (String)account.get('LastName');

            List<String> phoneNumbers = new List<String>();
            for(String phoneField : accountPhoneFields) {
                if(account.get(phoneField) != null) {
                    phoneNumbers.add((String) account.get(phoneField));
                }
            }
            currentResult.phoneNumbers = phoneNumbers;

            List<String> emails = new List<String>();
            for(String emailField : accountEmailFields) {
                if(account.get(emailField) != null) {
                    emails.add((String) account.get(emailField));
                }
            }
            currentresult.emails = emails;

            List<AddressResult> addresses = new List<AddressResult>();
            for(sObject addressRow :account.getSObjects('Address_vod__r')) {
                AddressResult addressResult = new AddressResult();
                addressResult.addressLine1 = (String)addressRow.get('Name');
                addressResult.addressLine2 = (String)addressRow.get('Address_line_2_vod__c');
                addressResult.city = (String)addressRow.get('City_vod__c');
                addressResult.state = (String)addressRow.get('State_vod__c');
                addressResult.zip = (String)addressRow.get('Zip_vod__c');
                addressResult.country = (String)addressRow.get('Country_vod__c');
                addressResult.Id = (String)addressRow.get('Id');

                addresses.add(addressResult);
            }
            currentResult.addresses = addresses;
            searchResults.add(currentResult);
        }

        return JSON.serialize(searchResults);
    }

    webService static String findUserResult(String Id, List<String> userEmailFields, List<String> userPhoneFields) {
        String query = 'SELECT Id,FirstName,LastName,City,Country,PostalCode,State,Street';

        if(Id == null) {
        	Id = '';
        }

        Id = String.escapeSingleQuotes(Id);

        for(String userField : userEmailFields) {
            query+= ', ' + String.escapeSingleQuotes(userField);
        }

        for(String userField : userPhoneFields) {
            query+= ', ' + String.escapeSingleQuotes(userField);
        }

        query += ' FROM User WHERE Id = \'' + Id + '\'';

        List<sObject> userQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();
        for(sObject user: userQueryResults) {
            SearchResult currentResult = new SearchResult();
            currentResult.Id = user.Id;
            currentResult.isUser = true;
            currentResult.firstName = (String)user.get('FirstName');
            currentResult.lastName = (String)user.get('LastName');

            List<String> phoneNumbers = new List<String>();
            for(String phoneField : userPhoneFields) {
                if(user.get(phoneField) != null) {
                    phoneNumbers.add((String) user.get(phoneField));
                }
            }
            currentResult.phoneNumbers = phoneNumbers;

            List<String> emails = new List<String>();
            for(String emailField : userEmailFields) {
                if(user.get(emailField) != null) {
                    emails.add((String) user.get(emailField));
                }
            }
            currentresult.emails = emails;

            List<AddressResult> addresses = new List<AddressResult>();
            AddressResult addressResult = new AddressResult();
            addressResult.addressLine1 = (String)user.get('Street');
            addressResult.city = (String)user.get('City');
            addressResult.state = (String)user.get('State');
            addressResult.zip = (String)user.get('PostalCode');
            addressResult.country  = (String)user.get('Country');
            addressResult.Id = (String)user.get('Id');

            addresses.add(addressResult);
            currentResult.addresses = addresses;
            searchResults.add(currentResult);
        }
        return JSON.serialize(searchResults);
    }

    static Set<String> getVisibleAccounts(String userId) {
        Set<String> groupIds = new Set<String>();
        groupIds.add(userId);

        // user's territory
        for (Group g: [SELECT Id FROM Group WHERE RelatedId in (SELECT TerritoryId FROM UserTerritory WHERE UserId = :userId)]) {
          groupIds.add(g.Id);
        }

        // parent's territory
        //Set<String> parentTerritories = new Set<String>();
        //for (UserTerritory u: [SELECT TerritoryId FROM UserTerritory WHERE UserId = :userId]) {
        //  parentTerritories.add(u.TerritoryId);
        //}
        //Set<String> newTerritories = new Set<String>();
        //newTerritories.addAll(parentTerritories);
        //while (newTerritories.size() != 0) {
        //  List<Territory> territoryQueryResult = [SELECT ParentTerritoryId FROM Territory WHERE Id in :newTerritories];
        //  newTerritories.clear();
        //  for (Territory t: territoryQueryResult){
        //    if (t.ParentTerritoryId != null && !parentTerritories.contains(t.ParentTerritoryId)) {
        //      parentTerritories.add(t.ParentTerritoryId);
        //      newTerritories.add(t.ParentTerritoryId);
        //    }
        //  }
        //}
        //for (Group g: [SELECT Id FROM Group WHERE RelatedId in :ParentTerritories AND Type = 'TerritoryAndSubordinates']) {
        //  groupIds.add(g.Id);
        //}

        // user's role
        for (Group g: [SELECT Id FROM Group WHERE RelatedId in (SELECT UserRoleId FROM User WHERE Id = :userId)]) {
          groupIds.add(g.Id);
        }

        // parent's roles
        //String userRoleId = '';
        //for (User u: [SELECT UserRoleId FROM User WHERE Id = :userId]) {
        //  userRoleId = u.UserRoleId;
        //}
        //Set<String> parentRoles = new Set<String>();
        //Set<String> newRoles = new Set<String>();
        //parentRoles.add(userRoleId);
        //newRoles.add(userRoleId);
        //while (newRoles.size() != 0) {
        //  List<UserRole> roleQueryResult = [SELECT ParentRoleId FROM UserRole WHERE Id in :newRoles];
        //  newRoles.clear();
        //  for (UserRole u: roleQueryResult){
        //    if (u.ParentRoleId != null && !parentRoles.contains(u.ParentRoleId)) {
        //      parentRoles.add(u.ParentRoleId);
        //      newRoles.add(u.ParentRoleId);
        //    }
        //  }
        //}
        //for (Group g: [SELECT Id FROM Group WHERE RelatedId in :ParentRoles AND Type = 'RoleAndSubordinates']) {
        //  groupIds.add(g.Id);
        //}

        // groups in groups
        //Set<String> newGroups = new Set<String>();
        //newGroups.addAll(groupIds);
        //while (newGroups.size() != 0) {
        //  List<GroupMember> groupMemberQueryResult = [Select GroupId FROM GroupMember WHERE UserOrGroupId in :newGroups];
        //  newGroups.clear();
        //  for (GroupMember gm: groupMemberQueryResult) {
        //    if (!groupIds.contains(gm.GroupId)) {
        //      groupIds.add(gm.GroupId);
        //      newGroups.add(gm.GroupId);
        //    }
        //  }
        //}

        // get visible accounts
        Set<String> visibleAccountIds = new Set<String>();
        for (AccountShare accountShare: [SELECT AccountId FROM AccountShare WHERE UserOrGroupId in :groupIds]) {
          visibleAccountIds.add(accountShare.AccountId);
        }
        return visibleAccountIds;
    }

    global class SearchResult {
        String parentName;
        String Id;
        String firstName;
        String lastName;
        List<AddressResult> addresses;
        List<String> emails;
        List<String> phoneNumbers;
        boolean isUser;
        boolean inTerritory;
    }

    global class AddressResult {
        String Id;
        String addressLine1;
        String addressLine2;
        String state;
        String city;
        String zip;
        String country;
    }
}