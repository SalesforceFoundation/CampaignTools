public with sharing class CSegment {
    public Segment__c Segment { get; set; }
    public list<CSegment> listChildCSegments { get; set; }
    public CSegment parentCSegment { get; set; }
    public CSegment rootCSegment { get; set; }

    public CSegment(Segment__c seg) {
        Segment = seg;
        listChildCSegments = new list<CSegment>();
    }
}