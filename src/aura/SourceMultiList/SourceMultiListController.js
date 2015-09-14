({
    // handler for the Add Source button.
    // creates a new source, and if needed, a parent group.
	addSource: function(component, event, helper) {
		var group = component.get('v.group');
        
        // our current segment may be a group or a source.
        // so if we are not a group, we have to add one.
        if (group.Segment.Operation__c == 'SOURCE') {
            var segNew = {Operation__c:'AND'};
            var csegNew = {
                Segment: segNew, 
                listChildCSegments: [],
                rootCSegment: group.rootCSegment,
                parentCSegment: group.parentCSegment
            };
            helper.insertParentInTree(group, csegNew);
            group = csegNew;
        }
        
        var segNew = {Operation__c:'SOURCE'};
        var csegNew = {
            Segment: segNew,
            listChildCSegments: [],
            rootCSegment: group.rootCSegment,
            parentCSegment: group.parentCSegment
        };
        helper.insertChildInTree(group, csegNew);
		        
        component.set('v.group', group);
	},
    
    // handler for the Add Group button.
    // fires an addCSegmentEvent to allow its parent do the work.
    addGroup: function(component, event, helper) {        
        var group = component.get('v.group');
    	if (group == null)
    		return;
	    var event = $A.get("e.c:addCSegmentEvent");
		event.setParams({ "cseg" : group });
		event.fire();
		return;
	},
    
    // event handler to see if deleted cseg was one of our children (or ourself!)
    handleDeleteCSegmentEvent: function(component, event) {
		var cseg = event.getParam("cseg");
		var group = component.get('v.group');
        if (cseg != null && group != null) {
            // deleting ourself?
            if (cseg == group) {
                // turn a single segment into an empty group
                if (cseg.Segment.Operation__c == 'SOURCE') {
                    cseg.Segment.Operation__c = 'AND';
                    cseg.Segment.Source_ID__c = null;
                    cseg.Segment.Source_Type__c = null;
                    cseg.listChildCSegments = [];
                }
                
            }
            else if (group.listChildCSegments != null) {
                var i = group.listChildCSegments.indexOf(cseg);
                if (i >= 0) {
                    group.listChildCSegments.splice(i, 1);
                    // if deleted our last child, delete ourself
                    if (group.listChildCSegments.length == 0) {
                        var event = $A.get("e.c:deleteCSegmentEvent");
                        event.setParams({ "cseg" : group });
                        event.fire();                        
                    }
                }
            }
        	// to force rerender
            component.set('v.group', group);
        }
    },
    
})