public with sharing class SegmentMapper {

    public static CSegment mapRootSegment(Segment__c rootSegment) {
        return mapRootSegment(rootSegment, true);
    }
    
    public static CSegment mapRootSegment(Segment__c rootSegment, boolean fillBackLinks) {

        map<id, Segment__c> segMap = new map<id, Segment__c>(
            [SELECT Id, Operation__c, Parent_Segment__c, Root_Segment__c, Source_Type__c, Source_Id__c, Exclude_Source__c,
            (SELECT Id FROM Segments__r) 
            FROM Segment__c WHERE Root_Segment__c = :rootSegment.Id OR Id = :rootSegment.Id]
        );
        
        // get source names
        set<Id> setCmpId = new set<Id>();
        set<Id> setRptId = new set<Id>();
        for (Segment__c seg : segMap.values()) {
            if (seg.Source_Type__c == 'Campaign' && seg.Source_Id__c != null)
                setCmpId.add(seg.Source_Id__c);
            else if (seg.Source_Type__c == 'Report' && seg.Source_Id__c != null)
                setRptId.add(seg.Source_Id__c);
        }        
        map<Id, Campaign> mapIdCmp = new map<Id, Campaign> ([Select Id, Name from Campaign where Id in :setCmpId]);
        map<Id, Report> mapIdRpt = new map<Id, Report> ([Select Id, Name from Report where Id in :setRptId]);
        
        map<id, CSegment> mapCSegment = new map<id, CSegment>();

        //fill out CSegment map
        for (Segment__c seg : segMap.values()) {
            CSegment CSeg = new CSegment(seg);
            if (seg.Source_Type__c == 'Campaign' && seg.Source_Id__c != null)
                CSeg.sourceName = mapIdCmp.get(seg.Source_Id__c).Name;
            else if (seg.Source_Type__c == 'Report' && seg.Source_Id__c != null)
                CSeg.sourceName = mapIdRpt.get(seg.Source_Id__c).Name;
            mapCSegment.put(seg.Id, CSeg);
        }
        
        //fill out parent, root, and child lists with CSegments
        for (CSegment CSeg : mapCSegment.values()) {

            if (CSeg.Segment.Parent_Segment__c!=null && fillBackLinks)
                CSeg.parentCSegment = mapCSegment.get(CSeg.Segment.Parent_Segment__c);

            if (CSeg.Segment.Root_Segment__c!=null && fillBackLinks)
                CSeg.rootCSegment = mapCSegment.get(CSeg.Segment.Root_Segment__c);

            if (CSeg.Segment.getSObjects('Segments__r')!=null) {
                for (Segment__c childseg : CSeg.Segment.getSObjects('Segments__r')) {
                    CSeg.listChildCSegments.add(mapCSegment.get(childseg.id));
                }
            }
        }
        
        return mapCSegment.get(rootSegment.Id);
    }
}