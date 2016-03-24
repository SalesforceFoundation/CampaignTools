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
 * @description A Schedulable for refreshing marked Campaigns from Campaign Lists
 */
public class CampaignListRefreshSchedulable implements Schedulable {
    public void execute(SchedulableContext sc) {
        Map<Id, Campaign> campaigns = getCampaignsForAutoRefresh();

        lockAndMarkCampaignsAsQueued(campaigns);

        Set<Id> campaignListIds = getRootSegmentIdsFromCampaigns(campaigns.values());

        List<Segment__c> segments = getSegmentsByRootIds(campaignListIds);

        CampaignGraph cg = new CampaignGraph(campaigns, segments);

        cg.removeCycles();

        Worker w = new Worker(cg);

        CampaignList.getService().enqueueJob(w);
    }

    @TestVisible
    private static Map<Id, Campaign> getCampaignsForAutoRefresh() {
        return new Map<Id, Campaign>([
            SELECT
                Campaign_List__c,
                Campaign_List_Update_Status__c,
                Campaign_List_Mutex__c
            FROM Campaign
            WHERE Campaign_List_Refresh_Automatically__c = true
            AND Campaign_List__c != null
            FOR UPDATE
        ]);
    }

    @TestVisible
    private static List<Campaign> getCampaignsByIds(Set<Id> campaignIds) {
        return [
            SELECT
                Campaign_List__c,
                Campaign_List_Update_Status__c
            FROM Campaign
            WHERE Id IN :campaignIds
        ];
    }

    @TestVisible
    private static Set<Id> getRootSegmentIdsFromCampaigns(List<Campaign> campaigns) {
        Set<Id> campaignListIds = new Set<Id>();

        for (Campaign c : campaigns) {
            campaignListIds.add(c.Campaign_List__c);
        }

        return campaignListIds;
    }

    @TestVisible
    private static List<Segment__c> getSegmentsByRootIds(Set<Id> segmentIds) {
        return [
            SELECT
                Root_Segment__c,
                Source_ID__c,
                (
                    SELECT Id
                    FROM Campaigns__r
                )
            FROM Segment__c
            WHERE Id IN :segmentIds
            OR Root_Segment__c IN :segmentIds
        ];
    }

    @TestVisible
    private static void lockAndMarkCampaignsAsQueued(Map<Id, Campaign> campaigns) {
        for (Campaign c : campaigns.values()) {
            if (null != c.Campaign_List_Mutex__c) {
                throw new CampaignAlreadyLockedException();
            }
            c.Campaign_List_Mutex__c = DateTime.now();
            c.Campaign_List_Update_Status__c = 'Queued';
        }
        update campaigns.values();
    }

    public class CampaignAlreadyLockedException extends Exception {}

    @TestVisible
    private class CampaignGraph {
        @TestVisible
        private Map<Id, CampaignNode> nodes = new Map<Id, CampaignNode>();
        private Set<CampaignNode> visitedNodes = new Set<CampaignNode>();
        private Set<CampaignNode> assignedNodes = new Set<CampaignNode>();
        private Map<CampaignNode, Set<CampaignNode>> stronglyConnectedComponents = new Map<CampaignNode, Set<CampaignNode>>();
        private List<CampaignNode> leadingNodesStack = new List<CampaignNode>();

        public Integer queuedCount;

        @TestVisible
        private CampaignGraph() {}

