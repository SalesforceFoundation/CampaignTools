/*
    Copyright (c) 2016 Salesforce.org
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
 * @description Tests for CampaignListRefreshSchedulable
 */
@isTest
private class CampaignListRefreshSchedulable_TEST {
    @TestSetup
    private static void testData() {
        /*
         *         ,----------.
         *         |Campaign 1|
         *         `----------'
         *              |
         *              V
         *         ,---------.
         *         |Segment 1|
         *         `---------'
         *           |     |
         *           V     V
         *   ,---------.  ,---------.
         *   |Segment 2|  |Segment 3|
         *   `---------'  `---------'
         *     |    |             |
         *     |    V             V
         *     |  ,----------. ,----------. ,---------.
         *     |  |Campaign 2| |Campaign 5| |Segment 5|
         *     |  `----------' `----------' `---------'
         *     |   ^     |                    ^     |
         *     |   |     V                    |     |
         *     |   |   ,---------.    ,----------.  |
         *     |   |   |Segment 4|--->|Campaign 3|  |
         *     |   |   `---------'    `----------'  |
         *     | ,---------.                        |
         *     | |Segment 6|                        |
         *     | `---------'                        |
         *     |   ^                                |
         *     V   |                                |
         * ,----------.                             |
         * |Campaign 4|<----------------------------+
         * `----------'
         */

        Campaign c1 = new Campaign(
            Name = 'Test Campaign 1',
            Campaign_List_Refresh_Automatically__c = true,
            Campaign_List_Update_Status__c = 'Completed'
        );

        Campaign c2 = new Campaign(
            Name = 'Test Campaign 2',
            Campaign_List_Refresh_Automatically__c = true,
            Campaign_List_Update_Status__c = 'Completed'
        );

        Campaign c3 = new Campaign(
            Name = 'Test Campaign 3',
            Campaign_List_Refresh_Automatically__c = true,
            Campaign_List_Update_Status__c = 'Completed'
        );

        Campaign c4 = new Campaign(
            Name = 'Test Campaign 4',
            Campaign_List_Refresh_Automatically__c = true,
            Campaign_List_Update_Status__c = 'Completed'
        );

        Campaign c5 = new Campaign(
            Name = 'Test Campaign 5',
            Campaign_List_Refresh_Automatically__c = true,
            Campaign_List_Update_Status__c = 'Completed'
        );

        insert new List<Campaign>{c1, c2, c3, c4, c5};

        Segment__c s1 = new Segment__c();
        insert s1;

        Segment__c s2 = new Segment__c(
            Root_Segment__c = s1.Id,
            Source_ID__c = c4.Id
        );

        Segment__c s3 = new Segment__c(
            Root_Segment__c = s1.Id,
            Source_ID__c = c5.Id
        );

        Segment__c s4 = new Segment__c(
            Source_ID__c = c3.Id
        );

        Segment__c s5 = new Segment__c(
            Source_ID__c = c4.Id
        );

        Segment__c s6 = new Segment__c(
            Source_ID__c = c2.Id
        );

        insert new List<Segment__c>{s2, s3, s4, s5, s6};

        c1.Campaign_List__c = s1.Id;
        c2.Campaign_List__c = s4.Id;
        c3.Campaign_List__c = s5.Id;
        c4.Campaign_List__c = s6.Id;

        update new List<Campaign>{c1, c2, c3, c4};
    }

    @isTest
    private static void testGetCampaignsForAutoRefresh() {
        // to check exclusion, set c5 to not be auto update and c4 to have no
        // campaign list:
        Campaign c5 = [
            SELECT Campaign_List_Refresh_Automatically__c
            FROM Campaign
            WHERE Name = 'Test Campaign 5'
        ];

        c5.Campaign_List_Refresh_Automatically__c = false;
        update c5;

        Campaign c4 = [
            SELECT Campaign_List__c
            FROM Campaign
            WHERE Name = 'Test Campaign 4'
        ];

        c4.Campaign_List__c = null;
        update c4;

        Test.startTest();

        Map<Id, Campaign> campaigns = CampaignListRefreshSchedulable.getCampaignsForAutoRefresh();

        Test.stopTest();

        System.assertEquals(3, campaigns.size());

        Map<Id, Campaign> expectedCampaigns = new Map<Id, Campaign>([
            SELECT Id
            FROM Campaign
            WHERE Name IN (
                'Test Campaign 1',
                'Test Campaign 2',
                'Test Campaign 3'
            )
        ]);

        for (Campaign c : campaigns.values()) {
            System.assert(expectedCampaigns.containsKey(c.Id));

            System.assertEquals(
                'Completed',
                c.Campaign_List_Update_Status__c
            );

            System.assertNotEquals(
                null,
                c.Campaign_List__c
            );
        }
    }

