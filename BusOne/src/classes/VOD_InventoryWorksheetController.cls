public with sharing class VOD_InventoryWorksheetController {

    private String userId = null;
    private User userDetails = null;
    private Rep_Roster_vod__c repRoster = null;
    private List<Territory> userTerritories = null;
    private List<Sample_Lot_vod__c> activeSamples = null;
    private List<Message_vod__c> messages = null;
    private Sample_Inventory_vod__c sampInvMaxDate = null;
    private List<Product_vod__c> productCatalog = null;

    public VOD_InventoryWorksheetController() {
        userId = ApexPages.currentPage().getParameters().get('USERID');
        if ((userId == null) || (userId == '')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'User id is not specified'));
            return;
        }
    }

    public void loadTerritoryNames() {
        if (userTerritories != null)
            return;

        try {
            userTerritories = [select Name from Territory where Id in (select TerritoryId
                from UserTerritory where UserId = :userId) order by Name];
        } catch (System.QueryException e) {
            userTerritories = new List<Territory>();
        }
    }

    public String getTerritoryNames() {
        loadTerritoryNames();

        String territoryNames = '';

        for (Integer i = 0; i < userTerritories.size(); i++) {
            if (i > 0)
                territoryNames += ', ';
            Territory territory = userTerritories.get(i);
            territoryNames += territory.Name;
        }

        return territoryNames;
    }

    public void loadActiveSamples() {
        if (activeSamples != null)
            return;

        try {
            activeSamples = [select Sample_vod__c, Name, Expiration_Date_vod__c, U_M_vod__c
                from Sample_Lot_vod__c
                where Product_vod__r.Product_Type_vod__c != 'BRC' and Active_vod__c = true AND OwnerId = :userId
                order by Sample_vod__c, Name];
        } catch (System.QueryException e) {
            activeSamples = new List<Sample_Lot_vod__c>();
        }

        for (Sample_Lot_vod__c sampleLot: activeSamples) {
            if ('No_Lot_vod'.equals(sampleLot.Name)) {
                sampleLot.Name = '';
            }
        }
    }

    public List<Sample_Lot_vod__c> getActiveSamples() {
        loadActiveSamples();

        return activeSamples;
    }

    public void loadSampInvMaxDate() {
        if (sampInvMaxDate != null)
            return;

        try {
           sampInvMaxDate = [select Submitted_Date_vod__c from Sample_Inventory_vod__c where OwnerId = :userId and Submitted_vod__c = true order by Submitted_Date_vod__c desc limit 1];
        } catch (System.QueryException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Sample inventory date not found'));
            return;
        }
    }

    public Sample_Inventory_vod__c getSampInvMaxDate() {
        loadSampInvMaxDate();

        return sampInvMaxDate;
    }

    public void loadUserDetails() {
        if (userDetails != null)
            return;

        userDetails = [select FirstName, LastName, EmployeeNumber from User where Id = :userId];
    }

    public User getUserDetails() {
        loadUserDetails();

        return userDetails;
    }

    public void loadRepRoster() {
        if (repRoster != null)
            return;

        try {
            repRoster = [select Zip_vod__c from Rep_Roster_vod__c where OwnerId = :userId];
        } catch (System.QueryException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Rep Roster details not found'));
            return;
        }
    }

    public Rep_Roster_vod__c getRepRoster() {
        loadRepRoster();

        return repRoster;
    }

    public void loadProductCatalog() {
        if (productCatalog != null)
            return;

        loadActiveSamples();

        String names = '';
        for (Integer i = 0; i < activeSamples.size(); i++) {
            Sample_Lot_vod__c activeSample = activeSamples.get(i);
            String name = activeSample.Sample_vod__c.replace('\'', '\\\'');
            if (i > 0)
                names += ', ';
            names += '\''+name+'\'';
        }

        String query = 'select Name, Company_Product_vod__c from Product_vod__c where Name in ('+names+')';

        productCatalog = Database.query(query);
    }

    public List<Product_vod__c> getProductCatalog() {
        loadProductCatalog();

        return productCatalog;
    }

    public void loadMessages() {
        if (messages != null)
            return;

        String language = UserInfo.getLanguage();

        messages = [select Name, Text_vod__c from Message_vod__c
            where Category_vod__c = 'SAMPLES_MGMT' and Language_vod__c = :language and Name IN ('INVENTORY_FOR', 'QTY')];
    }

    public String getInventoryForMessage() {
        return findMessage('INVENTORY_FOR');
    }

    public String getQuantityMessage() {
            return findMessage('QTY');
    }

    public String findMessage(String messageName) {
        loadMessages();

        String messageText = '';

        for (Integer i = 0; i < messages.size() ; i++) {
            Message_vod__c message = messages.get(i);
            if (message.Name == messageName)
                messageText = message.Text_vod__c;
        }

        return messageText;
    }
}