public class VOD_CALL_TO_CALENDAR{
        	static Boolean inCallTrig = false;
            static Boolean inCalendarTrig = false;
            static Boolean inDelCallTrigger = false;
            
            public static void setCallTrig (Boolean p_inCallTrig) {
        		inCallTrig = p_inCallTrig;
        	}
        	 public static Boolean getCallTrig ()	{
           		return inCallTrig;
           }
        	
        	public static void setCalendarTrig (Boolean p_inCalendarTrig) {
        		inCalendarTrig = p_inCalendarTrig;
        	}
        	 public static Boolean getCalendarTrig ()	{
           		return inCalendarTrig;
           }
        	
        	public static void setDelCallTrig (Boolean p_inDelCallTrigger) {
        		inDelCallTrigger = p_inDelCallTrigger;
        	}
        	 public static Boolean getDelCallTrig ()	{
           		return inDelCallTrigger;
           }
        	
        }