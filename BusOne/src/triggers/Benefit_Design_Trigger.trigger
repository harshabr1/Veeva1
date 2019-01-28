trigger Benefit_Design_Trigger on Benefit_Design_vod__c bulk (after update) {
            
            for (Integer i=0;i<Trigger.old.size();i++) {
                Benefit_Design_vod__c oldBD = Trigger.old[i];
                Benefit_Design_vod__c newBD = Trigger.new[i];
                if ((newBD.Parent_Design_vod__c != null) && (oldBD.Parent_Design_vod__c != newBD.Parent_Design_vod__c)) {
                    Benefit_Design_Line_vod__c[] linesToDelete = [Select Id from Benefit_Design_Line_vod__c where Benefit_Design_vod__c=:newBD.Id limit 100];
                    try {
                        delete linesToDelete;
                        System.debug('Deleted '+linesToDelete.size()+' benefit design lines associated with '+newBD.Name);
                    } catch (System.DmlException e) {
                        System.debug(e.getMessage());
                    }
                }
                if (oldBD.Type_vod__c != newBD.Type_vod__c) {
                    VOD_BEN_LINE.setBenLine (true);
                    Benefit_Design_Line_vod__c[] linesToUpdate = [Select Id from Benefit_Design_Line_vod__c where Benefit_Design_vod__c=:newBD.Id limit 100];
                    List <Benefit_Design_Line_vod__c> updList = new List <Benefit_Design_Line_vod__c> ();
        
                    for (Integer j=0;j<linesToUpdate.size();j++) {
                        Benefit_Design_Line_vod__c newBDL  = new Benefit_Design_Line_vod__c (Id = linesToUpdate[j].Id, Type_vod__c = newBD.Type_vod__c);
                        updList.add (newBDL);
                    }
                    
                    if (updList.size () > 0) {
                        System.debug('Updating type for '+linesToUpdate.size()+' benefit design lines');
                        update updList;
                    }
                }
            }
        }