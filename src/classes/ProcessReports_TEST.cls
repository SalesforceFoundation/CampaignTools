@isTest
private class ProcessReports_TEST {
    
    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = 'combineCampaignAndReport';

    /*******************************************************************************************************
    * @description Extracts members from a report created for this purpose, if the report hasn't been deleted, 
    * and verifies five members have been extracted.
    */
    @isTest(SeeAllData='true')
    static void reportExtraction() {
        if (strTestOnly != '*' && strTestOnly != 'reportExtraction') return;
    
        list<report> testReport = [SELECT Id, DeveloperName FROM Report WHERE DeveloperName='Test_Report_Do_Not_Modify'];
        system.debug('testreport' + testReport);
        if (!testReport.isEmpty()) {
            id reportId = testReport[0].id;

            Reports.reportResults result = Reports.ReportManager.runReport(reportId, true);
            set<id> memberIds = ProcessReports.getMemberIdsFromReport(result,'CONTACT_ID');
            system.debug('lookhere'+memberIds);
            system.assertEquals(5, memberIds.size(), 'Five contact IDs should be parsed from the report.');
        }
    }

    /*******************************************************************************************************
    * @description Combines a campaign and a test report.
    */
    @isTest(SeeAllData='true')
    static void combineCampaignAndReport() {
        if (strTestOnly != '*' && strTestOnly != 'combineCampaignAndReport') return;
    
        list<report> testReport = [SELECT Id, Name FROM Report WHERE DeveloperName='Test_Report_Do_Not_Modify'];
        
        if (!testReport.isEmpty()) {
            id reportId = testReport[0].id;
            Campaign testCamp = new Campaign(Name = 'Test');
            insert testCamp;
            
            Contact testCon = new Contact(LastName = 'Testerson1');
            insert testCon;
            
            CampaignMember testMember = new CampaignMember(CampaignId = testCamp.ID, ContactId = testCon.ID, Status = 'Sent');
            insert testMember;
            
            //Root
            Segment__c root = new Segment__c(Root_Segment__c = null, Parent_Segment__c = null, 
                                Source_ID__c = null, Source_Type__c = null);
            insert root;
            //Level 1 segments
            Segment__c seg1_1 = new Segment__c(Root_Segment__c = root.ID, Parent_Segment__c = root.ID, 
                                Source_ID__c = testCamp.ID, Source_Type__c = 'Campaign');
            Segment__c seg1_2 = new Segment__c(Root_Segment__c = root.ID, Parent_Segment__c = root.ID, 
                                Source_ID__c = reportId, Source_Type__c = 'Report', Report_Field_Name__c='CONTACT_ID');
            insert new list<Segment__c>{seg1_1, seg1_2};
            
            Test.startTest();
            new MembersBuilder(root.ID);
            Test.stopTest();
            
            List<Member__c> membersInserted = [select Contact__c, Sources__c, Source_Names__c from Member__c WHERE Root_Segment__c=:root.ID];
            System.assertEquals(6, membersInserted.size());
            
            System.assertEquals(testCamp.ID, membersInserted[0].Sources__c);
            System.assertEquals('Campaign:' + testCamp.Name, membersInserted[0].Source_Names__c);
            
            System.assertEquals(reportId, membersInserted[1].Sources__c);
            System.assertEquals('Report:' + testReport[0].Name, membersInserted[1].Source_Names__c);
            
        }
    }
}