    @isTest
    private static void testGetCampaignsById() {
        Map<Id, Campaign> expectedCampaigns = new Map<Id, Campaign>([
            SELECT Id
            FROM Campaign
            WHERE Name IN (
                'Test Campaign 1',
                'Test Campaign 2',
                'Test Campaign 3'
            )
        ]);

        Test.startTest();

        List<Campaign> campaigns = CampaignListRefreshSchedulable.getCampaignsByIds(
            expectedCampaigns.keySet()
        );

        Test.stopTest();

        System.assertEquals(3, campaigns.size());

        for (Campaign c : campaigns) {
            System.assert(expectedCampaigns.containsKey(c.Id));

            System.assertEquals(
                'Completed',
                c.Campaign_List_Update_Status__c
            );

            System.assertNotEquals(
                null,
                c.Campaign_List__c
            );
        }
    }

    @isTest
    private static void testGetRootSegmentIdsFromCampaigns() {
        Id segmentId1 = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id segmentId2 = CampaignList_TEST.getNextId(Segment__c.sObjectType);

        List<Campaign> campaigns = new List<Campaign>{
            new Campaign(Campaign_List__c = segmentId1),
            new Campaign(Campaign_List__c = segmentId2)
        };

        Test.startTest();

        Set<Id> segmentIds = CampaignListRefreshSchedulable.getRootSegmentIdsFromCampaigns(campaigns);

        Test.stopTest();

        System.assertEquals(2, segmentIds.size());
        System.assert(segmentIds.contains(segmentId1));
        System.assert(segmentIds.contains(segmentId2));
    }

    @isTest
    private static void testGetSegmentsByRootIds() {
        List<Segment__c> existingSegments = [SELECT Root_Segment__c FROM Segment__c];

        Set<Id> rootSegmentIds = new Set<Id>();
        Set<Id> expectedIds = new Set<Id>();

        for (Segment__c s : existingSegments) {
            if (null == s.Root_Segment__c) {
                rootSegmentIds.add(s.Id);
            }
            expectedIds.add(s.Id);
        }

        Test.startTest();

        List<Segment__c> segments = CampaignListRefreshSchedulable.getSegmentsByRootIds(
            rootSegmentIds
        );

        Test.stopTest();

        System.assertEquals(expectedIds.size(), segments.size());

        for (Segment__c s : segments) {
            System.assert(expectedIds.contains(s.Id));
        }
    }

