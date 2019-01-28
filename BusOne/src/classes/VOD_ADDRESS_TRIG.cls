public class VOD_ADDRESS_TRIG{
            static Boolean inAddressTrig = false;
            static Boolean isPush = false;
            static Boolean isChildAcct = false;
            static Set<Id> addrSetFalse = new Set<Id>();
        	static Set<Id> setAddrDel = new Set<Id> ();

            public static void setAddressTrig (Boolean p_inAddressTrig) {
                inAddressTrig = p_inAddressTrig;
            }
            
           public static Boolean getAddressTrig ()  {
                return inAddressTrig;
           }
           
            public static void setPush (Boolean p_isPush) {
                isPush = p_isPush;
            }
            
           public static Boolean getPush () {
                return isPush;
           }
           
          public static void setChildAccount (Boolean p_isChildAcct) {
                isChildAcct = p_isChildAcct;
            }
            
           public static Boolean getChildAccount () {
                return isChildAcct;
           }
               public static void addCopySetFalse (String id) {
           		addrSetFalse.add(id);
           }
           
           public static Boolean isCopySetFalse (String id) {
           		return addrSetFalse.contains(id);	
           }
          
           public static void addDelSet (String id) {
           		setAddrDel.add(id);
           }
           
           public static Set<Id> getDelSet () {
           		return setAddrDel;	
           }
           
        }