public class VOD_ERROR_MSG_BUNDLE2 {
            
            Map<String, Map <String,String>> languagesMap  = 
                   new Map <String, Map <String,String>> ();
                   
             
             public VOD_ERROR_MSG_BUNDLE2 () {
                
                String userLang = UserInfo.getLanguage();   
             
                Map <String,String> baseLang = 
                    new Map <String,String> ();
                
                baseLang.put ('DEL_KEY_MSG','You cannot delete this object because some call report references it.');
                baseLang.put ('DEL_PROD_STRAT','You cannot delete this object because some call report references it.');
                baseLang.put ('MUST_HAVE_FROM','You must specify a From Account or From Contact.');
                baseLang.put ('MUST_HAVE_TO','You must specify a To Account or To Contact.');
                baseLang.put ('NO_DEL_ACCOUNT','This account cannot be deleted. Accounts with saved calls cannot be deleted.');
                baseLang.put ('NO_DEL_CONTACT','You cannot delete this object because some call report references it.');
                baseLang.put ('NO_DEL_MEDEVENT','You cannot delete this object because some call report references it.');
                baseLang.put ('NO_DEL_SUB','You may not delete a submitted call or any of the supporting data.');
                baseLang.put ('NO_UPD_SUB','You may not update a submitted call or any of the supporting data.');
                baseLang.put ('NO_FUTURE_SUBMIT','Submission of future calls not allowed.');
                baseLang.put ('NO_TOUCH_EVE','This event is associated with a submitted call, it cannot be updated or deleted.');
                baseLang.put ('NO_TOUCH_EVE_INPROG','This event is associated with a in-progress call, it cannot be deleted.');
                baseLang.put ('NO_UPD_SUB','You may not update a submitted call or any of the supporting data.');
                baseLang.put ('ONLY_ONE_FROM','Only one From Account or From Contact is allowed.');
                baseLang.put ('ONLY_ONE_TO','Only one To Account or To Contact is allowed.');
                baseLang.put ('Unable_To_Add_Event','Unable to add Doctor Call Event.  Please contact you administrator to verify your profile has access to add Doctor Calls.');
                baseLang.put ('NO_DEL_SAMPLOT_W_TRAN','This Sample Lot cannot be deleted. Sample Lots with disbursements may not be deleted.');
                baseLang.put ('NO_DEL_CALL_W_TRAN','This call cannot be deleted. Calls with submitted disbursements may not be deleted.');
                baseLang.put ('NO_DEL_ADDRESS','This address cannot be deleted. Addresses with saved or submitted calls cannot be deleted.');
                baseLang.put ('NO_TOUCH_SAMP_INV','The Inventory item that you are attempting to modify has been previously submitted and is read-only. Any modifications to the record have not been saved. Please click on the Cancel button or navigate from your current page.');
                baseLang.put ('NO_TOUCH_SAMP_TRAN','The transaction that you are attempting to modify has been previously submitted and is read-only. Any modifications to the record have not been saved. Please click on the Cancel button or navigate from your current page.');
                baseLang.put ('COL_PRE_MAP','This Column has been previously maped for this data map template. Please modify the column number in order to save.');
                baseLang.put ('NO_DUP_COL_OR_PPLAN','There can be only one Column Label\\Payer/Plan Mapped combination in production at a time. Please modify the Column Label or Payer/Plan Mapped in order to save.');
                baseLang.put ('LIMIT_AFFIL_MSG','The Affiliation object requires a batch size of 50 or smaller.  Please reset the batch size and try again.');
                baseLang.put ('AFFIL_NO_UPD_ENT','Error: The Account and Contact fields cannot be updated. Please delete the current Affiliation and create a new Affiliation between the desired entities.');
                baseLang.put ('CANNOT_UPD_INQ','Cannot update a submitted inquiry');
                baseLang.put ('CANNOT_DEL_INQ','Cannot Delete a locked Medical Inquiry');
                baseLang.put ('ONLY_ONE_NAME_DT','There can be only one active Data Template with the name :');
                baseLang.put ('ADDRESS_UPD_LOCK_MSG','Address cannot be updated.');
                baseLang.put ('ADDRESS_DEL_LOCK_MSG','Address cannot be deleted.');
                baseLang.put ('ADDRESS_PRIMARY_MSG','A primary address cannot be marked inactive.');
                baseLang.put ('DUP_AFFIL','The affiliation cannot be saved because the affiliation already exists. Please modify the existing affiliation.');
                baseLang.put ('DEL_PRODUCT','You cannot delete this object because some call report references it.');
                baseLang.put ('UPD_SAMPORDER','Cannot update a submitted Sample Order.');
                baseLang.put ('DEL_SAMPORDER','Cannot delete a submitted Sample Order.');
                baseLang.put ('NO_CREATE_NO_LOT_VOD','You cannot create No_Lot_vod for the selected product type.');

        
        
                languagesMap.put ('base', baseLang);
                
                if (userLang == 'es') {
                    //spanish
                } else if (userLang == 'fr') {
                    //french
                    
                }
                
             }
             
             public String getErrorMsg (String Key) {
                String userLang = UserInfo.getLanguage();   
                Map <String,String> base = languagesMap.get ('base');
                Map <String,String> user = languagesMap.get (userLang);
                String msg = null;
                
                if (user != null) {
                    msg = user.get (Key);
                }
                
                if (msg == null )  {
                    msg = base.get (Key);   
                }
                
                if (msg == null)
                    msg  ='An error has occurred.';
                    
                return msg;
             }
            
        }