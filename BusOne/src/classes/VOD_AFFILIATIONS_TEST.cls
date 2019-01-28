@isTest
public class VOD_AFFILIATIONS_TEST {
	public static testMethod void test_VOD_AFFILIATIONS () {
        System.assertEquals (VOD_AFFILIATIONS.getCount(), 0); 
        VOD_AFFILIATIONS.incCount();
        System.assertEquals (VOD_AFFILIATIONS.getCount(), 1);
        System.assertEquals (VOD_AFFILIATIONS.getAfilTrig(), false);
        System.assertEquals (VOD_AFFILIATIONS.getUpdAfilTrig(), false);   

        VOD_AFFILIATIONS.setAfilTrig(true);
        
        System.assertEquals (VOD_AFFILIATIONS.getCount(), 1);
        System.assertEquals (VOD_AFFILIATIONS.getAfilTrig(), true);
        System.assertEquals (VOD_AFFILIATIONS.getUpdAfilTrig(), false);
        
		VOD_AFFILIATIONS.setUpdAfilTrig(true);
        
        System.assertEquals (VOD_AFFILIATIONS.getCount(), 1);
        System.assertEquals (VOD_AFFILIATIONS.getAfilTrig(), true);
        System.assertEquals (VOD_AFFILIATIONS.getUpdAfilTrig(), true);
    }
}