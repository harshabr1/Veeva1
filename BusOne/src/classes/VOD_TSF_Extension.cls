public class VOD_TSF_Extension {
    private final Account acct;
    
    public VOD_TSF_Extension(ApexPages.StandardController controller) {
        this.acct = (Account)controller.getRecord();
    }

    public String getURL() {
        return VOD_Common.VOD_URL + 
                '?oType=tsf&ui=2&acctid=' +
                this.acct.Id +
                '&VER=' +
                VOD_Common.VOD_VERSION; 
    }
}