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
* @description contains the logic to take an in-memory segment tree, for a
* given campaign, and persist it to the segment__c object table.
*
*/
public with sharing class SegmentTreeSave {

    /*******************************************************************************************************
    * @description Saves the campaign's Campaign List segment tree to Salesforce.  Handles both new and
    * updated segment trees.
    * @param campaignId The Campaign's Id
    * @param csegRoot The root csegment of the segment tree
    * @return void
    ********************************************************************************************************/
    public static void saveCSegmentTree(ID campaignId, CSegment csegRoot) {
    
        // strategy: using a recursive strategy, insert or update the parent segments,
        // and then save their children.  Since Segments__c have a lookup to their parent (and root)
        // we must save those first to get their id's.
        
        // to handle updates to existing segment trees, we also have to track which of the
        // original segments is no longer in the tree.
        map<Id, Segment__c> mapIdSegmentOriginal = new map<ID, Segment__c>();
        if (csegRoot.Segment.Id != null)
            mapIdSegmentOriginal.putAll([select Id from Segment__c where Root_Segment__c = :csegRoot.Segment.Id]);
        
        // we upsert the root, and then we can handle all the descendants
        upsert csegRoot.Segment;
        list<Segment__c> listSegmentSaved = new list<Segment__c>();
        saveCSegmentChildren(csegRoot, csegRoot, listSegmentSaved);
        
        // now figure out which old segments need to be deleted.
        for (Segment__c seg : listSegmentSaved) {
            if (mapIdSegmentOriginal.containsKey(seg.Id))
                mapIdSegmentOriginal.remove(seg.Id);
        }
        
        // delete any old segments
        if (!mapIdSegmentOriginal.isEmpty())
            delete mapIdSegmentOriginal.values();
        
        // update the campaign
        Campaign cmp = new Campaign(Id = campaignId, Campaign_List__c = csegRoot.Segment.Id);
        update cmp;
    }
    
    /*******************************************************************************************************
    * @description Saves the children and descendant Segments of the passed in tree.  Handles both new and
    * updated segment trees.
    * @param csegRoot The root csegment of the segment tree
    * @param csegParent The parent csegment whose children need saving
    * @param listSegmentSaved The list of segments saved by this function
    * @return void
    ********************************************************************************************************/
    private static void saveCSegmentChildren (CSegment csegRoot, CSegment csegParent, list<Segment__c> listSegmentSaved) {
    
        list<Segment__c> listSegment = new list<Segment__c>();
        
        // update each child's parent and root segment lookups
        for (CSegment cseg : csegParent.listChildCSegments) {
            cseg.Segment.Root_Segment__c = csegRoot.Segment.Id;
            cseg.Segment.Parent_Segment__c = csegParent.Segment.Id;
            listSegment.add(cseg.Segment);
        }
        // commit the changes
        upsert listSegment;
        listSegmentSaved.addAll(listSegment);
        
        // now recursively save each child's descendants
        for (CSegment cseg : csegParent.listChildCSegments) {
            saveCSegmentChildren(csegRoot, cseg, listSegmentSaved);
        }        
        
    }

}