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
@isTest
private class CampaignListToCampaignBatch_TEST {
    private static testMethod void testStart() {
        Segment__c rootSegment = new Segment__c();
        insert rootSegment;

        Segment__c someOtherSegment = new Segment__c();
        insert someOtherSegment;

        Member__c member1 = new Member__c(
            Root_Segment__c = rootSegment.Id
        );
        insert member1;

        Member__c member2 = new Member__c(
            Root_Segment__c = someOtherSegment.Id
        );
        insert member2;

        CampaignList_TEST.SegmentStub rootSegmentStub = new CampaignList_TEST.SegmentStub();
        rootSegmentStub.segmentId = rootSegment.Id;

        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(null, rootSegmentStub);

        Database.QueryLocatorIterator qli = batch.start(null).iterator();

        List<Member__c> queriedMembers = new List<Member__c>();
        while (qli.hasNext()) {
            queriedMembers.add((Member__c) qli.next());
        }

        System.assertEquals(1, queriedMembers.size());
        System.assertEquals(member1.Id, queriedMembers.get(0).Id);
    }

    private static testMethod void testCampaignListToCampaignBatchExecute() {
        Member__c member1 = new Member__c(
            Id = CampaignList_TEST.getNextId(Member__c.sObjectType)
        );

        Member__c member2 = new Member__c(
            Id = CampaignList_TEST.getNextId(Member__c.sObjectType)
        );

        Id campaignId = CampaignList_TEST.getNextId(Campaign.sObjectType);

        CampaignList_TEST.SegmentStub rootSegment = new CampaignList_TEST.SegmentStub();
        rootSegment.acceptIds.add(member1.Id);

        CampaignList_TEST.MemberMapperStub mapperStub = new CampaignList_TEST.MemberMapperStub();
        CampaignList.setMemberMapper(mapperStub);

        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(campaignId, rootSegment);

        batch.execute(
            null,
            new List<Member__c>{member1, member2}
        );

        System.assertEquals(campaignId, mapperStub.campaignId);
        System.assertEquals(1, mapperStub.members.size());
        System.assertEquals(member1.Id, mapperStub.members.get(0).getId());
    }

    public static testMethod void testExecuteBatch() {
        CampaignList_TEST.MutexStub mutexStub = new CampaignList_TEST.MutexStub();
        mutexStub.releaseLock = true;

        CampaignList_TEST.MutexStubFactory mutexFactory = new CampaignList_TEST.MutexStubFactory();
        mutexFactory.m = mutexStub;
        CampaignList.setMutexFactory(mutexFactory);

        CampaignList_TEST.SegmentStub rootSegment = new CampaignList_TEST.SegmentStub();
        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(null, rootSegment);
        batch.setScope(200);

        CampaignList.setService(new CampaignList_TEST.ServiceStub());

        Test.startTest();

        Id jobId = batch.executeBatch();

        Test.stopTest();

        System.assertEquals(AsyncApexJob.sObjectType, jobId.getSobjectType());
    }
}