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
* @description Test code for the SegmentTreeSave class
*
*/
@isTest
public with sharing class SegmentTreeSave_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    
    /*********************************************************************************************************
    * @description statics to hold our test data
    */  
    private static Campaign cmp;
    private static Campaign cmpSrc1;
    private static Campaign cmpSrc2;
    private static CSegment csegRoot;
    private static CSegment csegAnd;
    private static CSegment csegSrc1;
    private static CSegment csegSrc2;
    
    /*********************************************************************************************************
    * @description create a CSegment Tree in memory of the form root(AND(src1, src2)) 
    */  
    private static void createTestData() {
        cmp = new Campaign(name='test campaign');
        insert cmp;
        
        cmpSrc1 = new Campaign(name='src1');
        insert cmpSrc1;
        
        cmpSrc2 = new Campaign(name='src2');
        insert cmpSrc2;
        
        // let's create a tree that looks like root(AND(src1, src2))
        // so four segments.
        Segment__c segRoot = new Segment__c();
        csegRoot = new CSegment(segRoot);
        
        Segment__c segAnd = new Segment__c(Operation__c='AND');
        csegAnd = new CSegment(segAnd);
        //csegAnd.rootCSegment = csegRoot;
        csegRoot.listChildCSegments.add(csegAnd);
        
        Segment__c segSrc1 = new Segment__c(Operation__c='SOURCE', Source_Type__c='Campaign', Source_Id__c=cmpSrc1.Id);
        csegSrc1 = new CSegment(segSrc1);
        //csegSrc1.rootCSegment = csegRoot;
        //csegSrc1.parentCSegment = csegAnd;
        csegAnd.listChildCSegments.add(csegSrc1);
        
        Segment__c segSrc2 = new Segment__c(Operation__c='SOURCE', Source_Type__c='Campaign', Source_Id__c=cmpSrc2.Id);
        csegSrc2 = new CSegment(segSrc2);
        //csegSrc2.rootCSegment = csegRoot;
        //csegSrc2.parentCSegment = csegAnd;
        csegAnd.listChildCSegments.add(csegSrc2);
    }
        
    /*********************************************************************************************************
    * @description test saving a new tree 
    */  
    static testMethod void testSaveNewTree() {
        if (strTestOnly != '*' && strTestOnly != 'testSaveNewTree') return;
        
        createTestData();
        
        Test.startTest();
        SegmentTreeSave.saveCSegmentTree(cmp.Id, csegRoot);
        Test.stopTest();
        
        list<Segment__c> listSeg = [select Id, Exclude_Source__c, Operation__c, Parent_Segment__c, Root_Segment__c, Source_ID__c, Source_Type__c 
            from Segment__c order by Id];
        system.assertEquals(4, listSeg.size());
        for (integer i = 0; i < 4; i++) {
            Segment__c seg = listSeg[i];
            if (i == 0) {
                system.assertEquals(null, seg.Root_Segment__c);
                system.assertEquals(null, seg.Parent_Segment__c);
            } else {
                system.assertEquals(listSeg[0].Id, seg.Root_Segment__c);
                system.assertNotEquals(null, seg.Parent_Segment__c);
            }
        }
        
        cmp = [select Id, name, Campaign_List__c from Campaign where Id = :cmp.Id];
        system.assertEquals(listSeg[0].Id, cmp.Campaign_List__c);
    }

    /*********************************************************************************************************
    * @description test saving an existing modified tree 
    */  
    static testMethod void testSaveExistingTree() {
        if (strTestOnly != '*' && strTestOnly != 'testSaveExistingTree') return;
        
        createTestData();
        SegmentTreeSave.saveCSegmentTree(cmp.Id, csegRoot);
        list<Segment__c> listSeg = [select Id, Exclude_Source__c, Operation__c, Parent_Segment__c, Root_Segment__c, Source_ID__c, Source_Type__c 
            from Segment__c order by Id];
        system.assertEquals(4, listSeg.size());
        
        // now let's prune the tree, resave, and make sure the no longer referenced segments get deleted.
        system.assertEquals(2, csegAnd.listChildCSegments.size());
        csegAnd.listChildCSegments.remove(1);

        Test.startTest();
        SegmentTreeSave.saveCSegmentTree(cmp.Id, csegRoot);
        Test.stopTest();
        
        listSeg = [select Id, Exclude_Source__c, Operation__c, Parent_Segment__c, Root_Segment__c, Source_ID__c, Source_Type__c 
            from Segment__c order by Id];
        system.assertEquals(3, listSeg.size());
        for (integer i = 0; i < 3; i++) {
            Segment__c seg = listSeg[i];
            if (i == 0) {
                system.assertEquals(null, seg.Root_Segment__c);
                system.assertEquals(null, seg.Parent_Segment__c);
            } else {
                system.assertEquals(listSeg[0].Id, seg.Root_Segment__c);
                system.assertNotEquals(null, seg.Parent_Segment__c);
            }
        }
        
        cmp = [select Id, name, Campaign_List__c from Campaign where Id = :cmp.Id];
        system.assertEquals(listSeg[0].Id, cmp.Campaign_List__c);
    }

    /*********************************************************************************************************
    * @description test saving an existing modified tree 
    */  
    static testMethod void testJSON() {
        if (strTestOnly != '*' && strTestOnly != 'testJSON') return;
        
        createTestData();
        SegmentTreeSave.saveCSegmentTree(cmp.Id, csegRoot);
        list<Segment__c> listSeg = [select Id, Exclude_Source__c, Operation__c, Parent_Segment__c, Root_Segment__c, Source_ID__c, Source_Type__c 
            from Segment__c order by Id];
        system.assertEquals(4, listSeg.size());
        
        // can we parse it?
        string strJSON = JSON.serialize(csegRoot);
        system.debug('**** serializePretty: ' + csegRoot);
        CSegment csegDe = (CSegment)JSON.deserialize(strJSON, Type.forName('CSegment'));
        system.debug('**** deserialized: ' + csegDe);
   }
   
    /*********************************************************************************************************
    * @description test saving an existing modified tree 
    */  
    static testMethod void testJSON2() {
        if (strTestOnly != '*' && strTestOnly != 'testJSON2') return;
        
        string strJSON = 
//'{"listChildCSegments":[{"listChildCSegments":[],"Segment”:{“Source_ID__c":"70137000000IaIC","Operation__c":"SOURCE","Source_Type__c":"Campaign","Root_Segment__c":"a04370000010ZDTAA2","Id":"a04370000010YvQAAU","Exclude_Source__c":false,"Parent_Segment__c":"a04370000010YvBAAU"},"rootCSegment":null,"parentCSegment":null},{"listChildCSegments":[],"Segment":{"Source_ID__c":"70137000000IaIM","Operation__c":"SOURCE","Source_Type__c":"Campaign","Root_Segment__c":"a04370000010ZDTAA2","Id":"a04370000010YziAAE","Exclude_Source__c":false,"Parent_Segment__c":"a04370000010YvBAAU"},"rootCSegment":null,"parentCSegment":null}],"Segment":{"Operation__c":"OR","Root_Segment__c":"a04370000010ZDTAA2","Id":"a04370000010YvBAAU","Exclude_Source__c":false,"Parent_Segment__c":"a04370000010ZDTAA2","Segments__r":[{"Id":"a04370000010YvQAAU","Parent_Segment__c":"a04370000010YvBAAU"},{"Id":"a04370000010YziAAE","Parent_Segment__c":"a04370000010YvBAAU"}]},"rootCSegment":null,"parentCSegment":null}';
        

'{"listChildCSegments":[{"listChildCSegments":[],"Segment":{"Source_ID__c":"70137000000IaIC","Operation__c":"SOURCE","Source_Type__c":"Campaign","Root_Segment__c":"a04370000010ZDTAA2","Id":"a04370000010YvQAAU","Exclude_Source__c":false,"Parent_Segment__c":"a04370000010YvBAAU"},"rootCSegment":null,"parentCSegment":null},{"listChildCSegments":[],"Segment":{"Source_ID__c":"70137000000IaIM","Operation__c":"SOURCE","Source_Type__c":"Campaign","Root_Segment__c":"a04370000010ZDTAA2","Id":"a04370000010YziAAE","Exclude_Source__c":false,"Parent_Segment__c":"a04370000010YvBAAU"},"rootCSegment":null,"parentCSegment":null}],"Segment":{"Operation__c":"OR","Root_Segment__c":"a04370000010ZDTAA2","Id":"a04370000010YvBAAU","Exclude_Source__c":false,"Parent_Segment__c":"a04370000010ZDTAA2"},"rootCSegment":null,"parentCSegment":null}';
        
        CSegment csegDe = (CSegment)JSON.deserialize(strJSON, Type.forName('CSegment'));
        system.debug('**** deserialized: ' + csegDe);
   }
}