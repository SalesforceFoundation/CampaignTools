@isTest
private class Mutex_TEST {
    private static testMethod void testConstructorValidField() {
        Campaign c = new Campaign(Name = 'My Test Campaign');
        insert c;
        
        Boolean exceptionThrown = false;
        
        try {
            Mutex campaignMutex = new Mutex(c.Id, Campaign.Campaign_List_Mutex__c);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        System.assert(!exceptionThrown);
    }
    
    private static testMethod void testConstructorNonModifiableField() {
        Campaign c = new Campaign(Name = 'My Test Campaign');
        insert c;
        
        Boolean exceptionThrown = false;
        
        try {
            Mutex campaignMutex = new Mutex(c.Id, Campaign.SystemModstamp);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        System.assert(exceptionThrown);
    }

    private static testMethod void testConstructorNotDateTimeField() {
        Campaign c = new Campaign(Name = 'My Test Campaign');
        insert c;
        
        Boolean exceptionThrown = false;
        
        try {
            Mutex campaignMutex = new Mutex(c.Id, Campaign.Name);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        System.assert(exceptionThrown);
    }
    
    private static testMethod void testConstructorFieldDoesNotBelongToRecord() {
        Campaign c = new Campaign(Name = 'My Test Campaign');
        insert c;
        
        Boolean exceptionThrown = false;
        
        try {
            Mutex campaignMutex = new Mutex(c.Id, Contact.LastName);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        System.assert(exceptionThrown);
    }
    
    public static testMethod void testGetLockRecordReturnsNullWhenNoRecordFound() {
        Id recordId = Campaign.sObjectType.getDescribe().getKeyPrefix() + '000000000000';
        
        Mutex m = new Mutex(recordId, Campaign.Campaign_List_Mutex__c);
        
        System.assertEquals(null, m.getLockRecord(false));
    }
    
    public static testMethod void testGetLockRecordReturnsCorrectRecord() {
        Schema.SObjectField mutexField = Campaign.Campaign_List_Mutex__c;
        
        Campaign c = new Campaign(Name = 'My Test Campaign');
        insert c;
        
        Mutex m = new Mutex(c.Id, mutexField);
        
        sObject so = m.getLockRecord(false);

        System.assert(so instanceof Campaign);
        System.assertEquals(c.Id, so.Id);
        
        Boolean mutexFieldWasQueried = true;
        
        try {
            so.get(mutexField);
        } catch (SObjectException e) {
            mutexFieldWasQueried = false;
        }
        
        System.assert(mutexFieldWasQueried);
    }
    
    public static testMethod void testAcquireLockFailsIfMissingLockRecord() {
        Id recordId = Campaign.sObjectType.getDescribe().getKeyPrefix() + '000000000000';
        
        Mutex m = new Mutex(recordId, Campaign.Campaign_List_Mutex__c);
        
        System.assertEquals(false, m.acquireLock(null, null));
    }
    
    public static testMethod void testAcquireLockFailsIfRecordAlreadyLocked() {
        Schema.SObjectField mutexField = Campaign.Campaign_List_Mutex__c;
        DateTime lockTime = DateTime.now();
                
        Campaign c = new Campaign(
            Name = 'My Test Campaign',
            Campaign_List_Mutex__c = lockTime
        );
        insert c;
            
        Mutex m = new Mutex(c.Id, mutexField);

        Boolean lockAcquired = m.acquireLock(c, lockTime);
        
        System.assertEquals(false, lockAcquired);
    }
    
    public static testMethod void testAcquireLockUpdatesLockField() {
        Schema.SObjectField mutexField = Campaign.Campaign_List_Mutex__c;
        
        Campaign c = new Campaign(Name = 'My Test Campaign');
        insert c;
            
        DateTime lockTime = DateTime.now();
        
        Mutex m = new Mutex(c.Id, mutexField);
        
        Boolean lockAcquired = m.acquireLock(c, lockTime);
        
        c = [
            SELECT Campaign_List_Mutex__c
            FROM Campaign
            WHERE Id = :c.Id
        ];
        
        System.assert(lockAcquired);
        System.assertEquals(lockTime, c.get(mutexField));
    }
    
    public static testMethod void testReleaseLockReturnsNullIfNoRecord() {
        Id recordId = Campaign.sObjectType.getDescribe().getKeyPrefix() + '000000000000';
        
        Mutex m = new Mutex(recordId, Campaign.Campaign_List_Mutex__c);
        
        System.assertEquals(false, m.releaseLock(null));        
    }

    public static testMethod void testReleaseLockClearsLockField() {
        
    }   
    
    public static testMethod void testGetLockTimeReturnsNullIfMissingLockRecord() {
        Schema.SObjectField mutexField = Campaign.Campaign_List_Mutex__c;
        DateTime lockTime = DateTime.now();
                
        Campaign c = new Campaign(
            Name = 'My Test Campaign',
            Campaign_List_Mutex__c = lockTime
        );
        insert c;
            
        Mutex m = new Mutex(c.Id, mutexField);

        Boolean lockReleased = m.releaseLock(c);
        
        c = [
            SELECT Campaign_List_Mutex__c
            FROM Campaign
            WHERE Id = :c.Id
        ];
        
        System.assert(lockReleased);
        System.assertEquals(null, c.get(mutexField));
    }
    
    public static testMethod void testGetLockTimeReturnsLockTime() {
        Id recordId = Campaign.sObjectType.getDescribe().getKeyPrefix() + '000000000000';
        DateTime lockTime = DateTime.now();
        Campaign c = new Campaign(Campaign_List_Mutex__c = lockTime);
        
        Mutex m = new Mutex(recordId, Campaign.Campaign_List_Mutex__c);
        
        System.assertEquals(lockTime, m.getLockTime(c));
    }
}