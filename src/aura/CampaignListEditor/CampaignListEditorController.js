({
    doInit: function (component, event, helper) {
        var rootSegmentId = component.get('v.rootSegmentId');
        helper.verifyPermissions(
            component
        );
        helper.loadSegmentTreeData(
            component,
            rootSegmentId,
            function (err, segmentTreeData) {
                if (err) {
                    var initErrorLabel;
                    if (component.get('v.nsPrefix') === 'camptools') {
                        initErrorLabel = '$Label.camptools.PageMessagesError';
                    } else {
                        initErrorLabel = '$Label.c.PageMessagesError';
                    }
                    helper.addPageMessage(
                        'error',
                        $A.get(initErrorLabel),
                        err[0].message
                    );
                }
                component.set('v.segmentData', segmentTreeData);
                component.set('v.showSpinner', false);
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
        var segmentData = component.get('v.segmentData');
        // After deletion if entire segment branch is removed re-add with an empty group
        if (segmentData.segmentTree.children.length === 1) {
            // Deal with Locker Service issue by creating a new array when pushing new elements
            var children = [];
            children = segmentData.segmentTree.children;
            if ($A.util.isEmpty(segmentData.inclusionSegment.children)) {
                helper.addGroup(segmentData.inclusionSegment);
                children.push(segmentData.inclusionSegment);
            } else if ($A.util.isEmpty(segmentData.exclusionSegment.children)) {
                helper.addGroup(segmentData.exclusionSegment);
                children.push(segmentData.exclusionSegment);
            }
            segmentData.segmentTree.children = children;
        }
        component.set('v.segmentData', segmentData);
    },

    handleSave: function (component, event, helper) {
        var segmentData = component.get('v.segmentData');
        var campaignId = component.get('v.campaignId');

        if (!helper.validSegmentData(component, segmentData))
            return;

        helper.saveSegmentData(
            component,
            campaignId,
            segmentData,
            function (err) {
                if (err) {
                    var saveErrorLabel;
                    if (component.get('v.nsPrefix') === 'camptools') {
                        saveErrorLabel = '$Label.camptools.CampaignToolsListEditorSaveError';
                    } else {
                        saveErrorLabel = '$Label.c.CampaignToolsListEditorSaveError';
                    }
                    helper.addPageMessage(
                        'error',
                        $A.get(saveErrorLabel),
                        err[0].message
                    );
                } else {
                    if (typeof sforce === "undefined") {
                        window.location.replace('/' + component.get('v.campaignId'));
                    } else {
                        sforce.one.back(true);
                    }
                }
            }
        );
    }
})