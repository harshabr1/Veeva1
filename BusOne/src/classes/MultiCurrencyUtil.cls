public class MultiCurrencyUtil {  
	//Protected Members
    private static MultiCurrencyUtil instance;
    private static Boolean multiCurrencyEnabled = Schema.getGlobalDescribe().containsKey('CurrencyType');

    //Properties
    public final Map<string, SObject> IsoCurrencyTypes;

    //Constructors
    private MultiCurrencyUtil() {
        IsoCurrencyTypes = getCurrencyTypesByIsoCode();
    }

    //Static Methods
    public static MultiCurrencyUtil getInstance() {
        if (instance == null) {
            instance = new MultiCurrencyUtil();
        }

        return instance;
    }
    
    public static boolean isMultiCurrencyOrg() {
        return multiCurrencyEnabled;
    }

    public static decimal convertCurrency(string fromIsoCode, string toIsoCode, decimal value) {
        MultiCurrencyUtil util = MultiCurrencyUtil.getInstance();
        decimal convertedValue = value;

        boolean conversionRequired = (fromIsoCode != toIsoCode && value != null);
        boolean fromIsoCodeValid = util.IsoCurrencyTypes.containsKey(fromIsoCode);
        boolean toIsoCodeValid = util.IsoCurrencyTypes.containsKey(toIsoCode);

        if (conversionRequired && fromIsoCodeValid && toIsoCodeValid) {
            SObject fromCurrencyType = util.IsoCurrencyTypes.get(fromIsoCode);
            convertedValue = value / (Double)fromCurrencyType.get('ConversionRate');

            SObject toCurrencyType = util.IsoCurrencyTypes.get(toIsoCode);
            convertedValue = convertedValue * (Double)toCurrencyType.get('ConversionRate');
        }

        return convertedValue;
    }

    //Private Methods
    private Map<string, SObject> getCurrencyTypesByIsoCode() {
        Map<string, SObject> currencyTypesByIsoCode = new Map<string, SObject>();
        if(multiCurrencyEnabled) {
        	List<SObject> currencyTypes = queryCurrencyTypes();
            for (SObject currencyType : currencyTypes) {
                currencyTypesByIsoCode.put((String)currencyType.get('IsoCode'), currencyType);
            }	
        } 
        
        return currencyTypesByIsoCode;
    }

    //Query Methods
    private List<SObject> queryCurrencyTypes() {
        return Database.query('SELECT Id, IsoCode, ConversionRate, IsCorporate FROM CurrencyType');
    }    
    
    public static String toCommaSeperated(Set<Id> ids) {
        String result = '(';
        List<Id> idList = new List<Id>();
        idList.addall(ids);

        for(Integer ndx = 0; ndx < idList.size(); ndx++) {
            Id currentId = idList.get(ndx);
            result += '\'' + currentId + '\'';
            if(ndx+1 < idList.size()) {
                result += ',';
            }
        }
        
        result += ')';
        return result;
    }
}