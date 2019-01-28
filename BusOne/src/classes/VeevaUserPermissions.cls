// THIS CLASS MUST BE DEPLOYED WITH API 25 OR HIGHER.
// While this class still builds and runs with API versions 22-24, the queries used only directly accesses the Profile's granted
// permissions when the API version is set to 25 or higher.

// See http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_permissionset.htm:
// In API version 25 and later, every profile is associated with a permission set that stores the profile’s user, object, and field permissions,
// as well as setup entity access settings. Permission sets that are owned by profiles can be queried but not modified.

global class VeevaUserPermissions{
    webService static List<String> listPermissionSets() {
        final String assignee = UserInfo.getUserId();
        List<PermissionSetAssignment> assignments = [SELECT PermissionSetId FROM PermissionSetAssignment
            WHERE AssigneeId = :assignee
            ORDER BY PermissionSetId ASC];

        List<String> result = new List<String>();
        for(PermissionSetAssignment assignment : assignments) {
            result.add(assignment.PermissionSetId);
        }

        return result;
    }

    webService static boolean checkPermission(final String permissionName) {
        final String assignee = UserInfo.getUserId();
        final String permissionColumnName = 'Permissions' + String.escapeSingleQuotes(permissionName);

        final String query = 'Select COUNT() FROM PermissionSet ' +
            'WHERE Id IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :assignee) AND ' +
            permissionColumnName + ' = true';

        // Return true if the user has at least one PermissionSet (including the profile's) that grants this permission
        try {
            return Database.countQuery(query) != 0;
        } catch(System.QueryException e) {
            return false;
        }
    }
}