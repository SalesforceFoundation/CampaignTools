public with sharing class AutocompleteController {

    @AuraEnabled
    public static List<sObject> getSuggestions(String sObjectType, String term, String fieldsToGet, Integer limitSize) {
        // Determine if user has read access to sObjectType
        Schema.DescribeSObjectResult dsor = getSObjectDescribe(sObjectType);
        if (!userCanReadSObject(dsor)) {
            return new List<sObject>();
        }

        Set<String> accessibleFields = new Set<String>();

        // Determine if user has read access to Name field
        if (!userCanReadSobjectField(dsor, 'Name')) {
            return new List<sObject>();
        }
        accessibleFields.add('Name');

        // Determine if user has read access to each additional requested field
        List<String> fieldsList = fieldsToGet.split('.');
        for (String field : fieldsList) {
            if (userCanReadSobjectField(dsor, field.trim())) {
                accessibleFields.add(field.trim());
            }
        }

        String soql = 
            ' SELECT ' + String.join(new List<String>(accessibleFields), ', ') +
            ' FROM '   + sObjectType +
            ' WHERE Name Like \'%' + String.escapeSingleQuotes(term) + '%\'' +
            ' ORDER By Name ' +
            ' LIMIT ' + limitSize;
        return Database.query(soql);
    }

    public static Schema.DescribeSObjectResult getSObjectDescribe(String sObjectType) {
        List<Schema.DescribeSObjectResult> dsors = Schema.describeSObjects(new List<String>{sObjectType});
        if (!dsors.isEmpty()) {
            Schema.DescribeSObjectResult dsor = dsors.get(0);
            if (dsor.getName() == sObjectType) {
                return dsor;
            }
        }
        return null;
    }

    public static Boolean userCanReadSObject(Schema.DescribeSObjectResult dsor) {
        if (dsor == null) {
            return false;
        } else {
            return dsor.isAccessible();
        }
    }

    public static Boolean userCanReadSobjectField(Schema.DescribeSObjectResult dsor, String fieldName) {
        if (dsor == null) {
            return false;
        } else {
            Map<String, Schema.SObjectField> sofs = dsor.fields.getMap();
            if (!sofs.containsKey(fieldName)) { // warning, case sensitive
                return false;
            } else {
                return sofs.get(fieldName).getDescribe().isAccessible();
            }
        }
    }
}