public class VEEVA_PROCESS_FLAGS {
  
    private static boolean updateCR = false;
            
    public static boolean getUpdateCR () {
        return updateCR;
    }
    public static void setUpdateCR (boolean bVal) {
        updateCR = bVal;
    }
    
    private static boolean updateTOT = false;
            
    public static boolean getUpdateTOT () {
        return updateTOT;
    }
    public static void setUpdateTOT (boolean bVal) {
        updateTOT = bVal;
    }
    
    private static boolean updateSIO = false;
    
    public static boolean getUpdateSIO () {
        return updateSIO;
    }
    public static void setUpdateSIO (boolean bVal) {
        updateSIO = bVal;
    }
}