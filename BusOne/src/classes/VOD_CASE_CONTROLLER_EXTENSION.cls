public with sharing class VOD_CASE_CONTROLLER_EXTENSION {
	private final Case c;
    
    public VOD_CASE_CONTROLLER_EXTENSION(ApexPages.StandardController stdController) {
        List<String> fields = new List<String>();
        fields.add('AccountId');
        stdController.addFields(fields);
        
        c = (Case)stdController.getRecord();        
    }
    
    public VOD_CASE_CONTROLLER_EXTENSION() {
        
    }
}