    @isTest
    private static void testLockAndMarkCampaignAsQueuedThrowsException() {
        // update c5 to be locked

        DateTime lockTime = DateTime.now();

        Campaign c5 = [
            SELECT
                Campaign_List_Mutex__c,
                Campaign_List_Update_Status__c
            FROM Campaign
            WHERE Name = 'Test Campaign 5'
        ];

        c5.Campaign_List_Mutex__c = lockTime;
        c5.Campaign_List_Update_Status__c = 'Processing';
        update c5;

        Map<Id, Campaign> campaignsToLock = new Map<Id, Campaign>([
            SELECT
                Campaign_List__c,
                Campaign_List_Update_Status__c,
                Campaign_List_Mutex__c
            FROM Campaign
            FOR UPDATE
        ]);

        Test.startTest();

        Boolean exceptionThrown = false;

        try {
            CampaignListRefreshSchedulable.lockAndMarkCampaignsAsQueued(
                campaignsToLock
            );
        } catch (CampaignListRefreshSchedulable.CampaignAlreadyLockedException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(true, exceptionThrown);

        List<Campaign> campaigns = [
            SELECT
                Campaign_List_Mutex__c,
                Campaign_List_Update_Status__c
            FROM Campaign
        ];

        for (Campaign c : campaigns) {
            if (c.Id == c5.Id) {
                System.assertEquals(
                    lockTime,
                    c.Campaign_List_Mutex__c
                );

                System.assertEquals(
                    'Processing',
                    c.Campaign_List_Update_Status__c
                );
            } else {
                System.assertEquals(
                    'Completed',
                    c.Campaign_List_Update_Status__c
                );
            }
        }
    }

    @isTest
    private static void testLockAndMarkCampaignAsQueued() {
        Map<Id, Campaign> campaignsToLock = new Map<Id, Campaign>([
            SELECT
                Campaign_List__c,
                Campaign_List_Update_Status__c,
                Campaign_List_Mutex__c
            FROM Campaign
            FOR UPDATE
        ]);

        Test.startTest();

        CampaignListRefreshSchedulable.lockAndMarkCampaignsAsQueued(campaignsToLock);

        Test.stopTest();

        Map<Id, Campaign> campaigns = new Map<Id, Campaign>([
            SELECT
                Campaign_List_Mutex__c,
                Campaign_List_Update_Status__c
            FROM Campaign
        ]);

        System.assertEquals(5, campaigns.size());

        for (Campaign c : campaigns.values()) {
            System.assertNotEquals(
                null,
                c.Campaign_List_Mutex__c
            );

            System.assertEquals(
                'Queued',
                c.Campaign_List_Update_Status__c
            );
        }
    }

    @isTest
    private static void testCampaignGraphConstructor() {
        Map<Id, Campaign> campaigns = new Map<Id, Campaign>([
            SELECT
                Name,
                Campaign_List__c
            FROM Campaign
        ]);

        List<Segment__c> segments = [
            SELECT
                Root_Segment__c,
                Source_ID__c,
                (
                    SELECT Id
                    FROM Campaigns__r
                )
            FROM Segment__c
        ];

        Test.startTest();

        CampaignListRefreshSchedulable.CampaignGraph cg = new CampaignListRefreshSchedulable.CampaignGraph(campaigns, segments);

        Test.stopTest();

        Map<String, Id> cids = new Map<String, Id>();

        for (Campaign c : campaigns.values()) {
            cids.put(c.Name, c.Id);
        }

        Map<Id, Set<Id>> expectedDependants = new Map<Id, Set<Id>>{
            cids.get('Test Campaign 1') => new Set<Id>(),
            cids.get('Test Campaign 2') => new Set<Id>{
                cids.get('Test Campaign 4')
            },
            cids.get('Test Campaign 3') => new Set<Id>{
                cids.get('Test Campaign 2')
            },
            cids.get('Test Campaign 4') => new Set<Id>{
                cids.get('Test Campaign 1'),
                cids.get('Test Campaign 3')
            },
            cids.get('Test Campaign 5') => new Set<Id>{
                cids.get('Test Campaign 1')
            }
        };

        Map<Id, Set<Id>> expectedDependencies = new Map<Id, Set<Id>>{
            cids.get('Test Campaign 1') => new Set<Id>{
                cids.get('Test Campaign 4'),
                cids.get('Test Campaign 5')
            },
            cids.get('Test Campaign 2') => new Set<Id>{
                cids.get('Test Campaign 3')
            },
            cids.get('Test Campaign 3') => new Set<Id>{
                cids.get('Test Campaign 4')
            },
            cids.get('Test Campaign 4') => new Set<Id>{
                cids.get('Test Campaign 2')
            },
            cids.get('Test Campaign 5') => new Set<Id>()
        };

        System.assertEquals(5, cg.nodes.size());

        for (CampaignListRefreshSchedulable.CampaignNode cn : cg.nodes.values()) {
            System.assertEquals('', cn.updateStatus);
            System.assertEquals(false, cn.visited);
            System.assertEquals(false, cn.inComponent);

            System.assertEquals(
                campaigns.get(cn.campaignId).Campaign_List__c,
                cn.campaignListId
            );

            Set<Id> actualDependants = new Set<Id>();

            for (CampaignListRefreshSchedulable.CampaignNode dependant : cn.dependants) {
                actualDependants.add(dependant.campaignId);
            }

            Set<Id> actualDependencies = new Set<Id>();

            for (CampaignListRefreshSchedulable.CampaignNode dependency : cn.dependencies) {
                actualDependencies.add(dependency.campaignId);
            }

            System.assertEquals(
                expectedDependants.get(cn.campaignId),
                actualDependants
            );

            System.assertEquals(
                expectedDependencies.get(cn.campaignId),
                actualDependencies
            );
        }
    }

    @isTest
    private static void testCampaignGraphGetCampaignIds() {
        TestNodes tn = new TestNodes();

        CampaignListRefreshSchedulable.CampaignGraph cg = new CampaignListRefreshSchedulable.CampaignGraph();
        cg.nodes = tn.nodes;

        Test.startTest();

        Set<Id> campaignIds = cg.getCampaignIds();

        Test.stopTest();

        System.assertEquals(
            new Set<Id>{
                tn.campaignId1,
                tn.campaignId2,
                tn.campaignId3,
                tn.campaignId4,
                tn.campaignId5
            },
            campaignIds
        );
    }

    @isTest
    private static void testCampaignGraphSetCampaignStatus() {
        TestNodes tn = new TestNodes();

        CampaignListRefreshSchedulable.CampaignGraph cg = new CampaignListRefreshSchedulable.CampaignGraph();
        cg.nodes = tn.nodes;

        Map<Id, Campaign> campaigns = new Map<Id, Campaign>{
            tn.campaignId1 => new Campaign(
                Id = tn.campaignId1,
                Campaign_List_Update_Status__c = 'Queued'
            ),
            tn.campaignId2 => new Campaign(
                Id = tn.campaignId2,
                Campaign_List_Update_Status__c = 'Processing'
            ),
            tn.campaignId3 => new Campaign(
                Id = tn.campaignId3,
                Campaign_List_Update_Status__c = 'Aborted'
            ),
            tn.campaignId4 => new Campaign(
                Id = tn.campaignId4,
                Campaign_List_Update_Status__c = 'Completed'
            ),
            tn.campaignId5 => new Campaign(
                Id = tn.campaignId5,
                Campaign_List_Update_Status__c = 'Failed'
            )
        };

        Test.startTest();

        cg.setCampaignStatus(campaigns.values());

        Test.stopTest();

        System.assertEquals(1, cg.queuedCount);

        for (CampaignListRefreshSchedulable.CampaignNode cn : cg.nodes.values()) {
            System.assertEquals(
                campaigns.get(cn.campaignId).Campaign_List_Update_Status__c,
                cn.updateStatus
            );
        }
    }

    @isTest
    private static void testCampaignGraphRemoveCycles() {
        TestNodes tn = new TestNodes();

        CampaignListRefreshSchedulable.CampaignGraph cg = new CampaignListRefreshSchedulable.CampaignGraph();
        cg.nodes = tn.nodes;

        Test.startTest();

        cg.removeCycles();

        Test.stopTest();

        // The cycle breaking algorithm should detect the strongly connected
        // component C2>C3>C4>C2 and break the cycle by removing the edge C4>C2

        System.assertEquals(
            tn.cn1.dependants,
            cg.nodes.get(tn.cn1.campaignId).dependants
        );

        System.assertEquals(
            tn.cn1.dependencies,
            cg.nodes.get(tn.cn1.campaignId).dependencies
        );

        // because C4>C2 is broken, C2 no longer has any dependants
        System.assertEquals(
            new Set<CampaignListRefreshSchedulable.CampaignNode>(),
            cg.nodes.get(tn.cn2.campaignId).dependants
        );

        System.assertEquals(
            tn.cn2.dependencies,
            cg.nodes.get(tn.cn2.campaignId).dependencies
        );

        System.assertEquals(
            tn.cn3.dependants,
            cg.nodes.get(tn.cn3.campaignId).dependants
        );

        System.assertEquals(
            tn.cn3.dependencies,
            cg.nodes.get(tn.cn3.campaignId).dependencies
        );

        System.assertEquals(
            tn.cn4.dependants,
            cg.nodes.get(tn.cn4.campaignId).dependants
        );

        // because C4>C2 is broken, C4 no longer has any dependencies
        System.assertEquals(
            new Set<CampaignListRefreshSchedulable.CampaignNode>(),
            cg.nodes.get(tn.cn4.campaignId).dependencies
        );

        System.assertEquals(
            tn.cn5.dependants,
            cg.nodes.get(tn.cn5.campaignId).dependants
        );

        System.assertEquals(
            tn.cn5.dependencies,
            cg.nodes.get(tn.cn5.campaignId).dependencies
        );
    }

    @isTest
    private static void testGetReadyCampaigns() {
        TestNodes tn = new TestNodes();

        // remove the C4>C2 edge to break cycle in test data
        tn.cn4.dependencies = new Set<CampaignListRefreshSchedulable.CampaignNode>();
        tn.cn2.dependants = new Set<CampaignListRefreshSchedulable.CampaignNode>();

        // mark C4 and C5 as completed states with the rest queued
        tn.cn1.updateStatus = 'Queued';
        tn.cn2.updateStatus = 'Queued';
        tn.cn3.updateStatus = 'Queued';
        tn.cn4.updateStatus = 'Failed';
        tn.cn5.updateStatus = 'Completed';

        // this should make C1 and C3 ready, but not C2
        System.assert(tn.cn1.isReady());
        System.assert(tn.cn3.isReady());

        CampaignListRefreshSchedulable.CampaignGraph cg = new CampaignListRefreshSchedulable.CampaignGraph();
        cg.nodes = tn.nodes;

        Test.startTest();

        List<Campaign> campaigns = cg.getReadyCampaigns();

        Test.stopTest();

        System.assertEquals(2, campaigns.size());

        Map<Id, Campaign> campaignMap = new Map<Id, Campaign>(campaigns);

        System.assert(campaignMap.containsKey(tn.cn1.campaignId));
        System.assert(campaignMap.containsKey(tn.cn3.campaignId));
    }

    private class TestNodes {
        public Id campaignId1;
        public Id campaignId2;
        public Id campaignId3;
        public Id campaignId4;
        public Id campaignId5;
        public Id segmentId1;
        public Id segmentId3;
        public Id segmentId4;
        public Id segmentId5;
        public Id segmentId6;
        public CampaignListRefreshSchedulable.CampaignNode cn1;
        public CampaignListRefreshSchedulable.CampaignNode cn2;
        public CampaignListRefreshSchedulable.CampaignNode cn3;
        public CampaignListRefreshSchedulable.CampaignNode cn4;
        public CampaignListRefreshSchedulable.CampaignNode cn5;
        Map<Id, CampaignListRefreshSchedulable.CampaignNode> nodes;

        public TestNodes() {
            campaignId1 = CampaignList_TEST.getNextId(Campaign.sObjectType);
            campaignId2 = CampaignList_TEST.getNextId(Campaign.sObjectType);
            campaignId3 = CampaignList_TEST.getNextId(Campaign.sObjectType);
            campaignId4 = CampaignList_TEST.getNextId(Campaign.sObjectType);
            campaignId5 = CampaignList_TEST.getNextId(Campaign.sObjectType);
            segmentId1 = CampaignList_TEST.getNextId(Segment__c.sObjectType);
            segmentId4 = CampaignList_TEST.getNextId(Segment__c.sObjectType);
            segmentId5 = CampaignList_TEST.getNextId(Segment__c.sObjectType);
            segmentId6 = CampaignList_TEST.getNextId(Segment__c.sObjectType);

            cn1 = new CampaignListRefreshSchedulable.CampaignNode(campaignId1, segmentId1);
            cn2 = new CampaignListRefreshSchedulable.CampaignNode(campaignId2, segmentId4);
            cn3 = new CampaignListRefreshSchedulable.CampaignNode(campaignId3, segmentId5);
            cn4 = new CampaignListRefreshSchedulable.CampaignNode(campaignId4, segmentId6);
            cn5 = new CampaignListRefreshSchedulable.CampaignNode(campaignId5, null);

            cn1.dependencies.add(cn4);
            cn1.dependencies.add(cn5);
            cn2.dependants.add(cn4);
            cn2.dependencies.add(cn3);
            cn3.dependants.add(cn2);
            cn3.dependencies.add(cn4);
            cn4.dependants.add(cn1);
            cn4.dependants.add(cn3);
            cn4.dependencies.add(cn2);
            cn5.dependants.add(cn1);

            nodes = new Map<Id, CampaignListRefreshSchedulable.CampaignNode>{
                campaignId1 => cn1,
                campaignId2 => cn2,
                campaignId3 => cn3,
                campaignId4 => cn4,
                campaignId5 => cn5
            };
        }
    }
}