({
	doInit: function(component, event, helper) {
        helper.loadCampaignInfo(component);
	},
    
    saveAndClose: function(component, event, helper) {
        helper.saveCSegmentTree(component, true);
    },
    
    close: function(component, event, helper) {
        helper.close(component);
    },
    
    // event handler to add a group csegment
    handleAddCSegmentEvent: function(component, event, helper) {
        helper.addGroup(component, event);
    },    
})