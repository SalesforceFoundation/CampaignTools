public with sharing class CSegment {

    @AuraEnabled
	public Segment__c Segment { get; set; }

    @AuraEnabled
	public list<CSegment> listChildCSegments { get; set; }

    // not aura enabled to prevent circular reference when converting to JSON
    public CSegment parentCSegment { get; set; }

    // not aura enabled to prevent circular reference when converting to JSON
    public CSegment rootCSegment { get; set; }

    public CSegment(Segment__c seg) {
    	Segment = seg;
    	listChildCSegments = new list<CSegment>();
    }
    
    @AuraEnabled
    public String sourceName { get; set; }
    
}