trigger Account_After_Insert on Account (after insert) {

	boolean networkEnabled = VOD_Utils.isNetworkEnabled();
	List<Child_Account_vod__c> children = new List<Child_Account_vod__c>();
    String crmSettingValue = null;
    String thirdPartySettingValue = null;
    String country = null;
    Map<Id, RecordType> recordTypes = null;
    boolean crmManaged = false;
    boolean childAccountEnabledInWizards = false;
    if (networkEnabled) {
        crmSettingValue = VOD_Utils.getNetworkCrmManagedSettingValue();
        thirdPartySettingValue = VOD_Utils.getNetworkThirdPartyManagedSettingValue();
        recordTypes = new Map<Id, RecordType>([SELECT Id, DeveloperName FROM RecordType WHERE SobjectType='Account']);
        country = VOD_Utils.getUserCountry();
    }
    childAccountEnabledInWizards = VeevaSettings.isEnableChildAccountsInWizards();
    for (Account acct : Trigger.new) {
        if (networkEnabled) {            
            String acctRecordType = recordTypes.get(acct.RecordTypeId).DeveloperName;
            crmManaged = VOD_Utils.isNetworkCrmManaged(networkEnabled, thirdPartySettingValue, crmSettingValue, acctRecordType, country);
        }
        if (acct.Mobile_ID_vod__c == null
             && acct.Primary_Parent_vod__c != null
             && acct.Do_Not_Create_Child_Account_vod__c != true 
			 && (!networkEnabled || crmManaged)
			 && (!childAccountEnabledInWizards)) {
            Child_Account_vod__c childAccount = new Child_Account_vod__c();
            childAccount.Parent_Account_vod__c = acct.Primary_Parent_vod__c;
            childAccount.Child_Account_vod__c = acct.Id;
            if (VeevaSettings.isEnableParentAccountAddressCopy()) {
                childAccount.Copy_Address_vod__c = true;
            }
            children.add(childAccount);
        }
    }
    if (children.size() > 0) {
        try {
            VOD_Utils.setUpdateAccount(true);
            insert children;
        } finally {
            VOD_Utils.setUpdateAccount(false);
        }
    }
}