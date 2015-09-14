({
	insertParentInTree : function(cseg, csegNewParent) {
		// replace cseg from its parent's children with csegNewParent
		var csegOldParent = cseg.parentCSegment;
        var i = csegOldParent.listChildCSegments.indexOf(cseg);
        csegOldParent.listChildCSegments[i] = csegNewParent;

        // make sure the new parent has its correct parent
        csegNewParent.parentCSegment = csegOldParent;
        
		// add cseg to new parent's children
        csegNewParent.listChildCSegments.push(cseg);

        // set new Parent for cseg
        cseg.parentCSegment = csegNewParent;
	},
    
    insertChildInTree : function (cseg, csegNewChild) {
        csegNewChild.parentCSegment = cseg;
        cseg.listChildCSegments.push(csegNewChild);
    }
})