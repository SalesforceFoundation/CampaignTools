/*
    Copyright (c) 2015 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description Tests for CampaignListBuilder
 */
@isTest
private with sharing class CampaignListBuilder_TEST {
    /*******************************************************************************************************
     * @description Verify the report columns returned match those of the report service stub
     *******************************************************************************************************/
    public static testMethod void testGetReportIdColumnsReturnsIdColumns() {
        Id reportId = CampaignList_TEST.getNextId(Report.sObjectType);

        Map<String, String> expectedColumns = new Map<String, String>{
            'CONTACT_ID' => 'Contact ID'
        };

        ReportServiceWithResultsStub service = new ReportServiceWithResultsStub();
        service.idColumns = expectedColumns;
        CampaignList.setReportService(service);

        Test.startTest();

        Map<String, String> actualColumns = CampaignListBuilder_CTRL.getReportIdColumns(reportId);

        Test.stopTest();

        System.assertEquals(expectedColumns, actualColumns);
        System.assertEquals(reportId, service.reportId);
    }
    /*******************************************************************************************************
     * @description Verify an exception is thrown by get report columns when report service stub method
     * is set to throw an exception.
     *******************************************************************************************************/
    public static testMethod void testGetReportIdInvalidThrowsNoColumnsException() {
        ReportServiceWithExceptionStub service = new ReportServiceWithExceptionStub();
        CampaignList.setReportService(service);

        Boolean exceptionThrown = false;

        try {
            CampaignListBuilder_CTRL.getReportIdColumns(null);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown);
    }
    /*******************************************************************************************************
     * @description Unable to test CRUD levels in unit tests, setting the class to throw an exception to
     * verify the permission exception is properly thrown when attempting to retrieve report columns without
     * proper permissions
     *******************************************************************************************************/
    public static testMethod void testGetReportIdInvalidThrowsNoPermsException() {
        Boolean exceptionThrown;
        Id reportId = CampaignList_TEST.getNextId(Report.sObjectType);
        Map<String, String> expectedColumns = new Map<String, String>{
            'CONTACT_ID' => 'Contact ID'
        };
        ReportServiceWithResultsStub service = new ReportServiceWithResultsStub();
        service.idColumns = expectedColumns;
        CampaignList.setReportService(service);
        CampaignTools_UTIL.throwException = true;

        Test.startTest();
        try {
            Map<String, String> actualColumns = CampaignListBuilder_CTRL.getReportIdColumns(reportId);
            exceptionThrown = false;
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'An exception should be thrown and the user should not have permission.');
    }
    /*******************************************************************************************************
     * @description Unable to test CRUD levels in unit tests, setting the class to throw an exception to
     * verify the permission exception is properly thrown when checking overall permissions for the app
     *******************************************************************************************************/
    public static testMethod void testCheckPerms() {
        Boolean exceptionThrown;

        try {
            CampaignListBuilder_CTRL.checkPerms();
            exceptionThrown = false;
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assert(!exceptionThrown, 'An exception should not be thrown and the user should have permission.');
    }
    /*******************************************************************************************************
     * @description Unable to test CRUD levels in unit tests, not setting the class to throw an exception to
     * verify the permission exception is not thrown when checking overall permissions for the app
     *******************************************************************************************************/
    public static testMethod void testCheckWithoutPerms() {
        Boolean exceptionThrown;

        try {
            CampaignTools_UTIL.throwException = true;
            CampaignListBuilder_CTRL.checkPerms();
            exceptionThrown = false;
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'An exception should be thrown and the user should not have permission.');
    }
    /*******************************************************************************************************
     * @description Verifying the get status methods returns the correct statuses
     *******************************************************************************************************/
    public static testMethod void testGetStatuses() {
        Campaign campRecord = new Campaign(Name='test');
        insert campRecord;
        CampaignMemberStatus newStatus = new CampaignMemberStatus(
            CampaignID = campRecord.id,
            Label = 'New Status'
        );
        insert newStatus;

        Test.startTest();
        Map<String,String> campStatuses = CampaignListBuilder_CTRL.getStatuses(campRecord.Id);
        Test.stopTest();

        System.assertEquals(1, campStatuses.size(), 'New campaigns should have one status.');
    }
    /*******************************************************************************************************
     * @description Unable to test CRUD levels in unit tests, setting the class to throw an exception to
     * verify the permission exception is properly thrown when attempting to retrieve statuses
     *******************************************************************************************************/
    public static testMethod void testGetStatusesNoPermsException() {
        Boolean exceptionThrown;
        Campaign campRecord = new Campaign(Name='test');
        insert campRecord;
        CampaignMemberStatus newStatus = new CampaignMemberStatus(
            CampaignID = campRecord.id,
            Label = 'New Status'
        );
        insert newStatus;

        Test.startTest();
        try {
            CampaignTools_UTIL.throwException = true;
            Map<String,String> campStatuses = CampaignListBuilder_CTRL.getStatuses(campRecord.Id);
            exceptionThrown = false;
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'An exception should be thrown and the user should not have permission.');
    }
    /*******************************************************************************************************
     * @description Verify JSON string of saved campaign list is returned
     *******************************************************************************************************/
    @isTest
    private static void testSegmentSerialize() {
        Campaign newCampaign = new Campaign(Name = 'Testing Campaign');
        List<Segment__c> listNewSegments = new List<Segment__c>();

        // Creating generic segments for testing purposes that do not reflect a true segment tree
        listNewSegments.add(new Segment__c(Operation__c = 'AND'));
        listNewSegments.add(new Segment__c(Operation__c = 'OR'));
        listNewSegments.add(new Segment__c(Operation__c = 'AND'));
        insert listNewSegments;

        // Updating the segment to simulate a segment tree structure
        listNewSegments[1].Parent_Segment__c = listNewSegments[0].Id;
        listNewSegments[1].Root_Segment__c = listNewSegments[0].Id;
        listNewSegments[2].Parent_Segment__c = listNewSegments[1].Id;
        listNewSegments[2].Root_Segment__c = listNewSegments[0].Id;
        update listNewSegments;

        // Assigning the segment to the new campaign
        newCampaign.Campaign_List__c = listNewSegments[0].Id;
        insert newCampaign;

        Test.startTest();
        String testJSON = CampaignListBuilder_CTRL.getSerializedSegmentTree(listNewSegments[0].Id);
        Test.stopTest();

        System.assert(testJSON.contains(listNewSegments[0].Id), 'The resulting json should contain the root segment id');
    }
    /*******************************************************************************************************
     * @description Verify saving campaign list saves without error
     *******************************************************************************************************/
    @isTest
    private static void testSegmentSave() {
        Campaign newCampaign = new Campaign(Name = 'Testing Campaign');
        List<Segment__c> listNewSegments = new List<Segment__c>();

        // Creating generic segments for testing purposes that do not reflect a true segment tree
        listNewSegments.add(new Segment__c(Operation__c = 'AND'));
        listNewSegments.add(new Segment__c(Operation__c = 'OR'));
        listNewSegments.add(new Segment__c(Operation__c = 'AND'));
        insert listNewSegments;

        // Updating the segment to simulate a segment tree structure
        listNewSegments[1].Parent_Segment__c = listNewSegments[0].Id;
        listNewSegments[1].Root_Segment__c = listNewSegments[0].Id;
        listNewSegments[2].Parent_Segment__c = listNewSegments[1].Id;
        listNewSegments[2].Root_Segment__c = listNewSegments[0].Id;
        update listNewSegments;

        // Assigning the segment to the new campaign
        newCampaign.Campaign_List__c = listNewSegments[0].Id;
        insert newCampaign;
        String testJSON = CampaignListBuilder_CTRL.getSerializedSegmentTree(listNewSegments[0].Id);

        Test.startTest();
        Boolean saveSucccess = CampaignListBuilder_CTRL.saveCSegmentTree(newCampaign.Id, testJSON);
        Test.stopTest();

        System.assert(saveSucccess, 'The saving of the campaign with serialized tree should succeed');
    }
    /*******************************************************************************************************
     * @description Report Service Stub with columns used to mock report in system for testing
     *******************************************************************************************************/
    private class ReportServiceWithResultsStub implements CampaignList.ReportService {
        public Id reportId;
        public Map<String, String> idColumns;
        public Map<String, String> getIdColumns(Id reportId) {
            this.reportId = reportId;
            return idColumns;
        }
    }
    /*******************************************************************************************************
     * @description Report Service Stub set to throw an error used to mock handling an error
     *******************************************************************************************************/
    private class ReportServiceWithExceptionStub implements CampaignList.ReportService {
        public Map<String, String> getIdColumns(Id reportId) {
            throw new DummyException();
        }
    }
    /*******************************************************************************************************
     * @description Dummy exceptiont thrown by report service stub
     *******************************************************************************************************/
    private class DummyException extends Exception {}
}