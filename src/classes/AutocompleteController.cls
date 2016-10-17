public with sharing class AutocompleteController {
    @AuraEnabled
    public static List<ProviderResult> getSuggestions(String sObjectType, String term) {
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
                return new List<ProviderResult>();
            }

            // '%', '_', and '\' all are special characters in LIKE syntax.
            // We escape them here by prepending those characters with a backslash
            String preparedTerm = '%' + term.replaceAll('([%_\\\\])', '\\\\$0') + '%';
            String soql = 'SELECT Name FROM {0} WHERE Name LIKE :preparedTerm ORDER BY Name LIMIT 10';
            String query = String.format(soql, new List<String>{sObjectType});
            List<SObject> results = Database.query(query);
            List<ProviderResult> providerResults = new List<ProviderResult>();
    
            for (SObject so : results) {
                ProviderResult result = new ProviderResult();
                result.value = so.Id;
                result.label = (String) so.get('Name');
                providerResults.add(result);
            }

            return providerResults;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*******************************************************************************************************
    * @description helper class that holds the display string and sobject to return to the
    * autocomplete lightning component
    */
    public class ProviderResult {
        @AuraEnabled
        public String label;

        @AuraEnabled
        public Id value;
    }
}