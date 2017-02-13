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

    private static List<AsyncApexJob> scheduleJob() {
        String jobId = System.schedule('testRefreshScheduledApex',
            '0 0 10 ? * MON-FRI', 
            new CampaignListRefreshSchedulable());
        return [SELECT Id FROM AsyncApexJob
                WHERE JobType = 'ScheduledApex' AND Status ='Queued'
                AND ApexClass.Name = 'CampaignListRefreshSchedulable'];
    }

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