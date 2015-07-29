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
* @description Test code for the Refresh Campaign List button on a campaign.
*
*/
@isTest
public with sharing class ProcessSegmentBTN_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    @isTest
    public static void testProcessSegment1() {
        if (strTestOnly != '*' && strTestOnly != 'testProcessSegment1') return;
        
        // create test data

        // need campaigns for leaf nodes B, D, E
        list<Campaign> listCmp = new list<Campaign>();
        list<Contact> listContact = new list<Contact>();
        list<CampaignMember> listCM = new list<CampaignMember>();
        
        for (integer i = 0; i < 3; i++) {
            listCmp.add(new Campaign(name='TestCmp' + i));
            for (integer j = 0; j < 3; j++) {
                listContact.add(new Contact(Lastname='contact' + i +',' + j));
            }
        }
        insert listCmp;
        insert listContact;
        for (integer i = 0; i < 3; i++) {
            for (integer j = 0; j < 3; j++) {
                listCM.add(new CampaignMember(CampaignId = listCmp[i].Id, ContactId = listContact[(i * 3) + j].Id));
            }
        }
        insert listCM;
        system.assertEquals(9, [select count() from CampaignMember]);
        
        // now create our Segment Tree with the campaign Id's
        // contacts in list B or (D and E)
        Segment__c segRoot = SegmentTreeProcessor_TEST.segTreeTestData(listCmp[0].Id, listCmp[1].Id, listCmp[2].Id); 
                
        // our test campaign to fill
        Campaign cmp = new Campaign();
        cmp.Name = 'Test Campaign';
        cmp.Campaign_List__c = segRoot.Id;
        insert cmp;
        
	    //now run our button
	    Test.startTest();
	    ApexPages.StandardController sc = new ApexPages.StandardController(cmp);
	    ProcessSegmentBTN_CTRL btn = new ProcessSegmentBTN_CTRL(sc);
	    PageReference pr = btn.refreshCampaignList();
	    Test.stopTest();
	    
	    // validate data
	    system.assertNotEquals(null, pr);
	    listCM = [select Id from CampaignMember where CampaignId = :cmp.Id];
	    system.assertEquals(3, listCM.size());

    }

}