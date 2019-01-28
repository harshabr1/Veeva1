trigger VOD_ADDRESS_VOD_BEFORE on Address_vod__c (before insert, before update) {
     
    String ProfileId = UserInfo.getProfileId();
    VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
    Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
    boolean modAllData = false;
    if (pr != null && pr.PermissionsModifyAllData)
        modAllData = true;
    
    
    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Address_vod__c.fields.getMap();
    Schema.SObjectField Lock_vod = fieldMap.get('Lock_vod__c');
    Boolean lock = false;
    if (Lock_vod != null) {
        lock = true;
    }
    
    boolean networkAdminUser = false;
    Schema.SObjectField netAdminFld = Schema.SObjectType.User.fields.getMap().get('Network_Admin_vod__c');
    if (netAdminFld != null) {
    	String userId = UserInfo.getUserId();
        List<SObject> thisUser = Database.query('Select Network_Admin_vod__c From User Where Id = :userId');
        if ((thisUser != null) && (thisUser.size() > 0)) {
        	if (thisUser[0].get(netAdminFld) == true) {
				networkAdminUser = true;
			}
		}
	}

    for (Integer i = 0 ; i < Trigger.new.size(); i++) {
        if (Trigger.new[i].No_Address_Copy_vod__c == true  && !networkAdminUser) {
            VOD_ADDRESS_TRIG.addCopySetFalse(Trigger.new[i].Id);
            Trigger.new[i].No_Address_Copy_vod__c = false;
        } 
        
        if (Trigger.isUpdate && !networkAdminUser) {
            if (Trigger.new[i].Controlling_Address_vod__c != null ) {
                if (Trigger.new[i].Name != Trigger.old[i].Name) {
                    if (VOD_ADDRESS_TRIG.getPush() == false) {
                        Trigger.new[i].Name.addError(bundle.getErrorMsg ('ADDRESS_UPD_LOCK_MSG'), false);
                    }
                }
            }
        }
        Address_vod__c add_c_new = Trigger.new[i];
        if (Trigger.isInsert == true && add_c_new.Entity_Reference_Id_vod__c != null && 
            add_c_new.Entity_Reference_Id_vod__c.length() > 0) {
                add_c_new.Account_vod__c = add_c_new.Entity_Reference_Id_vod__c;
                add_c_new.Entity_Reference_Id_vod__c = null;
            }
        
        if ((add_c_new.Controlled_Address_vod__c == true) && (add_c_new.External_ID_vod__c == null) && !networkAdminUser) {
            //CRM-15460
            //this needs to be after the Account_vod__c that is assigned, for mobile devices
            add_c_new.External_ID_vod__c = add_c_new.Account_vod__c + '_' + add_c_new.Controlling_Address_vod__c;
        }
                
        Schema.DescribeFieldResult clearGpsCoordinatesField = Address_vod__c.Clear_GPS_Coordinates_vod__c.getDescribe();
        // get the default Clear GPS Coordinates value for use later
        Boolean defaultClearGpsCoordinatesValue = (Boolean) clearGpsCoordinatesField.getDefaultValue();
        
        if (Trigger.isUpdate) {
            Address_vod__c add_c_old = Trigger.old[i];
            // only users with modify all data permissions or are a network admin user can change DEA addresses
            if (!modAllData && !networkAdminUser && add_c_old.DEA_Address_vod__c  == true) {
                if (add_c_old.Name != add_c_new.Name ||
                    add_c_old.City_vod__c != add_c_new.City_vod__c ||
                    add_c_old.State_vod__c != add_c_new.State_vod__c ||
                    add_c_old.Zip_vod__c != add_c_new.Zip_vod__c ||                                                 
                    add_c_old.Zip_4_vod__c != add_c_new.Zip_4_vod__c || 
                    add_c_old.Address_line_2_vod__c != add_c_new.Address_line_2_vod__c ||
                    add_c_old.DEA_Status_vod__c != add_c_new.DEA_Status_vod__c ||
                    add_c_old.DEA_vod__c != add_c_new.DEA_vod__c ||
                    add_c_old.DEA_Status_vod__c != add_c_new.DEA_Status_vod__c ||
                    add_c_old.DEA_Expiration_Date_vod__c != add_c_new.DEA_Expiration_Date_vod__c ||
                    add_c_old.DEA_Address_vod__c != add_c_new.DEA_Address_vod__c ||
                    add_c_old.DEA_Schedule_vod__c != add_c_new.DEA_Schedule_vod__c ||
                    add_c_old.ASSMCA_vod__c !=  add_c_new.ASSMCA_vod__c) {
                        Trigger.new[i].Name.addError(bundle.getErrorMsg ('NO_UPD_DEA_ADDRESS'), false);
                    }
            }
            // For Network rely on the values coming from Network, do not need to nullify Lat ,Long values
            if ( !networkAdminUser) {
                boolean latLongUpdated = false;
                boolean addressUpdated = false;
                if (add_c_old.Name != add_c_new.Name ||
                    add_c_old.City_vod__c != add_c_new.City_vod__c ||
                    add_c_old.State_vod__c != add_c_new.State_vod__c ||
                    add_c_old.Zip_vod__c != add_c_new.Zip_vod__c ||                                                 
                    add_c_old.Address_line_2_vod__c != add_c_new.Address_line_2_vod__c) {
                        addressUpdated = true;                     
                        if (add_c_old.Latitude_vod__c != add_c_new.Latitude_vod__c  || add_c_old.Longitude_vod__c != add_c_new.Longitude_vod__c) {
                            latLongUpdated = true;
                        } 
                }
                // If address is updated, but lat/long is not updated, clear the value and check to see if the clear_gps_coordinates_vod 
                // field is set, if they have access to it
                Boolean hasFieldAccess = clearGpsCoordinatesField.isAccessible();
                if (addressUpdated && !latLongUpdated && ((hasFieldAccess && add_c_new.Clear_GPS_Coordinates_vod__c) || !hasFieldAccess)) {
                    Trigger.new[i].Longitude_vod__c = null;
                    Trigger.new[i].Latitude_vod__c = null;
                }
            }    
                  
        }
        
        // be sure to set clear gps coordinates field to default value
        add_c_new.Clear_GPS_Coordinates_vod__c = defaultClearGpsCoordinatesValue;  
        
        if (Trigger.new[i].Inactive_vod__c == true && Trigger.new[i].Primary_vod__c == true && !networkAdminUser) {
            Trigger.new[i].Inactive_vod__c.addError(bundle.getErrorMsg ('ADDRESS_PRIMARY_MSG'), false);
        }
        
        if (Trigger.isUpdate) {
            if (Trigger.old[i].Name != Trigger.new[i].Name) {
                if (lock == true && !modAllData && !networkAdminUser) {
                    SObject obj = Trigger.new[i];
                    Boolean checkLock = (Boolean)obj.get('Lock_vod__c');
                    if (checkLock == true)
                        Trigger.new[i].Name.addError(bundle.getErrorMsg ('ADDRESS_UPD_LOCK_MSG'), false);
                }
            }
        }    
    }
}