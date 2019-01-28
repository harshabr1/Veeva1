public class VOD_VALIDATION_CONTROLLER {

    public VOD_VALIDATION_CONTROLLER(ApexPages.StandardController controller) {
    }

    public VOD_VALIDATION_CONTROLLER() {
    }
    
    public static String getValidationRuleAdminConsole() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault(
            'VALIDATIONRULE_ADMIN_CONSOLE', 'ValidationRule', 'Validation Rule Admin Console');
    }

    public String getExtraParams() {
        return '&motif=Custom5Tab';
    }
    
    public static String getTitle() {
        return 'Veeva CRM Online';
    }
    
    public static String getVodUrl () {
        return VOD_Common.VOD_URL;
    }
}