        public CampaignGraph(Map<Id, Campaign> campaigns, List<Segment__c> segments) {
            for (Id campaignId : campaigns.keySet()) {
                Campaign c = campaigns.get(campaignId);
                nodes.put(
                    campaignId,
                    new CampaignNode(
                        campaignId,
                        c.Campaign_List__c
                    )
                );
            }

            Map<Id, Segment__c> segmentsMap = new Map<Id, Segment__c>(segments);

            for (Segment__c s : segments) {
                if (campaigns.containsKey(s.Source_ID__c)) {
                    Campaign sourceCampaign = campaigns.get(s.Source_ID__c);
                    List<Campaign> targetCampaigns;
                    if (null != s.Root_Segment__c) {
                        if (!segmentsMap.containsKey(s.Root_Segment__c))  {
                            continue;
                        }
                        targetCampaigns = segmentsMap.get(s.Root_Segment__c).Campaigns__r;
                    } else {
                        targetCampaigns = s.Campaigns__r;
                    }
                    for (Campaign targetCampaign : targetCampaigns) {
                        if (nodes.containsKey(targetCampaign.Id)) {
                            CampaignNode sourceCampaignNode = nodes.get(sourceCampaign.Id);
                            CampaignNode targetCampaignNode = nodes.get(targetCampaign.Id);
                            sourceCampaignNode.dependants.add(targetCampaignNode);
                            targetCampaignNode.dependencies.add(sourceCampaignNode);
                        }
                    }
                }
            }
        }

        public Set<Id> getCampaignIds() {
            return nodes.keySet();
        }

        public void setCampaignStatus(List<Campaign> campaigns) {
            queuedCount = 0;
            for (Campaign c : campaigns) {
                if (nodes.containsKey(c.Id)) {
                    nodes.get(c.Id).updateStatus = c.Campaign_List_Update_Status__c;
                    if ('Queued' == c.Campaign_List_Update_Status__c) {
                        queuedCount++;
                    }
                }
            }
        }

        public List<Campaign> getReadyCampaigns() {
            List<Campaign> readyCampaigns = new List<Campaign>();

            for (CampaignNode cn : nodes.values()) {
                if (cn.isReady()) {
                    readyCampaigns.add(new Campaign(
                        Id = cn.campaignId,
                        Campaign_List__c = cn.campaignListId
                    ));
                }
            }

            return readyCampaigns;
        }

        @TestVisible
        private void removeCycles() {
            visitedNodes = new Set<CampaignNode>();
            assignedNodes = new Set<CampaignNode>();
            stronglyConnectedComponents = new Map<CampaignNode, Set<CampaignNode>>();
            leadingNodesStack = new List<CampaignNode>();

            for (CampaignNode cn : nodes.values()) {
                depthFirstVisit(cn);
            }

            for (Integer i = leadingNodesStack.size() - 1; i >= 0; i--) {
                CampaignNode cn = leadingNodesStack.get(i);
                assignToStronglyConnectedComponent(cn, cn);
            }

            for (Set<CampaignNode> ssc : stronglyConnectedComponents.values()) {
                if (ssc.size() > 1) {
                    List<Edge> edgesInComponent = getEdgesBetweenNodes(ssc);
                    List<Edge> edgesToRemove = getEdgesToRemove(edgesInComponent);
                    removeEdges(edgesToRemove);
                }
            }

        }

        private void depthFirstVisit(CampaignNode cn) {
            if (!visitedNodes.contains(cn)) {
                visitedNodes.add(cn);
                for (CampaignNode dependency : cn.dependencies) {
                    depthFirstVisit(dependency);
                }
                leadingNodesStack.add(cn);
           }
        }

        private void assignToStronglyConnectedComponent(CampaignNode cn, CampaignNode root) {
            if (!assignedNodes.contains(cn)) {
                if (!stronglyConnectedComponents.containsKey(root)) {
                    stronglyConnectedComponents.put(root, new Set<CampaignNode>());
                }
                stronglyConnectedComponents.get(root).add(cn);
                assignedNodes.add(cn);
                for (CampaignNode dependant : cn.dependants) {
                    assignToStronglyConnectedComponent(dependant, root);
                }
            }
        }

        private List<Edge> getEdgesBetweenNodes(Set<CampaignNode> nodes) {
            List<Edge> edges = new List<Edge>();

            for (CampaignNode cn : nodes) {
                for (CampaignNode dependency : cn.dependencies) {
                    if (nodes.contains(dependency)) {
                        edges.add(new Edge(cn, dependency));
                    }
                }
            }


            return edges;
        }

