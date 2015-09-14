/*
    Copyright (c) 2015 Salesforce.com Foundation
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
* @author Salesforce.com Foundation
* @date 2015
*
* @group Segments
*
* @description Apex controller for the Lightning CampaignListBuilder app.
*
*/

public with sharing class CampaignListBuilder_CTRL {

    @AuraEnabled
    public static CSegment getCSegmentTree(ID segmentId) {
        Segment__c segRoot = [select Id from Segment__c where Id = :segmentId];
        CSegment csegRoot = SegmentMapper.mapRootSegment(segRoot, false);
        return csegRoot;
    }
    
    @AuraEnabled
    public static boolean saveCSegmentTree(ID campaignId, string csegRoot) {
        system.debug('**** saveCSegmentTree called with csegRoot: ' + csegRoot);
        csegRoot = csegRoot.replace(',"sobjectType":"Segment__c"', '');
        system.debug('**** after cleanup csegRoot: ' + csegRoot);
        CSegment cseg = (CSegment)JSON.deserialize(csegRoot, Type.forName('CSegment'));
        system.debug('**** cseg is: ' + cseg);
        
        // save it!
        SegmentTreeSave.saveCSegmentTree(campaignId, cseg);
        
        return true;
    }

    /*
    @AuraEnabled
    public static list<Segment__c> getSegments(ID segmentId) {
        return [select Id, Exclude_Source__c, Operation__c, Parent_Segment__c, Root_Segment__c, Source_ID__c, Source_Type__c 
            from Segment__c where Root_Segment__c = :segmentId or Id = :segmentId order by Id];
    }
    */

    @AuraEnabled
    public static Campaign getCampaign(ID campaignId) {
        if (campaignId == null)
            return null;
        return [select Id, Name, Campaign_List__c from Campaign where Id = :campaignId];
    }	
}