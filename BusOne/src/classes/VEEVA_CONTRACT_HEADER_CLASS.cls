public class VEEVA_CONTRACT_HEADER_CLASS {
	private static boolean fromContractAfterTrigger = false;
    private static boolean fromContractBeforeTrigger = false;
    private static boolean isEmSpeakerQualificationEnabled;
    
    public static boolean isFromContractAfterTrigger() {
        return fromContractAfterTrigger;
    }
    
    public static boolean isFromContractBeforeTrigger() {
        return fromContractBeforeTrigger;
    }
    
    public static void setFromContractAfterTrigger(boolean val) {
        fromContractAfterTrigger = val;
    }
    
    public static void setFromContractBeforeTrigger(boolean val){
        fromContractBeforeTrigger = val;
    }
    
    public static boolean isEmSpeakerQualificationEnabled() {
        if(isEmSpeakerQualificationEnabled == null) {
            List<Schema.RecordTypeInfo> infos = EM_Speaker_Qualification_vod__c.sObjectType.getDescribe().getRecordTypeInfosById().values();
	      	if(infos.isEmpty()) {
    	        isEmSpeakerQualificationEnabled = false;
                return isEmSpeakerQualificationEnabled;
        	}
        	for(Schema.RecordTypeInfo rt : infos) {
            	if(!rt.isMaster() && rt.isAvailable()) {
                    isEmSpeakerQualificationEnabled = true;
                	return isEmSpeakerQualificationEnabled;
            	}
        	}
        	isEmSpeakerQualificationEnabled = false;
        }
        return isEmSpeakerQualificationEnabled;
    }
}