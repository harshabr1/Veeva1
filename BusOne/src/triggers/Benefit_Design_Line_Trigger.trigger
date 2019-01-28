trigger Benefit_Design_Line_Trigger on Benefit_Design_Line_vod__c bulk (after insert, after update) {
            if (VOD_BEN_LINE.getBenLine() == true)
                return;
        
            VOD_BEN_LINE.setBenLine(true);
        
            List <Benefit_Design_Line_vod__c> updList = new List <Benefit_Design_Line_vod__c>();
            Map <Id, Benefit_Design_Line_vod__c> myBDLs = new Map <Id, Benefit_Design_Line_vod__c>
                    ([Select Benefit_Design_vod__r.Type_vod__c from Benefit_Design_Line_vod__c where Id in :Trigger.new limit 100]);
        
            for (Integer i=0;i<Trigger.new.size();i++) {
                if (myBDLs.containsKey(Trigger.new[i].Id)) {
                    Benefit_Design_Line_vod__c myBD = myBDLs.get(Trigger.new[i].Id);
                    Benefit_Design_Line_vod__c newBDL = new Benefit_Design_Line_vod__c (ID = Trigger.new[i].Id, Type_vod__c = myBD.Benefit_Design_vod__r.Type_vod__c);
                    updList.add (newBDL);
                }
            }
        
            if (updList.size () > 0) {
                update updList;
            }
        }