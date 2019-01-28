trigger VOD_DATA_MAP_TEMPLATE_BEFORE on Data_Map_Template_vod__c (before update, before insert) {
        
            VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
            for (Integer i = 0; i < Trigger.new.size(); i++) {
            
                String name = Trigger.new[i].Name;
                if (Trigger.new[i].Active_vod__c == true) {
                    Data_Map_Template_vod__c [] dt = null;
                    if (Trigger.isInsert == true) {
                       dt = [Select Id from Data_Map_Template_vod__c where Name = :name and Active_vod__c = true];
                    } else {
                       String Id = Trigger.new[i].Id;
                       dt = [Select Id from Data_Map_Template_vod__c where Name = :name and Active_vod__c = true and Id != :Id];
                    }
                   
                    if (dt != null && dt.size() > 0 ) {
                       Trigger.new[i].Name.addError(bundle.getErrorMsg ('ONLY_ONE_NAME_DT') + name, false);
                    } 
                 }
            }
           
        }