trigger VEEVA_Samples_State_Settings_vod on Samples_State_Settings_vod__c (before update, before insert) {
    for (Samples_State_Settings_vod__c sss : Trigger.new) {
        sss.External_ID_vod__c = sss.Name;
        if (sss.CDS_Required_vod__c) {
            sss.External_ID_vod__c = sss.Name + '_CDSRequired';
        } else if (sss.State_Distributor_Required_vod__c) {
            sss.External_ID_vod__c = sss.Name + '_State_Distributor_Required';
        }
    }
}