public with sharing class VEEVA_PRINT_AOC_CONTROLLER {

    public VEEVA_PRINT_AOC_CONTROLLER(ApexPages.StandardSetController controller) {

    }

    public VEEVA_PRINT_AOC_CONTROLLER() {
    }

    public String getErrorMessage() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('NO_ROWS_SELECTED', 'COMMON', 'No row has been selected');
    }
}