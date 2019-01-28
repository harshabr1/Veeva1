trigger Affiliation_trigger_vod on Affiliation_vod__c bulk ( after insert, after delete, after update) {
                
                if (VOD_AFFILIATIONS.getAfilTrig() == true)
                   return;
                if (VOD_AFFILIATIONS.getUpdAfilTrig() == true)
                   return;
                /* If the Account Trigger is firing then it will delete both affiliations */
                if (VOD_ACCOUNT_TRIG.getAccountTrig()== true)
                   return;
                
                   VOD_AFFILIATIONS.setUpdAfilTrig(true);
                   VOD_AFFILIATIONS.setAfilTrig(true);    
                   List<Affiliation_vod__c > delList = new  List<Affiliation_vod__c >();
                   List<Affiliation_vod__c > insList = new  List<Affiliation_vod__c >();
                   List<Affiliation_vod__c > updList = new  List<Affiliation_vod__c >();
                   List<Boolean> disableTrigger;
                   if(Trigger.isDelete == false)
                       disableTrigger = VOD_AFFILIATIONS.getDisableTrigger();
                   
                   Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Affiliation_vod__c.fields.getMap();
                    
                   for (Integer i = 0; i < (Trigger.isDelete ? Trigger.old.size(): Trigger.new.size()); i++) {
                    
                       if (Trigger.isDelete) {
                          Affiliation_vod__c row = Trigger.old[i];
                          if (row.Child_affiliation_vod__c != null) {
                              Affiliation_vod__c delObject = new Affiliation_vod__c (ID = row.Child_affiliation_vod__c);
                              delList.add (delObject);
                          }
                        }
                       else if (Trigger.isInsert) {
                          if(disableTrigger.size() > i && disableTrigger[i]==true)
                              continue;
                               
                          Affiliation_vod__c row = Trigger.new[i];
                          Affiliation_vod__c newrow = new Affiliation_vod__c ( From_Account_vod__c = row.To_Account_vod__c,
                                                                           From_Contact_vod__c = row.To_Contact_vod__c,
                                                                           To_Account_vod__c   = row.From_Account_vod__c,
                                                                           To_Contact_vod__c   = row.From_Contact_vod__c,
                                                                           Comments_vod__c            = row.Comments_vod__c,
                                                                           Role_vod__c             = row.Role_vod__c,
                                                                           Therapeutic_Area_vod__c    = row.Therapeutic_Area_vod__c,
                                                                           Relationship_Strength_vod__c    = row.Relationship_Strength_vod__c,
                                                                           Child_affiliation_vod__c = row.Id);
                    
                          if (row.Influence_vod__c == 'Has influence') {
                             newrow.Influence_vod__c = 'Is influenced';
                          }
                          else if (row.Influence_vod__c == 'Is influenced') {
                             newrow.Influence_vod__c = 'Has influence';
                          }
                          
                          //update custom picklists/multi-selects that start with zvod_
                          for (String fieldName : fieldMap.keyset()) {
                              if (fieldName.startsWith('zvod_')) {
                                  Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
                                  if (field.getType() == Schema.DisplayType.Picklist || field.getType() == Schema.DisplayType.Multipicklist) {
                                      newrow.put(fieldName, row.get(fieldName));
                                  }
                              }
                          } 
                          insList.add(newrow);   
                                                                            
                       } 
                     else if (Trigger.isUpdate)
                     {
                        if(disableTrigger.size() > i && disableTrigger[i]==true)
                            continue;

                        Affiliation_vod__c oldrowupd = Trigger.old[i];
                        Affiliation_vod__c newrowupd = Trigger.new[i];
                        if (newrowupd.destroy_vod__c == true) {
                                Affiliation_vod__c delfromupdate  = new Affiliation_vod__c (Id = newrowupd.Id);
                                delList.add(delfromupdate);
                                if (newrowupd.Child_affiliation_vod__c != null) {
                                   Affiliation_vod__c delObject = new Affiliation_vod__c (ID = newrowupd.Child_affiliation_vod__c);
                                   delList.add (delObject);
                                }
                                continue;
                        }       
                        Affiliation_vod__c updrow = new Affiliation_vod__c (Id = newrowupd.Child_affiliation_vod__c,
                                                                            Comments_vod__c  = newrowupd.Comments_vod__c,
                                                                            Role_vod__c    = newrowupd.Role_vod__c,
                                                                            Therapeutic_Area_vod__c = newrowupd.Therapeutic_Area_vod__c,
                                                                            Relationship_Strength_vod__c = newrowupd.Relationship_Strength_vod__c);
                        
                        if (newrowupd.Influence_vod__c == 'Has influence') {
                            updrow.Influence_vod__c = 'Is influenced';
                        }
                        else if (newrowupd.Influence_vod__c == 'Is influenced') {
                            updrow.Influence_vod__c = 'Has influence';
                        } else if (newrowupd.Influence_vod__c == 'No influence') {
                            updrow.Influence_vod__c = 'No influence';
                        } else {
                            updrow.Influence_vod__c = null;
                        }

                        //update custom picklists/multi-selects that start with zvod_
                        for (String fieldName : fieldMap.keyset()) {
                            if (fieldName.startsWith('zvod_')) {
                                Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
                                if (field.getType() == Schema.DisplayType.Picklist || field.getType() == Schema.DisplayType.Multipicklist) {
                                    updrow.put(fieldName, newrowupd.get(fieldName));
                                }
                            }
                        } 
                          
                        updList.add(updrow);
                     }
                       
                   }
                 if (Trigger.isInsert) {
                    if (insList.size() > 0) {
                        try {
                            insert insList;
                        } catch (System.DmlException e){
                            for (Integer i = 0; i < e.getNumDml(); i++) {
                                // Process exception here
                                Id id  = e.getDmlId(i);
                                if (id == null)
                                    continue;
                                Affiliation_vod__c afilError = Trigger.newMap.get(id);
                                if (afilError == null)
                                    continue;
                                System.debug(e.getDmlMessage(i));
                                afilError.Id.addError(e.getDmlMessage(i), false);
                            }               
                        }
                                
                    for (Integer up = 0; up < insList.size(); up++) {
                            Affiliation_vod__c uprow = insList[up];
                            Affiliation_vod__c upd = new Affiliation_vod__c (Id = uprow.Child_affiliation_vod__c,
                                                                             Child_affiliation_vod__c = uprow.Id,
                                                                             Parent_vod__c = true);
                            updList.add(upd);
                        }
                        update updList; 
                    }   
                 } else if(Trigger.isDelete) {
                    if (delList.size() > 0) {
                        try {
                            delete delList;
                        } catch (System.DmlException e) {
                           //do nothing.
                        }
                    }
                 }
                 else if(Trigger.isUpdate) {
                    if (updList.size() > 0) {
                        
                    try {   
                        update updList;
                    
                    } catch (System.DmlException e){
                            for (Integer i = 0; i < e.getNumDml(); i++) {
                                // Process exception here
                                Id id  = e.getDmlId(i);
                                if (id == null)
                                    continue;
                                Affiliation_vod__c afilError = Trigger.newMap.get(id);
                                if (afilError == null)
                                    continue;
                                System.debug(e.getDmlMessage(i));
                                afilError.Id.addError(e.getDmlMessage(i), false);
                            }               
                        }
                    
                    }
                    if (delList.size() > 0) {
                        try {
                            delete delList;
                        } catch (System.DmlException e) {
                           //do nothing.
                        }
                    }
                 }
                }