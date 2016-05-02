({
    doInit: function (component, event, helper) {
        var rootSegmentId = component.get('v.rootSegmentId');
        helper.loadSegmentTreeData(
            component,
            rootSegmentId,
            function (err, segmentTreeData) {
                if (err) throw err[0];
                component.set('v.segmentData', segmentTreeData);
            }
        );
    },

    handleAddSegment: function (component, event, helper) {
        var segment = event.getParam('segment');
        helper.addSegment(segment);
        component.set('v.segmentData', component.get('v.segmentData'));
    },

    handleAddGroup: function (component, event, helper) {
        var group = event.getParam('segment');
        helper.addGroup(group);
        component.set('v.segmentData', component.get('v.segmentData'));
    },

    handleDeleteSegment: function (component, event, helper) {
        var segment = event.getParam('segment');
        helper.deleteSegment(segment);
        component.set('v.segmentData', component.get('v.segmentData'));
    },

    handleSave: function (component, event, helper) {
        var segmentData = component.get('v.segmentData');
        var campaignId = component.get('v.campaignId');
        helper.saveSegmentData(
            component,
            campaignId,
            segmentData,
            function (err) {
                if (err) {
                    helper.addPageMessage(
                        'error',
                        $A.get('$Label.c.CampaignToolsListEditorSaveError'),
                        err[0].message
                    );
                } else {
                    helper.addPageMessage(
                        'confirm',
                        $A.get('$Label.c.CampaignToolsListEditorSaveSuccessful')
                    );
                }
            }
        );
    }
})