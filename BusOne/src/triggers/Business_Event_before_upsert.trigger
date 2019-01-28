trigger Business_Event_before_upsert on Business_Event_vod__c (before insert, before update)
{
    Map<Id, RecordType> recTypes = new Map<Id, RecordType>
        ([select Id, Name from RecordType where SobjectType = 'Business_Event_vod__c' and IsActive=true]);
    
    for (Business_Event_vod__c busEvnt : Trigger.new)
    {
        RecordType rt = recTypes.get(busEvnt.RecordTypeId);
        if (rt == null)
        {
            busEvnt.addError((busEvnt.Name + ' has invalid recordtype ' + busEvnt.RecordTypeId), false);
            return;
        }
        
        if ('EPPV'.equals(rt.Name))
        {
            if (busEvnt.Start_Date_vod__c == null || busEvnt.End_Date_vod__c == null || busEvnt.Product_Launch_Date_vod__c == null)
            {
                busEvnt.addError(('Start_Date_vod__c/End_Date_vod__c/Product_Launch_Date_vod__c ' + VOD_GET_ERROR_MSG.getErrorMsg('REQUIRED', 'Common')), false);
                return;
            }
        }
        else if ('PI'.equals(rt.Name))
        {
            if (busEvnt.Issue_Date_vod__c == null)
            {
                busEvnt.addError(('Issue_Date_vod__c ' + VOD_GET_ERROR_MSG.getErrorMsg('REQUIRED', 'Common')), false);
                return;
            }
        }
    }
}