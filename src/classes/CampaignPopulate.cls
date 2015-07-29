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

public with sharing class CampaignPopulate {

    public static void populateCampaignWithMembers(ID cmpId, list<Member__c> listMember) {
    
        // for now, we blindly clear the campaign
        delete [select Id from CampaignMember where CampaignId = :cmpId];
        
        // now add each Member to a CampaignMember
        list<CampaignMember> listCM = new list<CampaignMember>();
        for (Member__c member : listMember) {
            if (!member.Include_In_List__c) 
                continue;
            CampaignMember cm = new CampaignMember();
            cm.CampaignId = cmpId;
            if (member.Contact__c != null)
                cm.ContactId = member.Contact__c;
            if (member.Lead__c != null)
                cm.LeadId = member.Lead__c;
            cm.Source_Names__c = member.Source_Names__c;
            system.debug('**** cm: ' + cm);
            listCM.add(cm);
        }
        insert listCM;
    }

}