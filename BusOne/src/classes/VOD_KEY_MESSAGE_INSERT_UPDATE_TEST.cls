@isTest
public class VOD_KEY_MESSAGE_INSERT_UPDATE_TEST {

    public static final String INSERT_NAME = 'TestInsert';
    public static final String UPDATE_NAME = 'TestUpdate';
    public static final String INSERT_FILE = 'insertFile';
    public static final String UPDATE_FILE = 'updateFile';
    public static final String NEW_UPDATE_FILE = 'newUpdateFile';
    public static final String INSERT_ID = 'insertID';
    public static final String UPDATE_ID = 'updateID';
    public static final String NEW_UPDATE_ID = 'newUpdateID';
    public static final String CLM_ID = 'CLM ID';


    static testMethod void testInsertNewKeyMessageNoCLMId() {
        Key_Message_vod__c kMsg = createKeyMessageNoCLMId(INSERT_NAME, INSERT_FILE);

        System.Test.startTest();
        insert kMsg;
        System.Test.stopTest();

        Key_Message_vod__c msg = getKeyMessage(kMsg);

        System.assertEquals(msg.CLM_ID_vod__c, CLM_ID);

    }

    static testMethod void testInsertNewKeyMessageWithCLMId() {
        Key_Message_vod__c kMsg = createKeyMessageWithCLMId(INSERT_NAME, INSERT_FILE, INSERT_ID);

        System.Test.startTest();
        insert kMsg;
        System.Test.stopTest();

        Key_Message_vod__c msg = getKeyMessage(kMsg);

        System.assertNotEquals(msg.CLM_ID_vod__c, CLM_ID);
        System.assertEquals(msg.CLM_ID_vod__c, INSERT_ID);

    }

    static testMethod void testInsertNewKeyMessageNoMediaFile() {
        Key_Message_vod__c kMsg1 = createKeyMessageNoMediaFile(INSERT_NAME + 1, INSERT_ID);
        Key_Message_vod__c kMsg2 = createKeyMessage(INSERT_NAME + 2);

        List<Key_Message_vod__c> toInsert = new List<Key_Message_vod__c>{kMsg1, kMsg2};

        System.Test.startTest();
        insert toInsert;
        System.Test.stopTest();

		Map<ID, Key_Message_vod__c> toCheck = getKeyMessages(toInsert);

        System.assertNotEquals(toCheck.get(kMsg1.Id).CLM_ID_vod__c, CLM_ID);
        System.assertEquals(toCheck.get(kMsg1.Id).CLM_ID_vod__c, INSERT_ID);

        System.assertNotEquals(toCheck.get(kMsg2.Id).CLM_ID_vod__c, CLM_ID);
    }

    static testMethod void testUpdateKeyMessageNoCLMId() {
        Key_Message_vod__c kMsg = createKeyMessage(UPDATE_NAME);

        System.Test.startTest();
        insert kMsg;
        kMsg.Media_File_Name_vod__c = UPDATE_FILE;
        update kMsg;
        System.Test.stopTest();

        Key_Message_vod__c msg = getKeyMessage(kMsg);

        System.assertEquals(msg.Media_File_Name_vod__c, UPDATE_FILE);
        System.assertEquals(msg.CLM_ID_vod__c, CLM_ID);

    }

    static testMethod void testUpdateKeyMessageWithCLMId() {
        Key_Message_vod__c kMsg1 = createKeyMessageWithCLMId(UPDATE_NAME + 1, UPDATE_FILE + 1, UPDATE_ID + 1);
        Key_Message_vod__c kMsg2 = createKeyMessageWithCLMId(UPDATE_NAME + 2, UPDATE_FILE + 2, UPDATE_ID + 2);

        List<Key_Message_vod__c> toInsert = new List<Key_Message_vod__c>{kMsg1, kMsg2};

        System.Test.startTest();
        insert toInsert;
        toInsert.get(0).Media_File_Name_vod__c = NEW_UPDATE_FILE;
        toInsert.get(1).CLM_ID_vod__c= NEW_UPDATE_ID;
        update toInsert;
       	System.Test.stopTest();

        Map<ID, Key_Message_vod__c> toCheck = getKeyMessages(toInsert);

        System.assertEquals(toCheck.get(kMsg1.Id).Media_File_Name_vod__c, NEW_UPDATE_FILE);
        System.assertNotEquals(toCheck.get(kMsg1.Id).CLM_ID_vod__c, CLM_ID);
        System.assertEquals(toCheck.get(kMsg1.Id).CLM_ID_vod__c, UPDATE_ID + 1);

        System.assertNotEquals(toCheck.get(kMsg2.Id).CLM_ID_vod__c, CLM_ID);
        System.assertEquals(toCheck.get(kMsg2.Id).CLM_ID_vod__c, NEW_UPDATE_ID);

    }

