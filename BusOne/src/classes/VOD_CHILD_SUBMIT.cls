public class VOD_CHILD_SUBMIT {
    private static boolean performSubmitCheckOnChild = true;
            
    public static boolean getPerformSubmitCheck () {
        return performSubmitCheckOnChild;
    }
    public static void setSubmitCheck (boolean bVal) {
        performSubmitCheckOnChild = bVal;
    }
}