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
        campaign = [select Campaign_List__c from Campaign where Id = :campaign.Id];

        if (campaign.Campaign_List__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no saved Campaign List for this campaign.'));
            return null;
        }
        
        /***
        MembersBuilder mb = new MembersBuilder(campaign.Campaign_List__c);
        ****/
        
        Segment__c segRoot = [select Id from Segment__c where Id = :campaign.Campaign_List__c];
        CSegment csegRoot = SegmentMapper.mapRootSegment(segRoot);
        
        list<Member__c> listMember = [select Id, Sources__c from Member__c where Root_Segment__c = :segRoot.Id];
        SegmentTreeProcessor.processSegmentTree(csegRoot, listMember);
        return pgRet;
    }

}