    static testMethod void testUpdateKeyMessageNoMediaFileWithCLMId() {
        Key_Message_vod__c kMsg = createKeyMessageNoMediaFile(UPDATE_NAME, UPDATE_ID);

        System.Test.startTest();
        insert kMsg;
        kMsg.Media_File_Name_vod__c = UPDATE_FILE;
        update kMsg;
        System.Test.stopTest();

        Key_Message_vod__c msg = getKeyMessage(kMsg);

        System.assertEquals(msg.Media_File_Name_vod__c, UPDATE_FILE);
        System.assertNotEquals(msg.CLM_ID_vod__c, CLM_ID);
        System.assertEquals(msg.CLM_ID_vod__c, UPDATE_ID);
    }

    static testMethod void testKeyMessageBatchInsert() {
        List<Key_Message_vod__c> toInsert = new List<Key_Message_vod__c>();
        for(Integer i = 0; i < 50; i++) {
            if(math.mod(i, 2) == 0) {
                toInsert.add(createKeyMessageNoCLMId(INSERT_NAME + i, INSERT_FILE + i));
            } else {
                toInsert.add(createKeyMessageWithCLMId(INSERT_NAME + i, INSERT_FILE + i, INSERT_ID + i));
            }
        }

        System.Test.startTest();
        insert toInsert;
        System.Test.stopTest();

        Map<ID, Key_Message_vod__c> toCheck = getKeyMessages(toInsert);

        for(Integer i = 0; i < 50; i++) {
            if(math.mod(i, 2) == 0) {
                System.assertEquals(toCheck.get(toInsert.get(i).Id).CLM_ID_vod__c, CLM_ID);
            } else {
                System.assertEquals(toCheck.get(toInsert.get(i).Id).CLM_ID_vod__c, INSERT_ID + i);
            }
        }

    }

    static testMethod void testKeyMessageBatchUpdate() {
        List<Key_Message_vod__c> toInsert = new List<Key_Message_vod__c>();
        for(Integer i = 0; i < 50; i++) {
            if(math.mod(i, 2) == 0) {
                toInsert.add(createKeyMessage(UPDATE_NAME + i));
            } else {
                toInsert.add(createKeyMessageNoMediaFile(UPDATE_NAME + i, UPDATE_ID + i));
            }
        }

        System.Test.startTest();
        insert toInsert;
        for(Integer i = 0; i < 50; i++) {
            toInsert.get(i).Media_File_Name_vod__c = UPDATE_FILE + i;
        }
        update toInsert;
        System.Test.stopTest();

        Map<ID, Key_Message_vod__c> toCheck = getKeyMessages(toInsert);

        for(Integer i = 0; i < 50; i++) {
            System.assertEquals(toCheck.get(toInsert.get(i).Id).Media_File_Name_vod__c, UPDATE_FILE + i);
            if(math.mod(i, 2) == 0) {
                System.assertEquals(toCheck.get(toInsert.get(i).Id).CLM_ID_vod__c, CLM_ID);
            } else {
                System.assertNotEquals(toCheck.get(toInsert.get(i).Id).CLM_ID_vod__c, CLM_ID);
                System.assertEquals(toCheck.get(toInsert.get(i).Id).CLM_ID_vod__c, UPDATE_ID + i);
            }
        }
    }

    static Key_Message_vod__c getKeyMessage(Key_Message_vod__c msg) {
        return [SELECT Id, Name, Media_File_Name_vod__c, CLM_ID_vod__c FROM Key_Message_vod__c WHERE Id = :msg.Id];
    }

    static Map<Id, Key_Message_vod__c> getKeyMessages(List<Key_Message_vod__c> kMsgList) {
        List<Key_Message_vod__c> myList = [SELECT Id, Name, Media_File_Name_vod__c, CLM_ID_vod__c FROM Key_Message_vod__c WHERE Id IN :kMsgList];
        Map<Id, Key_Message_vod__c> myMap = new Map<Id, Key_Message_vod__c>();
        for(Key_Message_vod__c k : myList) {
            myMap.put(k.Id, k);
        }
        return myMap;
    }

    static Key_Message_vod__c createKeyMessageNoCLMId(String name, String mediaFile) {
        return new Key_Message_vod__c(Name=name, Media_File_Name_vod__c=mediaFile);
    }

    static Key_Message_vod__c createKeyMessageWithCLMId(String name, String mediaFile, String clmId) {
        return new Key_Message_vod__c(Name=name, Media_File_Name_vod__c=mediaFile, CLM_ID_vod__c=clmId);
    }

    static Key_Message_vod__c createKeyMessageNoMediaFile(String name, String clmId) {
        return new Key_Message_vod__c(Name=name, CLM_Id_vod__c=clmId);
    }

    static Key_Message_vod__c createKeyMessage(String name) {
        return new Key_Message_vod__c(Name=name);
    }
}