trigger VOD_EM_SPEAKER_BEFORE_INS_UPD on EM_Speaker_vod__c (before insert, before update) {
    Set<String> accountSet = new Set<String>();
    Map<String, Account> accountMap = new Map<String, Account>();

    Integer defaultDay = 1;
    Integer defaultMonth = 1;

    Schema.DescribeFieldResult dayField = EM_Speaker_vod__c.Year_To_Date_Reset_Day_vod__c.getDescribe();
    List <Schema.PicklistEntry> dayPickVals = dayField.getPicklistValues();
    for (Schema.PicklistEntry pv: dayPickVals) {
        if (pv.isDefaultValue()) {
            defaultDay = Integer.valueOf(pv.getValue());
        }
    }

    Schema.DescribeFieldResult monthField = EM_Speaker_vod__c.Year_To_Date_Reset_Month_vod__c.getDescribe();
    List <Schema.PicklistEntry> monthPickVals = monthField.getPicklistValues();
    for (Schema.PicklistEntry pv: monthPickVals) {
        if (pv.isDefaultValue()) {
            defaultMonth = Integer.valueOf(pv.getValue());
        }
    }

    for (EM_Speaker_vod__c speaker : Trigger.new) {
        String account = speaker.Account_vod__c;
        if (account != null) {
            accountSet.add(account);
        }

        Integer day = speaker.Year_To_Date_Reset_Day_vod__c != null ? Integer.valueOf(speaker.Year_To_Date_Reset_Day_vod__c): defaultDay;
        Integer month = speaker.Year_To_Date_Reset_Month_vod__c != null ? Integer.valueOf(speaker.Year_To_Date_Reset_Month_vod__c): defaultMonth;
        Date resetDate = Date.newInstance(System.Today().year(), month, day);
        if(resetDate <= System.Today()) {
            speaker.Next_Year_Reset_Date_vod__c = Date.newInstance(System.Today().year() + 1, month, day);
        } else {
            speaker.Next_Year_Reset_Date_vod__c = resetDate;
        }
    }

    for (Account account : [SELECT Id, Formatted_Name_vod__c, FirstName, LastName, Credentials_vod__c, PersonTitle, Furigana_vod__c
                            FROM Account
                            WHERE Id IN :accountSet]) {
        accountMap.put(account.Id, account);
    }

    for (EM_Speaker_vod__c speaker : Trigger.new) {
        if (speaker.Account_vod__c != null) {
            Account account = accountMap.get(speaker.Account_vod__c);
            String name = account.Formatted_Name_vod__c;
            if(name != null && name.length() > 80) {
            	speaker.Name = name.subString(0,80);
            } else {
                speaker.Name = name;
            }
            speaker.First_Name_vod__c = account.FirstName;
            speaker.Last_Name_vod__c = account.LastName;
            speaker.Credentials_vod__c = account.Credentials_vod__c;
            speaker.Title_vod__c = account.PersonTitle;
            speaker.Furigana_vod__c = account.Furigana_vod__c;
        }
    }
}