        private List<Edge> getEdgesToRemove(List<Edge> edges) {
            List<Edge> left = new List<Edge>();
            List<Edge> right = new List<Edge>();

            for (Edge e : edges) {
                Integer compare = e.fromNode.compareTo(e.toNode);
                if (compare < 0) {
                    left.add(e);
                } else if (compare > 0) {
                    right.add(e);
                }
            }

            if (left.size() < right.size()) {
                return left;
            } else {
                return right;
            }
        }

        private void removeEdges(List<Edge> edges) {
            for (Edge e : edges) {
                if (nodes.containsKey(e.fromNode.campaignId)) {
                    nodes.get(e.fromNode.campaignId).dependencies.remove(e.toNode);
                }
                if (nodes.containsKey(e.toNode.campaignId)) {
                    nodes.get(e.toNode.campaignId).dependants.remove(e.fromNode);
                }
            }
        }
    }

    private static Set<String> finishedStates = new Set<String>{
        'Completed',
        'Aborted',
        'Failed'
    };

    @TestVisible
    private class CampaignNode implements Comparable {
        public Id campaignId;
        public Id campaignListId;
        public String updateStatus = '';
        public Set<CampaignNode> dependencies = new Set<CampaignNode>();
        public Set<CampaignNode> dependants = new Set<CampaignNode>();
        public Boolean visited = false;
        public Boolean inComponent = false;

        public CampaignNode(Id campaignId, Id campaignListId) {
            this.campaignId = campaignId;
            this.campaignListId = campaignListId;
        }

        public Boolean isReady() {
            if ('Queued' != updateStatus) {
                return false;
            }

            Set<String> dependencyStatus = new Set<String>();

            for (CampaignNode cn : dependencies) {
                if (!String.isEmpty(cn.updateStatus)) {
                    dependencyStatus.add(cn.updateStatus);
                }
            }

            return !dependencyStatus.retainAll(finishedStates);
        }

        public Integer hashCode() {
            return ((Object) campaignId).hashCode();
        }

        public Boolean equals(Object other) {
            if (null == other) {
                return false;
            }
            return (0 == compareTo(other));
        }

        public Integer compareTo(Object other) {
            Id otherId = ((CampaignNode) other).campaignId;
            if (campaignId == otherId) {
                return 0;
            }
            if (campaignId > otherId) {
                return 1;
            }
            return -1;
        }
    }

    private class Edge {
        public CampaignNode fromNode;
        public CampaignNode toNode;

        public Edge(CampaignNode fromNode, CampaignNode toNode) {
            this.fromNode = fromNode;
            this.toNode = toNode;
        }
    }

    public class Worker implements Queueable {
        @TestVisible
        private CampaignGraph cg;

        public Worker(CampaignGraph cg) {
            this.cg = cg;
        }

        public void execute(QueueableContext qc) {
            CampaignList.Service service = CampaignList.getService();

            List<Campaign> campaigns = getCampaignsByIds(cg.getCampaignIds());

            cg.setCampaignStatus(campaigns);

            List<Campaign> readyCampaigns = cg.getReadyCampaigns();

            // how much room is in the flex queue if we want to leave at least
            // 50 slots open?
            Integer flexQueueCapacity = service.getFlexQueueCapacity(50);

            // regardless of how much room is in the flex queue, never try to
            // schedule more than 50 per execute
            Integer maxToSchedule = Math.min(
                flexQueueCapacity,
                50
            );

            List<Campaign> campaignsToSchedule = new List<Campaign>();

            // we can't schedule more than are ready...
            Integer numberOfCampaignsToSchedule = Math.min(
                flexQueueCapacity,
                readyCampaigns.size()
            );

            for (Integer i = 0; i < numberOfCampaignsToSchedule; i++) {
                Campaign campaignToSchedule = readyCampaigns.get(i);
                service.updateCampaignFromCampaignList(
                    campaignToSchedule.Id,
                    campaignToSchedule.Campaign_List__c,
                    false
                );
            }

            if (cg.queuedCount > 0) {
                Worker w = new Worker(cg);
                service.enqueueJob(w);
            }
        }
    }
}