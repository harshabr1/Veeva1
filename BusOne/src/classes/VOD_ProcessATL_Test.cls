@isTest
public class VOD_ProcessATL_Test {

    @isTest static void testUpdateAccountATLTracking() {
        if (VOD_ProcessATL.haveAccountATLTracking()) {
            DateTime testStart = DateTime.now();
            DateTime oldUpdate = testStart.addDays(-1);
            System.debug('Test Start='+testStart+' Old Update='+oldUpdate);
            Account[] accountsUpdated = new Account[4];
            Account[] accountsNotUpdated = new Account[4];
            for (Integer i=0; i < 4; i++) {
                accountsUpdated[i] = new Account();
                accountsUpdated[i].Name = 'Updated ' + i;
                accountsUpdated[i].put(VOD_ProcessATL.ATL_TRACKING_FIELD, oldUpdate);
                accountsNotUpdated[i] = new Account();
                accountsNotUpdated[i].Name = 'NotUpdated ' + i;
                accountsNotUpdated[i].put(VOD_ProcessATL.ATL_TRACKING_FIELD, oldUpdate);
            }
            System.debug('Inserting 8 records, half of which will later be updated.');
            insert accountsUpdated;
            insert accountsNotUpdated;
            
            Set<Id> acctIds = new Set<Id>();
            String idList = '';
            for (Account acct : accountsUpdated) {
                acctIds.add(acct.Id);
                idList = idList + ',\'' + acct.Id + '\'';
            }
            idList = idList.substring(1);
            idList = '(' + idList + ')';
            VOD_ProcessATL.updateAccountATLTracking(acctIds);
            
            System.debug('Making sure updated records were in fact updated');
            String queryBase = 'SELECT Id,' + VOD_ProcessATL.ATL_TRACKING_FIELD + ' FROM Account WHERE Id in ';
            Account[] read = Database.query(queryBase + idList);
            System.assertEquals(read.size(), accountsUpdated.size());
            DateTime reference = testStart.addSeconds(-1); // stored values lose millisecond precision.
            for (Account acct : read) {
                DateTime lastUpdate = (DateTime)acct.get(VOD_ProcessATL.ATL_TRACKING_FIELD);
                System.debug('Account update time=' + lastUpdate);
                System.assert(lastUpdate >= reference);
            }
            System.debug('Now making sure the other records were untouched');
            idList = '';
            for (Account acct : accountsNotUpdated) {
                idList = idList + ',\'' + acct.Id + '\'';
            }
            idList = idList.substring(1);
            idList = '(' + idList + ')';
            read = Database.query(queryBase + idList);
            System.assertEquals(read.size(), accountsNotUpdated.size());
            for (Account acct : read) {
                DateTime lastUpdate = (DateTime)acct.get(VOD_ProcessATL.ATL_TRACKING_FIELD);
                System.debug('Old update time=' + lastUpdate); 
                // Again, stored value may not be exactly equal to set value, due to precision loss.
                System.assert( lastUpdate <= oldUpdate);
            }
        } else {
            System.debug('Skipping unit test - tracking field not visible');
        }
    }
    
    @isTest static void testHaveAccountATLTracking() {
        Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
        settings.ATL_LAST_UPDATE_TRACKING_vod__c = true;
        upsert settings;
        
        System.assert(VOD_ProcessATL.haveAccountATLTracking());
        
        settings.ATL_LAST_UPDATE_TRACKING_vod__c = false;
        upsert settings;
        System.assert( ! VOD_ProcessATL.haveAccountATLTracking() );
    }
}