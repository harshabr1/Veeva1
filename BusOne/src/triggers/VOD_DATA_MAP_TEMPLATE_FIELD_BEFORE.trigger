trigger VOD_DATA_MAP_TEMPLATE_FIELD_BEFORE on Data_Map_Template_Field_vod__c (before update, before insert) {
            VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
            
            Set <String> templateIds = new Set<String> ();
            
            for (Integer k = 0; k < Trigger.new.size ();k++) {
                templateIds.add(Trigger.new[k].Data_Map_Template_vod__c);
            }
            
            Map <Id,Data_Map_Template_vod__c> dataMap = 
                   new Map <Id,Data_Map_Template_vod__c> ([Select Id,
                                                                 (Select  Column_Number_vod__c 
                                                                  From  Data_Map_Template_Field_vod__r  ) 
                                                           FROM Data_Map_Template_vod__c where Id in :templateIds]);
                                                           
        
             for (Integer l = 0; l < Trigger.new.size ();l++) {
                 Data_Map_Template_vod__c dmt = dataMap.get(Trigger.new[l].Data_Map_Template_vod__c);
                 
                 if (dmt == null) {
                    continue;
                 }
                 
                 if (dmt.Data_Map_Template_Field_vod__r != null) {
                    for (Data_Map_Template_Field_vod__c fld : dmt.Data_Map_Template_Field_vod__r) {
                      
                        if (Trigger.new[l].Column_Number_vod__c == fld.Column_Number_vod__c) {
                          Trigger.new[l].Column_Number_vod__c.addError(bundle.getErrorMsg ('COL_PRE_MAP'), false);
                          break;
                        }
                    }
                 }
             
             }
        }