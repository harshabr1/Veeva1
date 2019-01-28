public class VOD_ERROR_MSG_BUNDLE {

   Map<String, Map <String,String>> languagesMap  =
           new Map <String, Map <String,String>> ();


   public VOD_ERROR_MSG_BUNDLE () {

      String userLang = UserInfo.getLanguage();

      Map <String,String> baseLang =
              new Map <String,String> ();

      baseLang.put ('DEL_KEY_MSG',System.Label.DEL_KEY_MSG);
      baseLang.put ('DEL_PROD_STRAT',System.Label.DEL_PROD_STRAT);
      baseLang.put ('MUST_HAVE_FROM',System.Label.MUST_HAVE_FROM);
      baseLang.put ('MUST_HAVE_TO', System.Label.MUST_HAVE_TO);
      baseLang.put ('NO_DEL_ACCOUNT',System.Label.NO_DEL_ACCOUNT);
      baseLang.put ('NO_DEL_CONTACT',System.Label.NO_DEL_CONTACT);
      baseLang.put ('NO_DEL_MEDEVENT',System.Label.NO_DEL_MEDEVENT);
      baseLang.put ('NO_DEL_SUB',System.Label.NO_DEL_SUB);
      baseLang.put ('NO_UPD_SUB',System.Label.NO_UPD_SUB);
      baseLang.put ('NO_FUTURE_SUBMIT',System.Label.NO_FUTURE_SUBMIT);
      baseLang.put ('NO_TOUCH_EVE',System.Label.NO_TOUCH_EVE);
      baseLang.put ('NO_TOUCH_EVE_INPROG',System.Label.NO_TOUCH_EVE_INPROG);

      baseLang.put ('ONLY_ONE_FROM',System.Label.ONLY_ONE_FROM);
      baseLang.put ('ONLY_ONE_TO',System.Label.ONLY_ONE_TO);
      baseLang.put ('Unable_To_Add_Event', System.Label.Unable_To_Add_Event);
      baseLang.put ('NO_DEL_SAMPLOT_W_TRAN', System.Label.NO_DEL_SAMPLOT_W_TRAN);
      baseLang.put ('NO_DEL_CALL_W_TRAN', System.Label.NO_DEL_CALL_W_TRAN);
      baseLang.put ('NO_DEL_ADDRESS', System.Label.NO_DEL_ADDRESS);
      baseLang.put ('NO_TOUCH_SAMP_INV', System.Label.NO_TOUCH_SAMP_INV);
      baseLang.put ('NO_TOUCH_SAMP_TRAN', System.Label.NO_TOUCH_SAMP_TRAN);
      baseLang.put ('COL_PRE_MAP', System.Label.COL_PRE_MAP);
      baseLang.put ('NO_DUP_COL_OR_PPLAN', System.Label.NO_DUP_COL_OR_PPLAN);
      baseLang.put ('LIMIT_AFFIL_MSG', System.Label.LIMIT_AFFIL_MSG);
      baseLang.put ('AFFIL_NO_UPD_ENT', System.Label.AFFIL_NO_UPD_ENT);
      baseLang.put ('CANNOT_UPD_INQ', System.Label.CANNOT_UPD_INQ);
      baseLang.put ('CANNOT_DEL_INQ', System.Label.CANNOT_DEL_INQ);
      baseLang.put ('ONLY_ONE_NAME_DT', System.Label.ONLY_ONE_NAME_DT);
      baseLang.put ('ADDRESS_UPD_LOCK_MSG', System.Label.ADDRESS_UPD_LOCK_MSG);
      baseLang.put ('ADDRESS_DEL_LOCK_MSG', System.Label.ADDRESS_DEL_LOCK_MSG);
      baseLang.put ('NO_DEL_LOCK_ADDRESS', System.Label.NO_DEL_LOCK_ADDRESS);
      baseLang.put ('ADDRESS_PRIMARY_MSG', System.Label.ADDRESS_PRIMARY_MSG);
      baseLang.put ('DUP_AFFIL', System.Label.DUP_AFFIL);
      baseLang.put ('DEL_PRODUCT', System.Label.DEL_PRODUCT);
      baseLang.put ('UPD_SAMPORDER', System.Label.UPD_SAMPORDER);
      baseLang.put ('DEL_SAMPORDER', System.Label.DEL_SAMPORDER);
      baseLang.put ('NO_MOD_ACCOUNT_NAME', System.Label.NO_MOD_ACCOUNT_NAME);
      baseLang.put ('NO_TOUCH_SAMP_TRAN_AUD', System.Label.NO_TOUCH_SAMP_TRAN_AUD);
      baseLang.put ('NO_TOUCH_SAMP_ORDER_TRAN_AUD', System.Label.NO_TOUCH_SAMP_ORDER_TRAN_AUD);
      baseLang.put ('NO_UPDATE_FIELD', System.Label.NO_UPDATE_FIELD);
      baseLang.put ('NO_DOUBLE_CONFIRM', System.Label.NO_DOUBLE_CONFIRM);
      baseLang.put ('NO_SIG_DEL', System.Label.NO_SIG_DEL);
      baseLang.put ('NO_DEL_ANA_MARKET', System.Label.NO_DEL_ANA_MARKET);
      baseLang.put ('NO_DEL_DEA_ADDRESS', System.Label.NO_DEL_DEA_ADDRESS);
      baseLang.put ('NO_DEL_PRIMARY_ADDRESS', System.Label.NO_DEL_PRIMARY_ADDRESS);
      baseLang.put ('NO_DEL_LAST_ADDRESS', System.Label.NO_DEL_LAST_ADDRESS);
      baseLang.put ('NO_DEL_ME_ADDRESS', System.Label.NO_DEL_ME_ADDRESS);
      baseLang.put ('NO_UPD_DEA_ADDRESS', System.Label.NO_UPD_DEA_ADDRESS);
      baseLang.put ('TRANSFER_TO_REQ', System.Label.TRANSFER_TO_REQ);
      baseLang.put ('NO_CREATE_NO_LOT_VOD', System.Label.NO_CREATE_NO_LOT_VOD);

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