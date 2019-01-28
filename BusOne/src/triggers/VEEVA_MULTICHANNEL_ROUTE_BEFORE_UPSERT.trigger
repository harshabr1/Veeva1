trigger VEEVA_MULTICHANNEL_ROUTE_BEFORE_UPSERT on Multichannel_Route_vod__c (before insert, before update) {

    Map<Id, String> countryNameMap = new Map<Id, String> ();
    Set<Id> routeCountryId = new Set<Id>();

    for (Multichannel_Route_vod__c route : trigger.new){
        routeCountryId.add(route.Country_vod__c);
    }

    List<SObject> countryNames = [Select Id,Alpha_2_Code_vod__c from Country_vod__c where Id in :routeCountryId];
    List<SObject> multichannelRecordType = [Select Id from RecordType where SobjectType='Multichannel_Route_vod__c' and DeveloperName in ('Email_Receipt_vod','Double_Opt_In_Confirmation_vod')];

    for(SObject  country : countryNames) {
        countryNameMap.put((Id)country.get('Id'), (String)country.get('Alpha_2_Code_vod__c'));
    }

    Set<Id> recordTypeIdSet = (new Map<Id,SObject>(multichannelRecordType)).keySet();

    for (Multichannel_Route_vod__c route : trigger.new){
        String recordTypeName = route.Record_Type_Name_vod__c;
        String recordTypeId = route.RecordTypeId;
        String objectName = route.Object_vod__c;
        if(recordTypeName == null){
            route.VExternal_Id_vod__c = objectName + '_' + route.Language_vod__c;
        } else {
            route.VExternal_Id_vod__c = objectName + '_' + recordTypeName + '_' + route.Language_vod__c;
        }

        if(recordTypeIdSet.contains(recordTypeId) && objectName.equals('Multichannel_Consent_vod__c')){
            if(route.Country_vod__c != null){
                if(countryNameMap.containsKey(route.Country_vod__c)){
                    route.VExternal_Id_vod__c += '_' + countryNameMap.get(route.Country_vod__c);
                }
            }
        }
    }
}