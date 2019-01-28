trigger Veeva_Sample_State_Credential_Settings_vod on Samples_State_Credential_Settings_vod__c (before insert, before update) {

    for (Samples_State_Credential_Settings_vod__c  sp : Trigger.new) {
        // when restricted products field has value either state or country will have value and external id is based on which field has value
        if (sp.Restricted_Products_vod__c != null) {
            if (sp.Country_vod__c != null) {
                sp.External_ID_vod__c = sp.Country_vod__c + '_' + sp.Credential_vod__c + '_CountryRestrictionvod_';   
            } else {
                sp.External_ID_vod__c = sp.State_vod__c + '_' + sp.Credential_vod__c + '_StateRestrictionvod_';   
            }                  
        } 
        else if (sp.Collaborative_Relationship_Required_vod__c == True) {
            // Collaborative Relationship Required record - only State value, no Country configuration
            sp.External_ID_vod__c = sp.State_vod__c + '_' + sp.Credential_vod__c + '_CollaborativeRequired';
        }
        else {        
            sp.External_ID_vod__c = sp.State_vod__c + '_' + sp.Credential_vod__c;
        }
    }
}