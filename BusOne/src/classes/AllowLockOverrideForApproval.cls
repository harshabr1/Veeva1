public class AllowLockOverrideForApproval {
    private static Set<ID> overridableIds = new Set<ID>();
    
    private AllowLockOverrideForApproval() {}
    
    public static void allowOrderToBeOverridable(ID id) {
        overridableIds.add(id);
    }
    
    public static void revokeAllowOrderToBeOverridable(ID id) {
        overridableIds.remove(id);
    }
    
    public static boolean orderIsOverridable(ID id) {
        return overridableIds.contains(id); 
    }
    
    public static void revokeAllAllowOrderToBeOverridable() {
    	overridableIds.clear();
    }
}