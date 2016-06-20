public with sharing class AutocompleteController {
    @AuraEnabled
    public static List<sObject> getSuggestions(String sObjectType, String term) {
        try {
            Boolean objectAccessible = false;
            Boolean nameFieldAccessible = false;

            if (sObjectType == 'Campaign') {
                objectAccessible = Campaign.sObjectType.getDescribe().isAccessible();
                nameFieldAccessible = Campaign.Name.getDescribe().isAccessible();
            } else if (sObjectType == 'Report') {
                objectAccessible = Report.sObjectType.getDescribe().isAccessible();
                nameFieldAccessible = Report.Name.getDescribe().isAccessible();
            }

            if (!objectAccessible || !nameFieldAccessible) {
                return new List<sObject>();
            }

            // '%', '_', and '\' all are special characters in LIKE syntax.
            // We escape them here by prepending those characters with a backslash
            String preparedTerm = '%' + term.replaceAll('([%_\\\\])', '\\\\$0') + '%';
            String soql = 'SELECT Name FROM {0} WHERE Name LIKE :preparedTerm ORDER BY Name LIMIT 10';
            String query = String.format(soql, new List<String>{sObjectType});
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}