trigger Sample_Inventory_Before_vod on Sample_Inventory_vod__c (before delete, before update, before insert) {
                    
                    
                    for (Integer i = 0; i < (Trigger.isDelete ? Trigger.old.size(): Trigger.new.size()); i++) {
                    
                    if (Trigger.isUpdate) {
                            Sample_Inventory_vod__c sampInv = Trigger.new[i];
                        
                            if (sampInv.Unlock_vod__c == true) {
                                  
                                  sampInv.Unlock_vod__c = false;
                                  sampInv.Status_vod__c = 'Saved_vod';
                                  continue;
                                  
                            } else  if (Trigger.old[i].Status_vod__c == 'Submitted_vod') {
                                Trigger.new[i].Status_vod__c.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_SAMP_INV','TriggerError'), false);
                            }
                        }
                    
                        if (Trigger.isUpdate  || Trigger.isInsert){
                            if (Trigger.isUpdate) {
                                if (Trigger.new[i].Status_vod__c == 'Submitted_vod' && Trigger.new[i].Submitted_vod__c == false) {
                                  Trigger.new[i].Submitted_Date_vod__c = System.now();
                                  Trigger.new[i].Submitted_vod__c = true;
                                }
                            }
                        Trigger.new[i].OwnerId = Trigger.new[i].Inventory_For_vod__c  ;
                        }
                            
                       if (Trigger.isDelete) {
                            if (Trigger.old[i].Status_vod__c == 'Submitted_vod') {
                                Trigger.old[i].Id.addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_TOUCH_SAMP_INV','TriggerError'), false);
                            }
                        }
                        
                    }
                
                }