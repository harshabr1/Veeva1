public class VOD_CALL_CHILD_VALIDATE {
        	
           public static boolean isValidCallID (String CallID)  {
           	
           	
           if (CallID == null ||CallId =='' ||  CallID =='null' || (CallID.startsWith('@') && CallID.endsWith('@')))
        		return false;
        		
        	return true; 
        	}
        	
        
        }