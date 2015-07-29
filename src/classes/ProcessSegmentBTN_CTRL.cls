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
* @description Button controller for the Refresh Campaign List button on a campaign.
*
*/

public with sharing class ProcessSegmentBTN_CTRL {

    private Campaign campaign { get; set; }
    private PageReference pgRet { get; set; }
    
    /*******************************************************************************************************
    * @description Constructor
    * @param controller StandardController to a Campaign
    ********************************************************************************************************/
    public ProcessSegmentBTN_CTRL(ApexPages.StandardController controller) {           
        campaign = (Campaign)controller.getRecord();
        pgRet = new PageReference('/' + campaign.Id);
    }

    /*******************************************************************************************************
    * @description Action Method invoked by the Refresh Campaign List button on a campaign.
    * @return PageReference null, to cause the campaign's detail page to refresh.
    ********************************************************************************************************/
    public PageReference refreshCampaignList() {
        campaign = [select Id, Campaign_List__c from Campaign where Id = :campaign.Id];

        if (campaign.Campaign_List__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no saved Campaign List for this campaign.'));
            return null;
        }
        
        // first we populate Members object with all potential people to include on the list.
        system.debug('**** Campaign_List__c: ' + campaign.Campaign_List__c);
        MembersBuilder mb = new MembersBuilder(campaign.Campaign_List__c);
        
        // next we instantiate our wrapper around the saved Segment for use in processing.
        Segment__c segRoot = [select Id from Segment__c where Id = :campaign.Campaign_List__c];
        system.debug('**** segRoot: ' + segRoot);
        CSegment csegRoot = SegmentMapper.mapRootSegment(segRoot);
        system.debug('**** csegRoot: ' + csegRoot);
        
        // now we process each member against the Segment tree, seeing if the member should be in the final list
        list<Member__c> listMember = [select Id, Sources__c, Contact__c, Lead__c, Source_Names__c, Include_In_List__c from Member__c where Root_Segment__c = :segRoot.Id];
        system.debug('**** listMember before processing: ' + listMember);
        SegmentTreeProcessor.processSegmentTree(csegRoot, listMember);
        system.debug('**** listMember after processing: ' + listMember);
        
        // populate the campaign with the included members.
        CampaignPopulate.populateCampaignWithMembers(campaign.Id, listMember);
        
        // finally, remove all temporary member records
        delete listMember;
        
        // return back to the campaign.
        return pgRet;
    }

}