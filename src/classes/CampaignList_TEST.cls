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
public class CampaignList_TEST {
    private static Integer nextId = 1;

    public static Id getNextId(Schema.SObjectType sObjectType) {
        String id_x = '' + nextId++;
        while (id_x.length() < 12) {
            id_x = '0' + id_x;
        }
        id_x = sObjectType.getDescribe().getKeyPrefix() + id_x;
        return id_x;
    }

    public class SegmentStub implements CampaignList.Segment {
        public Id segmentId;
        public Id parentId;
        public Id rootSegmentId;
        public Set<Id> acceptIds = new Set<Id>();
        public Boolean meetsCriteria(CampaignList.Member m) {
            return acceptIds.contains(m.getId());
        }
        public Id getId() {
            return segmentId;
        }
        public void setId(Id segmentId) {
            this.segmentId = segmentId;
        }
        public Id getParentId() {
            return null;
        }
        public void setParentId(Id parentId) {
            this.parentId = parentId;
        }
        public Id getRootSegmentId() {
            return null;
        }
        public void setRootSegmentId(Id rootSegmentId) {
            this.rootSegmentId = rootSegmentId;
        }
        public List<CampaignList.Segment> getChildren() {
            return null;
        }
        public Iterator<CampaignList.Segment> iterator() {
            return null;
        }
        public Segment__c getSObject() {
            return null;
        }
        public void addChild(CampaignList.Segment child) {}
    }

    public class MemberMapperStub implements CampaignList.MemberMapper {
        public List<CampaignList.Member> members;
        public Id campaignId;
        public List<Id> relatedIds;
        public Id rootSegmentId;
        public Id sourceId;
        public String sourceName;
        public void addMembersToCampaign(List<CampaignList.Member> members, Id campaignId) {
            this.members = members;
            this.campaignId = campaignId;
        }
        public void updateByRelatedIdsAndSource(List<Id> relatedIds, Id rootSegmentId, Id sourceId, String sourceName) {
            this.relatedIds = relatedIds;
            this.rootSegmentId = rootSegmentId;
            this.sourceId = sourceId;
            this.sourceName = sourceName;
        }
    }

    public class SegmentMapperStub implements CampaignList.SegmentMapper {
        public Id sourceId;
        public Id rootSegmentId;
        public String sourceName;
        public String serialized;
        public CampaignList.Segment rootSegment;
        public String getSourceNameById(Id sourceId) {
            this.sourceId = sourceId;
            return sourceName;
        }
        public CampaignList.Segment getSegmentTreeByRootId(Id rootSegmentId) {
            return null;
        }
        public Id upsertSegmentTreeByRootSegment(CampaignList.Segment rootSegment) {
            this.rootSegment = rootSegment;
            return rootSegmentId;
        }
        public CampaignList.Segment deserializeSegmentFromJSON(String serialized) {
            this.serialized = serialized;
            return null;
        }
    }

    public class ServiceStub implements CampaignList.Service {
        public Id updatedCampaignId;
        public Id updatedRootSegmentId;
        public CampaignList.UpdateStatus updatedStatus;
        public Boolean throwAlreadyRunningException = false;
        public void updateCampaignFromCampaignList(Id campaignId, Id rootSegmentId) {
            updatedCampaignId = campaignId;
            updatedRootSegmentId = rootSegmentId;
            if (throwAlreadyRunningException) {
                throw new CampaignListService.CampaignListUpdateAlreadyRunningException();
            }
        }
        public void updateCampaignStatus(Id campaignId, CampaignList.UpdateStatus status) {
            updatedCampaignId = campaignId;
            updatedStatus = status;
        }
    }

    public class MutexStubFactory implements Mutex.Factory {
        public Id recordId;
        public Schema.SObjectField mutexField;
        public Mutex.MutexInterface m;
        public Mutex.MutexInterface create(Id recordId, Schema.SObjectField mutexField) {
            this.recordId = recordId;
            this.mutexField = mutexField;
            return m;
        }
    }

    public class MutexStub implements Mutex.MutexInterface {
        public Integer acquireLockCalls = 0;
        public Integer releaseLockCalls = 0;
        public Integer getLockTimeCalls = 0;
        public Boolean acquireLock;
        public Boolean releaseLock;
        public DateTime lockTime;
        public Boolean acquireLock() {
            acquireLockCalls++;
            return acquireLock;
        }
        public Boolean releaseLock() {
            releaseLockCalls++;
            return releaseLock;
        }
        public DateTime getLockTime() {
            getLockTimeCalls++;
            return lockTime;
        }
    }

    public class TestCampaign {
        public Campaign campaign;
        public List<Contact> contacts;
        public List<Lead> leads;
        public List<CampaignMember> campaignMembers;

        public TestCampaign(String name, Integer numberOfContacts, Integer numberOfLeads) {
            campaign = new Campaign(Name = name);
            insert campaign;

            contacts = new List<Contact>();
            leads = new List<Lead>();

            for (Integer i = 0; i < numberOfContacts; i++) {
                contacts.add(new Contact(
                    LastName = 'Test' + i
                ));
            }

            insert contacts;

            for (Integer i = 0; i < numberOfLeads; i++) {
                leads.add(new Lead(
                    LastName = 'Test' + i,
                    Company = 'Test Company'
                ));
            }

            insert leads;

            campaignMembers = new List<CampaignMember>();

            for (Contact c : contacts) {
                campaignMembers.add(new CampaignMember(
                    CampaignId = campaign.Id,
                    ContactId = c.Id
                ));
            }

            for (Lead l : leads) {
                campaignMembers.add(new CampaignMember(
                    CampaignId = campaign.Id,
                    LeadId = l.Id
                ));
            }

            insert campaignMembers;
        }
    }
}