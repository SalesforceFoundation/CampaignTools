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
* @description test code for the SegmentTreeProcessor class
*
*/
@isTest
public with sharing class SegmentTreeProcessor_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    /*********************************************************************************************************
    * @description test processing a single leaf tree where the source should be included; 
    */	
    static testMethod void testSingleLeafIn() {
        if (strTestOnly != '*' && strTestOnly != 'testSingleLeafIn') return;
        
        Segment__c seg = new Segment__c();
        seg.Exclude_Source__c = false;
        seg.Source_ID__c = 'foo';
        seg.Source_Type__c = 'Campaign';
        insert seg;
        
        list<Member__c> listMember = new list<Member__c>();
        Member__c member = new Member__c();
        member.Root_Segment__c = seg.Id;
        member.Sources__c = seg.Source_ID__c;
        listMember.add(member);
        insert listMember;
        
        CSegment cseg = new CSegment(seg);
        
        SegmentTreeProcessor.processSegmentTree(cseg, listMember);
        system.assertEquals(true, listMember[0].Include_in_List__c);
    }

    /*********************************************************************************************************
    * @description test processing a single leaf tree where the source was not found.
    */  
    static testMethod void testSingleLeafOut() {
        if (strTestOnly != '*' && strTestOnly != 'testSingleLeafOut') return;
        
        Segment__c seg = new Segment__c();
        seg.Exclude_Source__c = false;
        seg.Source_ID__c = 'foo';
        seg.Source_Type__c = 'Campaign';
        insert seg;
        
        list<Member__c> listMember = new list<Member__c>();
        Member__c member = new Member__c();
        member.Root_Segment__c = seg.Id;
        member.Sources__c = 'bar';
        listMember.add(member);
        insert listMember;
        
        CSegment cseg = new CSegment(seg);
        
        SegmentTreeProcessor.processSegmentTree(cseg, listMember);
        system.assertEquals(false, listMember[0].Include_in_List__c);
    }

    /*********************************************************************************************************
    * @description test processing a single leaf tree where the source should be excluded 
    */  
    static testMethod void testSingleLeafExclude() {
        if (strTestOnly != '*' && strTestOnly != 'testSingleLeafExclude') return;
        
        Segment__c seg = new Segment__c();
        seg.Exclude_Source__c = true;
        seg.Source_ID__c = 'foo';
        seg.Source_Type__c = 'Campaign';
        insert seg;
        
        list<Member__c> listMember = new list<Member__c>();
        Member__c member = new Member__c();
        member.Root_Segment__c = seg.Id;
        member.Sources__c = 'foo';
        listMember.add(member);
        insert listMember;
        
        CSegment cseg = new CSegment(seg);
        
        SegmentTreeProcessor.processSegmentTree(cseg, listMember);
        system.assertEquals(false, listMember[0].Include_in_List__c);
    }

    /*********************************************************************************************************
    * @description creates a segment tree of sample data for testing purposes.
    * the logic represented is all contacts in list B or (D and E)
    *       A
    *       B   C
    *           D   E
    *
    *   A (B C(D, E))
    *
    * A is root
    * B, D, E are leafs
    */  
    public static Segment__c segTreeTestData(string srcB, string srcD, string srcE, boolean createCampaigns) {
    
        if (createCampaigns) {
	        Campaign cmpB = new Campaign(name=srcB);
	        Campaign cmpD = new Campaign(name=srcD);
	        Campaign cmpE = new Campaign(name=srcE);
	        insert cmpB;
	        insert cmpD;
	        insert cmpE;
	        srcB = cmpB.Id;
	        srcD = cmpD.Id;
	        srcE = cmpE.Id;
        }
        
        Segment__c rootSegment = new Segment__c(Operation__c=Label.logicOR);
        insert rootSegment;
        
        list<Segment__c> childSegments = new list<Segment__c>();
        for (integer i=0; i < 2; i++) {
            childSegments.add(new Segment__c(
                Root_Segment__c = rootSegment.id,
                Parent_Segment__c = rootSegment.id
            ));
        }
        childSegments[0].Operation__c = 'SOURCE';
        childSegments[0].Source_ID__c = srcB;
        childSegments[0].Source_Type__c = 'Campaign';
        childSegments[1].Operation__c = label.logicAND;
        insert childSegments;

        list<Segment__c> gchildSegments = new list<Segment__c>();
        for (integer i=0; i < 2; i++) {
            gchildSegments.add(new Segment__c(
                Operation__c = 'SOURCE',
                Root_Segment__c = rootSegment.id,
                Parent_Segment__c = childSegments[1].id
            ));
        }
        gchildSegments[0].Source_ID__c = srcD;
        gchildSegments[0].Source_Type__c = 'Campaign';
        gchildSegments[1].Source_ID__c = srcE;
        gchildSegments[1].Source_Type__c = 'Campaign';
        insert gchildSegments;

        return rootSegment;
    }
    
    /*********************************************************************************************************
    * @description test processing a tree w/ children & grandchildren where the sources should be included; 
    */  
    static testMethod void testSimpleTreeIn() {
        if (strTestOnly != '*' && strTestOnly != 'testSimpleTreeIn') return;
        
        // A (B C(D, E))
        CSegment csegRoot = SegmentMapper.mapRootSegment(segTreeTestData('B0', 'D0', 'E0', true));
        
        // create Members list with combinations of sources B, D, E
        list<Segment__c> listSrc = [select Id, Source_ID__c from Segment__c where Source_ID__c != null 
            order by Source_ID__c];
        system.assertEquals(3, listSrc.size());
        list<Campaign> listCmp = [select Id, Name from Campaign order by Name];
        system.assertEquals(3, listCmp.size());
        string idB = listCmp[0].Id;            
        string idD = listCmp[1].Id;
        string idE = listCmp[2].Id;
        list<Member__c> listMember = new list<Member__c>();
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idD+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idD+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idD+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idD+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c='XXXXXXXXXX;'));
        insert listMember;        

        // process the members against the segment tree
        SegmentTreeProcessor.processSegmentTree(csegRoot, listMember);
        
        // verify which are included for (B or (D and E))
        system.assertEquals(true, listMember[0].Include_in_List__c);
        system.assertEquals(true, listMember[1].Include_in_List__c);
        system.assertEquals(true, listMember[2].Include_in_List__c);
        system.assertEquals(false, listMember[3].Include_in_List__c);
        system.assertEquals(false, listMember[4].Include_in_List__c);
        system.assertEquals(true, listMember[5].Include_in_List__c);
        system.assertEquals(true, listMember[6].Include_in_List__c);
        system.assertEquals(false, listMember[7].Include_in_List__c);

    }

    /*********************************************************************************************************
    * @description test processing a tree w/ children & grandchildren where some sources should be excluded; 
    */  
    static testMethod void testSimpleTreeExclude() {
        if (strTestOnly != '*' && strTestOnly != 'testSimpleTreeExclude') return;
        
        // A (B C(D, E))
        // change E to be an Exclude
        Segment__c segRoot = segTreeTestData('B1', 'D1', 'E1', true);
        Campaign cmpE = [select Id from Campaign where Name = 'E1'];
        list<Segment__c> listSeg = [select Id from Segment__c where Source_ID__c = :cmpE.Id];
        system.assertEquals(1, listSeg.size());
        listSeg[0].Exclude_Source__c = true;
        upsert listSeg;
        CSegment csegRoot = SegmentMapper.mapRootSegment(segRoot);
        
        
        // create Members list with combinations of sources B, D, E
        list<Segment__c> listSrc = [select Id, Source_ID__c from Segment__c where Source_ID__c != null 
            order by Source_ID__c];
        system.assertEquals(3, listSrc.size());
        list<Campaign> listCmp = [select Id, Name from Campaign order by Name];
        system.assertEquals(3, listCmp.size());
        string idB = listCmp[0].Id;            
        string idD = listCmp[1].Id;
        string idE = listCmp[2].Id;
        list<Member__c> listMember = new list<Member__c>();
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idD+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idD+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idD+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idD+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c='XXXXXXXXXX;'));
        insert listMember;        

        // process the members against the segment tree
        SegmentTreeProcessor.processSegmentTree(csegRoot, listMember);
        
        // verify which are included for (B or (D and !E))
        system.assertEquals(true, listMember[0].Include_in_List__c);
        system.assertEquals(true, listMember[1].Include_in_List__c);
        system.assertEquals(true, listMember[2].Include_in_List__c);
        system.assertEquals(true, listMember[3].Include_in_List__c);
        system.assertEquals(false, listMember[4].Include_in_List__c);
        system.assertEquals(false, listMember[5].Include_in_List__c);
        system.assertEquals(true, listMember[6].Include_in_List__c);
        system.assertEquals(false, listMember[7].Include_in_List__c);

    }

    /*********************************************************************************************************
    * @description test processing a tree w/ children & grandchildren where some sources should be excluded; 
    */  
    static testMethod void testSimpleTreeExclude2() {
        if (strTestOnly != '*' && strTestOnly != 'testSimpleTreeExclude2') return;
        
        // A (B C(D, E))
        // change B to be an Exclude
        Segment__c segRoot = segTreeTestData('B2', 'D2', 'E2', true);
        Campaign cmpB = [select Id from Campaign where Name = 'B2'];
        list<Segment__c> listSeg = [select Id from Segment__c where Source_ID__c = :cmpB.Id];
        system.assertEquals(1, listSeg.size());
        listSeg[0].Exclude_Source__c = true;
        upsert listSeg;
        // change root node to be an AND
        segRoot.Operation__c = Label.logicAND;
        upsert segRoot;
                
        CSegment csegRoot = SegmentMapper.mapRootSegment(segRoot);
        
        
        // create Members list with combinations of sources B, D, E
        list<Segment__c> listSrc = [select Id, Source_ID__c from Segment__c where Source_ID__c != null 
            order by Source_ID__c];
        system.assertEquals(3, listSrc.size());
        list<Campaign> listCmp = [select Id, Name from Campaign order by Name];
        system.assertEquals(3, listCmp.size());
        string idB = listCmp[0].Id;            
        string idD = listCmp[1].Id;
        string idE = listCmp[2].Id;
        list<Member__c> listMember = new list<Member__c>();
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idD+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idD+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idD+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idD+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c='XXXXXXXXXXX;'));
        insert listMember;        

        // process the members against the segment tree
        test.startTest();
        SegmentTreeProcessor.processSegmentTree(csegRoot, listMember);
        test.stopTest();
        
        // verify which are included for (!B and (D and E))
        system.assertEquals(false, listMember[0].Include_in_List__c);
        system.assertEquals(false, listMember[1].Include_in_List__c);
        system.assertEquals(false, listMember[2].Include_in_List__c);
        system.assertEquals(false, listMember[3].Include_in_List__c);
        system.assertEquals(false, listMember[4].Include_in_List__c);
        system.assertEquals(true, listMember[5].Include_in_List__c);
        system.assertEquals(false, listMember[6].Include_in_List__c);
        system.assertEquals(false, listMember[7].Include_in_List__c);
    }
}