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
private with sharing class SegmentTreeProcessor_TEST {

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
    * @description test processing a single leaf tree where the source should not be included; 
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
    static CSegment csegTreeTestData() {

        Segment__c rootSegment = new Segment__c(Operation__c=Label.logicOR);
        insert rootSegment;
        
        list<Segment__c> childSegments = new list<Segment__c>();
        for (integer i=0; i < 2; i++) {
            childSegments.add(new Segment__c(
                Operation__c = Label.logicOR,
                Root_Segment__c = rootSegment.id,
                Parent_Segment__c = rootSegment.id
            ));
        }
        childSegments[0].Source_ID__c = 'B';
        childSegments[1].Operation__c = label.logicAND;
        insert childSegments;

        list<Segment__c> gchildSegments = new list<Segment__c>();
        for (integer i=0; i < 2; i++) {
            gchildSegments.add(new Segment__c(
                Root_Segment__c = rootSegment.id,
                Parent_Segment__c = childSegments[1].id
            ));
        }
        gchildSegments[0].Source_ID__c = 'D';
        gchildSegments[1].Source_ID__c = 'E';
        insert gchildSegments;

        CSegment csegRoot = SegmentMapper.mapRootSegment(rootSegment);
        return csegRoot;
    }
    
    /*********************************************************************************************************
    * @description test processing a tree w/ children & grandchildren where the sources should be included; 
    */  
    static testMethod void testSimpleTreeIn() {
        if (strTestOnly != '*' && strTestOnly != 'testSimpleTreeIn') return;
        
        // A (B C(D, E))
        CSegment csegRoot = csegTreeTestData();
        
        // create Members list with combinations of sources B, D, E
        list<Segment__c> listSrc = [select Id, Source_ID__c from Segment__c where Source_ID__c != null 
            order by Source_ID__c];
        system.assertEquals(3, listSrc.size());
        string idB = listSrc[0].Source_ID__c;            
        string idD = listSrc[1].Source_ID__c;
        string idE = listSrc[2].Source_ID__c;
        list<Member__c> listMember = new list<Member__c>();
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idD+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idD+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idD+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c=idB+';'+idD+';'+idE+';'));
        listMember.add(new Member__c(Root_Segment__c = csegRoot.Segment.Id, Sources__c='X;'));
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

}