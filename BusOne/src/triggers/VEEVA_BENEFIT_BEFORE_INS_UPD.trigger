trigger VEEVA_BENEFIT_BEFORE_INS_UPD on Benefit_Design_vod__c (before update,before insert) {
    
    Set<String> parentBdcSet = new Set<String> ();
       
    for (Benefit_Design_vod__c bdc : Trigger.new) {
        if (bdc.Parent_Design_vod__c != null) {
            parentBdcSet.add(bdc.Parent_Design_vod__c);     
        }
    }

    Map<String, Benefit_Design_vod__c> parentMap = 
              new  Map<String, Benefit_Design_vod__c> ([SELECT Id, Parent_Design_vod__c 
                                                        FROM Benefit_Design_vod__c 
                                                        WHERE Id in :parentBdcSet]);
                                                        
        for (Benefit_Design_vod__c bdc : Trigger.new) {
            if (bdc.Parent_Design_vod__c == null) {
                continue;  // Most will fall into this category
            } else {
            Benefit_Design_vod__c parentbdc =   parentMap.get(bdc.Parent_Design_vod__c);
            //Shouldn't happen but check anyways.
                if (parentbdc != null) {
                    if (parentbdc.Parent_Design_vod__c != null) {
                        bdc.Parent_Design_vod__c.addError(System.Label.NO_PARENT_CHAIN, false);
                    }
                }
            }
    }                                                    
    
}