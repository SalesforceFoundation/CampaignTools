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
 * @description Trigger Handler on Campaign
 */
public with sharing class CampaignTriggerHandler {
    /** @description A static map of the original state of the new or updated campaign objects */
    private static Map<Id, Campaign> mapNewOldCamp = new Map<Id, Campaign>();
    /** @description A static list AsyncApexJobs that match the CampaignListRefresh criteria */
    private static List<AsyncApexJob> listCampRefreshJobs;
    /** @description Boolean flag to determine if validation should run defaults to true if test not running */
    @TestVisible private static Boolean validate = !Test.isRunningTest();

    /*******************************************************************************************************
     * @description Trigger Handler on Campaign to validate the campaign objects before insert
     * @param listNewCamp the list of Campaigns from trigger new
     *******************************************************************************************************/
    public static void handleBeforeInsert(List<Campaign> listNewCamp) {
        validateCampaignRefresh(new List<Campaign>(), listNewCamp);
        onBeforeInsert(listNewCamp);
    }
    /*******************************************************************************************************
     * @description Trigger Handler on Campaign to validate the campaign objects before update
     * @param listOldCamp the list of Campaigns from trigger old
     * @param listNewCamp the list of Campaigns from trigger new
     *******************************************************************************************************/
    public static void handleBeforeUpdate(List<Campaign> listOldCamp, List<Campaign> listNewCamp) {
        validateCampaignRefresh(listOldCamp, listNewCamp);
    }
    /*******************************************************************************************************
     * @description Adds an error to any campaign set to refresh when a schedule is not present
     * @param listOldCamp the list of Campaigns from trigger old
     * @param listNewCamp the list of Campaigns from trigger new
     *******************************************************************************************************/
    public static void validateCampaignRefresh(List<Campaign> listOldCamp, List<Campaign> listNewCamp) {
        // return when not validating the records or the campaign refresh job is scheduled
        if (!validate || isCampaignRefreshScheduled())
            return;
        Map<Id, Campaign> mapOldCamp = new Map<Id, Campaign>(listOldCamp);
        for (Campaign newCamp : listNewCamp) {
            Campaign oldCamp;
            if (mapNewOldCamp.containsKey(newCamp.Id)) {
                oldCamp = mapNewOldCamp.get(newCamp.Id);
            } else {
                oldCamp = mapOldCamp.containsKey(newCamp.Id) ? mapOldCamp.get(newCamp.Id) : new Campaign();
                mapNewOldCamp.put(newCamp.Id, newCamp);
            }
            if (newCamp.Campaign_List_Refresh_Automatically__c && !oldCamp.Campaign_List_Refresh_Automatically__c) {
                newCamp.addError(Label.CampaignToolsRefreshScheduleValidation, false);
            }
        }
    }
    /*******************************************************************************************************
     * @description On newly inserted records check if cloned from a campaign with a campaign list
     * @param listNewCamp the list of Campaigns from trigger new
     *******************************************************************************************************/
    public static void onBeforeInsert(List<Campaign> listNewCamp) {
        /** @description A map of the original campaign list Ids to the newly cloned Campaign Record */
        Map<Id, Campaign> srcIdToClonedCampaigns = new Map<Id, Campaign>();
        // loop through all newly created campaign records and if they are a clone with a list add to map
        for (Campaign newCamp : listNewCamp) {
            if (newCamp.isClone() && newCamp.Campaign_List__c != null) {
                srcIdToClonedCampaigns.put(newCamp.Campaign_List__c, newCamp);
            }
        }
        if (srcIdToClonedCampaigns.size() > 0) {
            /** @description A map of all root and children segments related to the cloned campaigns with a list */
            Map<Id, Segment__c> mapSrcSegments = new Map<Id, Segment__c>(
                new CampaignListSegmentMapper().queryByRootSegmentId(srcIdToClonedCampaigns.keySet()));
            /** @description A deep clone of the list of related segments */
            List<Segment__c> clonedSegments = mapSrcSegments.values().deepClone();
            // clear out the existing hierarchy before inserting the new segments
            for (Segment__c clonedSegment : clonedSegments) {
                clonedSegment.Parent_Segment__c = null;
                clonedSegment.Root_Segment__c = null;
            }
            insert clonedSegments;
            /** @description A map of the original segment Id to the new segment Id */
            Map<Id, Id> mapSrcIdToClonedId = new Map<Id, Id>();
            for (Segment__c clonedSegment : clonedSegments) {
                mapSrcIdToClonedId.put(clonedSegment.getCloneSourceId(), clonedSegment.Id);
            }
            // update the hierarchy with the new ids and set the new root segment id on the campaign
            for (Segment__c clonedSegment : clonedSegments) {
                Segment__c srcSegment = mapSrcSegments.get(clonedSegment.getCloneSourceId());
                clonedSegment.Parent_Segment__c = srcSegment.Parent_Segment__c == null ? null : mapSrcIdToClonedId.get(srcSegment.Parent_Segment__c);
                clonedSegment.Root_Segment__c = srcSegment.Root_Segment__c == null ? null : mapSrcIdToClonedId.get(srcSegment.Root_Segment__c);
                if (srcIdToClonedCampaigns.containsKey(srcSegment.Id))
                    srcIdToClonedCampaigns.get(srcSegment.Id).Campaign_List__c = mapSrcIdToClonedId.get(srcSegment.Id);
            }
            upsert clonedSegments;
        }
    }
    /*******************************************************************************************************
     * @description Check to see if the refresh job is scheduled
     * @return Boolean true when job is scheduled
     *******************************************************************************************************/
    public static Boolean isCampaignRefreshScheduled() {
        if (listCampRefreshJobs == null){
            // scheduled Apex jobs will always stays in the Queued status until the job has no NextFireTime,
            // then it gets marked Completed, or if the job is aborted then it gets marked Aborted
            listCampRefreshJobs = [SELECT Id FROM AsyncApexJob
                WHERE JobType = 'ScheduledApex' AND Status ='Queued'
                AND ApexClass.Name = 'CampaignListRefreshSchedulable'];
        }
        return !listCampRefreshJobs.isEmpty();
    }
}