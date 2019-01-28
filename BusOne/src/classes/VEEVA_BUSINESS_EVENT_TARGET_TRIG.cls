public class VEEVA_BUSINESS_EVENT_TARGET_TRIG{
    public class CallObjectiveHolder
    {
        public Call_Objective_vod__c callObj;
        public Integer trig_idx;
    }
    
    //http://www.salesforce.com/us/developer/docs/apexcode/index_Left.htm#CSHID=apex_classes_static.htm|StartTopic=Content%2Fapex_classes_static.htm|SkinName=webhelp
    public static List<CallObjectiveHolder> holders = new List<CallObjectiveHolder>();
    public static boolean invoked = false;
}