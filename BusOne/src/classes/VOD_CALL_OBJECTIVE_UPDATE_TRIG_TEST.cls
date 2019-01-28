@isTest
public class VOD_CALL_OBJECTIVE_UPDATE_TRIG_TEST {
    static testMethod void testupdate_Completed_Call_Objective_With_FlipRecurringToTrue_ShouldFail() {
        
       System.Test.startTest();
       String objId = insertTestObject(false,null);
       System.Test.stopTest();
 
        Call_Objective_vod__c inserted = [SELECT Call2_vod__c,Completed_Flag_vod__c,Date_vod__c,From_Date_vod__c,Id,Name_vod__c,
                                   RecordTypeId,Recurring_vod__c,To_Date_vod__c FROM Call_Objective_vod__c 
                                                    WHERE Id= :objId LIMIT 1];
        try {
            objId = updateTestObject(inserted,null, true,true);
            Call_Objective_vod__c updated = [SELECT Call2_vod__c,Completed_Flag_vod__c,Date_vod__c,From_Date_vod__c,Id,Name_vod__c,
                                       RecordTypeId,Recurring_vod__c,To_Date_vod__c FROM Call_Objective_vod__c 
                                                        WHERE Id= :objId LIMIT 1];
        }
        catch(Exception e)
        {
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        } 
    }
    static testMethod void testupdate_Called_Call_Objective_With_FlipRecurringToTrue_ShouldFail() {
       system.Test.startTest();
       String objId = insertTestObject(false,null);
       System.Test.stopTest();
 
        Call_Objective_vod__c inserted = [SELECT Call2_vod__c,Completed_Flag_vod__c,Date_vod__c,From_Date_vod__c,Id,Name_vod__c,
                                   RecordTypeId,Recurring_vod__c,To_Date_vod__c FROM Call_Objective_vod__c 
                                                    WHERE Id= :objId LIMIT 1];
        try {
            objId = updateTestObject(inserted,'a04Z0000009KLFOIA4', false,true);
            Call_Objective_vod__c updated = [SELECT Call2_vod__c,Completed_Flag_vod__c,Date_vod__c,From_Date_vod__c,Id,Name_vod__c,
                                       RecordTypeId,Recurring_vod__c,To_Date_vod__c FROM Call_Objective_vod__c 
                                                        WHERE Id= :objId LIMIT 1];
        }
        catch(Exception e)
        {
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        } 
    }
    static testMethod void testupdate_Childed_Call_Objective_With_FlipRecurringToFalse_ShouldFail() {
       system.Test.startTest();
       String objId = insertTestObject(true,null);
       String objChildId = insertTestObject(true,objId);
       System.Test.stopTest();
 
        Call_Objective_vod__c inserted = [SELECT Call2_vod__c,Completed_Flag_vod__c,Date_vod__c,From_Date_vod__c,Id,Name_vod__c,
                                   RecordTypeId,Recurring_vod__c,To_Date_vod__c FROM Call_Objective_vod__c 
                                                    WHERE Id= :objId LIMIT 1];
        try {
            objId = updateTestObject(inserted,null, false,false);
            Call_Objective_vod__c updated = [SELECT Call2_vod__c,Completed_Flag_vod__c,Date_vod__c,From_Date_vod__c,Id,Name_vod__c,
                                       RecordTypeId,Recurring_vod__c,To_Date_vod__c FROM Call_Objective_vod__c 
                                                        WHERE Id= :objId LIMIT 1];
        }
        catch(Exception e)
        {
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        } 
    }
    static testMethod void testupdate_NoChilded_Call_Objective_With_FlipRecurringToFalse_ShouldPass() {
       system.Test.startTest();
       String objId = insertTestObject(true,null);
       //String objChildId = insertTestObject(true,objId);
       System.Test.stopTest();
 
        Call_Objective_vod__c inserted = [SELECT Call2_vod__c,Completed_Flag_vod__c,Date_vod__c,From_Date_vod__c,Id,Name_vod__c,
                                   RecordTypeId,Recurring_vod__c,To_Date_vod__c FROM Call_Objective_vod__c 
                                                    WHERE Id= :objId LIMIT 1];
        
        objId = updateTestObject(inserted,null, false,false);
        Call_Objective_vod__c updated = [SELECT Call2_vod__c,Completed_Flag_vod__c,Date_vod__c,From_Date_vod__c,Id,Name_vod__c,
                                         RecordTypeId,Recurring_vod__c,To_Date_vod__c FROM Call_Objective_vod__c 
                                         WHERE Id= :objId LIMIT 1];
        System.assertEquals(false, updated.Recurring_vod__c);
    }
    private static String insertTestObject(boolean Recurring, String parentId){
       Call_Objective_vod__c obj = new Call_Objective_vod__c(
            Business_Event_vod__c = 'a1kZ0000000eanUIAQ' ,
            Business_Event_Target_vod__c='a1jZ0000001ValyIAC',
            Account_vod__c = '001Z000000CEglvIAD',
            Name_vod__c = 'test',
            Recurring_vod__c = Recurring,
            RecordTypeId='012A0000000k5siIAA',
            Date_vod__c = Datetime.now()
        ); 
        if(parentId != null){
            obj.Parent_Objective_vod__c = parentId;
        }
        insert obj; 
        return obj.Id; 
    } 
    private static String updateTestObject(Call_Objective_vod__c updateObj,String Call, boolean Completed,boolean Recurring){
       Call_Objective_vod__c obj = updateObj;
       updateObj.Completed_Flag_vod__c = Completed;
       updateObj.Call2_vod__c = Call;
       updateObj.Recurring_vod__c = Recurring;
        
        update obj; 
        return obj.Id; 
    }
}