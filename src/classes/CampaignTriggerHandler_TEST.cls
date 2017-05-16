/*
    Copyright (c) 2017 Salesforce.org
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
 * @description Tests for CampaignTriggerHandler
 */
@isTest
public with sharing class CampaignTriggerHandler_TEST {
    /*******************************************************************************************************
     * @description Clones a campaign record without a campaign list and asserts the cloned campaign
     * does not have a campaign list.
     *******************************************************************************************************/
    @isTest
    private static void testNewCampsWithoutSegments() {
        List<Campaign> listNewCamps = generateCampaigns(1, false);
        List<Campaign> listClonedCamps;

        insert listNewCamps;
        listClonedCamps = listNewCamps.deepClone();

        Test.startTest();
        insert listClonedCamps;
        Test.stopTest();

        List<Campaign> queriedResults = [SELECT Id, Campaign_List__c FROM Campaign WHERE ID IN :listClonedCamps];

        System.assertEquals(null, listNewCamps[0].Campaign_List__c, 'There should not be a segment related to the original.');
        System.assertEquals(null, listClonedCamps[0].Campaign_List__c, 'There should not be a segment related to the clone.');
    }
    /*******************************************************************************************************
     * @description Clones a campaign record with a campaign list and asserts the cloned campaign
     * has a cloned copy of the original campaing list
     *******************************************************************************************************/
    @isTest
    private static void testNewCampsWithSegments() {
        List<Campaign> listNewCamps = generateCampaigns(1, false);
        List<Campaign> listClonedCamps;
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
        listNewCamps[0].Campaign_List__c = listNewSegments[0].Id;
        insert listNewCamps;
        listClonedCamps = listNewCamps.deepClone();

        Test.startTest();
        insert listClonedCamps;
        Test.stopTest();

        List<Campaign> queriedCampaigns = [SELECT Id, Campaign_List__c FROM Campaign WHERE ID IN :listClonedCamps];
        List<Segment__c> queriedSegments = new CampaignListSegmentMapper().queryByRootSegmentId(new Set<Id>{queriedCampaigns[0].Campaign_List__c});

        System.assertEquals(listNewSegments[0].Id, listNewCamps[0].Campaign_List__c, 'The root segment should be related to the original campaign.');
        System.assertNotEquals(listNewSegments[0].Id, queriedCampaigns[0].Campaign_List__c, 'The root segment should not be related to the cloned campaign.');
        System.assertEquals(listNewSegments.size(), queriedSegments.size(), 'The total number of segments should match the original campaigns.');
    }
    /*******************************************************************************************************
     * @description Clones several campaign records with a campaign list and asserts the cloned campaign
     * has a cloned copy of the original campaing list
     *******************************************************************************************************/
    @isTest
    private static void testMultiNewCampsWithSegments() {
        List<Campaign> listNewCamps = generateCampaigns(200, false);
        List<Campaign> listClonedCamps;
        List<Segment__c> listNewSegments = new List<Segment__c>();

        // Creating generic segments for testing purposes that do not reflect a true segment tree
        for (Integer i = 0; i < 100; i++) {
            listNewSegments.add(new Segment__c(Operation__c = 'AND'));
            listNewSegments.add(new Segment__c(Operation__c = 'OR'));
            listNewSegments.add(new Segment__c(Operation__c = 'AND'));
        }
        insert listNewSegments;

        // Updating the segment to simulate a segment tree structure
        for (Integer i = 0; i < 298; i = i+3) {
            listNewSegments[i + 1].Parent_Segment__c = listNewSegments[i].Id;
            listNewSegments[i + 1].Root_Segment__c = listNewSegments[i].Id;
            listNewSegments[i + 2].Parent_Segment__c = listNewSegments[i + 1].Id;
            listNewSegments[i + 2].Root_Segment__c = listNewSegments[i].Id;
        }
        update listNewSegments;

        // Assigning the segment to the new campaign
        for (Integer i = 0; i < 100; i++) {
            listNewCamps[i].Campaign_List__c = listNewSegments[i * 3].Id;
        }
        insert listNewCamps;
        listClonedCamps = listNewCamps.deepClone();

        Test.startTest();
        insert listClonedCamps;
        Test.stopTest();

        List<Campaign> queriedCampaigns = [SELECT Id, Campaign_List__c FROM Campaign WHERE ID IN :listClonedCamps];
        List<Segment__c> queriedSegments = new List<Segment__c>([SELECT Id, Root_Segment__c, Parent_Segment__c FROM Segment__c WHERE Id NOT IN :listNewSegments]);

        Map<Id, Segment__c> mapNewSegments = new Map<Id, Segment__c>(listNewSegments);

        for (Campaign queriedCampaign : queriedCampaigns) {
            System.assert(!mapNewSegments.keySet().contains(queriedCampaign.Campaign_List__c), 'The cloned camp segment should not be the same as the original segment.');
        }
        for (Segment__c queriedSegment : queriedSegments) {
            System.assert(!mapNewSegments.keySet().contains(queriedSegment.Root_Segment__c), 'The cloned segments root should not be the same as the original segment.');
        }
        for (Segment__c queriedSegment : queriedSegments) {
            System.assert(!mapNewSegments.keySet().contains(queriedSegment.Parent_Segment__c), 'The cloned segments parent should not be the same as the original segment.');
        }
        System.assertEquals(listNewSegments.size(), queriedSegments.size(), 'The total number of segments should match the original campaigns.');
    }
    /*******************************************************************************************************
     * @description Inserts a campaign record that is not set to auto refresh without a scheduled job and
     * asserts that the record should have inserted successfully
     *******************************************************************************************************/
    @isTest
	private static void testNewCampsWithoutScheduleNoRefresh() {
        CampaignTriggerHandler.validate = true;
        List<Campaign> listNewCamps = generateCampaigns(1, false);
        Test.startTest();
        insert listNewCamps;
        Test.stopTest();

        List<Campaign> queriedResults = [SELECT Id FROM Campaign WHERE ID IN :listNewCamps];

        System.assertEquals(listNewCamps.size(), queriedResults.size(), 'Records should have inserted without issue.');
    }
    /*******************************************************************************************************
     * @description Inserts a campaign record that is set to auto refresh without a scheduled job and
     * asserts that an error should have been thrown and no records were inserted
     *******************************************************************************************************/
    @isTest
    private static void testNewCampsWithoutScheduleWithRefresh() {
        CampaignTriggerHandler.validate = true;
        List<Campaign> listNewCamps = generateCampaigns(1, true);
        Test.startTest();
        try {
            insert listNewCamps;
            System.assert(false, 'Insert should fail and should leave try block.');
        } catch(Exception ex) {
            System.assert(true, 'Insert should fail and enter catch block.');
        }
        Test.stopTest();

        List<Campaign> queriedResults = [SELECT Id FROM Campaign WHERE ID IN :listNewCamps];

        System.assert(queriedResults.isEmpty());
    }
    /*******************************************************************************************************
     * @description Updates a campaign record that is not set to auto refresh without a scheduled job and
     * asserts that the record should have updated successfully
     *******************************************************************************************************/
    @isTest
    private static void testUpdateCampsWithoutScheduleNoRefresh() {
        CampaignTriggerHandler.validate = true;
        List<Campaign> listNewCamps = generateCampaigns(1, false);
        insert listNewCamps;
        for (Campaign newCamps : listNewCamps) {
            newCamps.Name += ' Updating';
        }

        Test.startTest();
        update listNewCamps;
        Test.stopTest();

        List<Campaign> queriedResults = [SELECT Id FROM Campaign WHERE ID IN :listNewCamps AND Name LIKE '% Updating'];

        System.assertEquals(listNewCamps.size(), queriedResults.size(), 'Records should have updated without issue.');
    }
    /*******************************************************************************************************
     * @description Updates a campaign record and sets it to auto refresh without a scheduled job and
     * asserts that an error should have been thrown and no records were updated
     *******************************************************************************************************/
    @isTest
    private static void testUpdateCampsWithoutScheduleWithRefresh() {
        CampaignTriggerHandler.validate = true;
        List<Campaign> listNewCamps = generateCampaigns(1, false);
        insert listNewCamps;
        for (Campaign newCamps : listNewCamps) {
            newCamps.Name += ' Updating';
            newCamps.Campaign_List_Refresh_Automatically__c = true;
        }

        Test.startTest();
        try {
            update listNewCamps;
            System.assert(false, 'Update should fail and should leave try block.');
        } catch (Exception ex) {
            System.assert(true, 'Insert should fail and enter catch block.');
        }
        Test.stopTest();

        List<Campaign> queriedResults = [SELECT Id FROM Campaign WHERE ID IN :listNewCamps AND Name LIKE '% Updating'];

        System.assert(queriedResults.isEmpty(), 'Records should have failed to update.');
    }
    /*******************************************************************************************************
     * @description Inserts 100 campaigns set to refresh and 100 campaigns not set to refresh with a
     * scheduled job and asserts that all records were inserted
     *******************************************************************************************************/
    @isTest
    private static void testCampsWithScheduleMixBulk() {
        CampaignTriggerHandler.validate = true;
        List<Campaign> listNewCamps = generateCampaigns(100, false);
        listNewCamps.addAll(generateCampaigns(100, true));
        Test.startTest();
        List<AsyncApexJob> listCampRefreshJobs = scheduleJob();
        insert listNewCamps;
        Test.stopTest();

        List<Campaign> queriedResults = [SELECT Id FROM Campaign WHERE ID IN :listNewCamps];

        System.assertEquals(listCampRefreshJobs.size(), 1, 'There should be one scheduled job.');
        System.assertEquals(listNewCamps.size(), queriedResults.size(), 'Records should have inserted without issue.');
    }
    /*******************************************************************************************************
     * @description Inserts 200 campaigns set to refresh and 200 campaigns not set to refresh without a
     * scheduled job and asserts that an exception was thrown and no records were inserted
     *******************************************************************************************************/
    @isTest
    private static void testCampsWithoutScheduleMixBulk() {
        CampaignTriggerHandler.validate = true;
        List<Campaign> listNewCamps = generateCampaigns(200, false);
        listNewCamps.addAll(generateCampaigns(200, true));
        Test.startTest();
        try {
            insert listNewCamps;
            System.assert(false, 'Update should fail and should leave try block.');
        } catch(Exception ex) {
            System.assert(true, 'Insert should fail and enter catch block.');
        }
        Test.stopTest();

        List<Campaign> queriedResults = [SELECT Id FROM Campaign WHERE ID IN :listNewCamps];

        System.assert(queriedResults.isEmpty(), 'Records should have failed to insert.');
    }
    /*******************************************************************************************************
     * @description creates a scheduled job called by tests requiring a scheduled job
     *******************************************************************************************************/
    private static List<AsyncApexJob> scheduleJob() {
        String jobId = System.schedule('testRefreshScheduledApex',
            '0 0 10 ? * MON-FRI', 
            new CampaignListRefreshSchedulable());
        return [SELECT Id FROM AsyncApexJob
                WHERE JobType = 'ScheduledApex' AND Status ='Queued'
                AND ApexClass.Name = 'CampaignListRefreshSchedulable'];
    }
    /*******************************************************************************************************
     * @description creates a specified number of campaigns and sets them to refresh if specefied by the
     * refresh parameter. Called by tests to generate test campaign data
     * @param numOfCamps - the number of campaigns to create
     * @param refresh - boolean flag when true sets the campaign to refresh
     * @return List<Campaign> - the list of campaign records created
     *******************************************************************************************************/
    private static List<Campaign> generateCampaigns(Integer numOfCamps, Boolean refresh) {
        List<Campaign> listCamps = new List<Campaign>();
        for (Integer i = 0; i < numOfCamps; i++) {
            listCamps.add(new Campaign(
                Name = 'Testing Campaign ' + 1,
                Campaign_List_Refresh_Automatically__c = refresh));
        }
        return listCamps;
    }
}