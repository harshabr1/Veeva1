public with sharing class VEEVA_AccountCyclePlan_Control {

    public boolean getEnableRemainingSetting() {
        Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance(UserInfo.getProfileId());   
        return settings.ENABLE_CYCLE_PLANS_REMAINING_vod__c;  
    }

    public boolean enableRemaining { get; set; }

    public String getAccountId() {
        return  System.currentPageReference().getParameters().get('id');
    }
    public boolean getShowActualCalls(){
        return 'true'.equals(System.currentPageReference().getParameters().get('sac'));
    }
    public boolean getShowTotalCalls(){
        return 'true'.equals(System.currentPageReference().getParameters().get('stc'));
    }
    public boolean getShowProdDetails(){
        return 'true'.equals(System.currentPageReference().getParameters().get('spd'));
    }
}