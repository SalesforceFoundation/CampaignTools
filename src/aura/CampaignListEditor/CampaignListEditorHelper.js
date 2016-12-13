({
    getEmptySegmentTree: function() {
        /**
         * Generate a new segmentTree with basic required structure.  The AND
         * and NOT OR children of the root are the two sub-trees that are
         * exposed via the UI.  Here, we supply two "unspecified" SOURCE
         * segments for each terminal group.
         *
         * AND
         *  |
         *  +-OR
         *  |  |
         *  |  +-AND
         *  |
         *  +-NOT OR
         *     |
         *     +-AND
         */
        var segmentTree = {
            segmentType: 'AND_SEGMENT',
            isExclusion: false,
            children: [
                {
                    segmentType: 'OR_SEGMENT',
                    isExclusion: false,
                    children: [
                        {
                            segmentType: 'AND_SEGMENT',
                            isExclusion: false,
                            children: []
                        }
                    ]
                },
                {
                    segmentType: 'OR_SEGMENT',
                    isExclusion: true,
                    children: [
                        {
                            segmentType: 'AND_SEGMENT',
                            isExclusion: false,
                            children: []
                        }
                    ]
                }
            ]
        };

        this.setParentReferences(segmentTree, null);
        return segmentTree;
    },

    setParentReferences: function (segment, parent_) {
        segment.parent = parent_;
        if (segment.children) {
            for (var i = 0; i < segment.children.length; i += 1) {
                this.setParentReferences(segment.children[i], segment);
            }
        }
    },

    fillEmptyGroups: function (segment) {
        // Groups without child segments look weird in the UI.  This method
        // will find those empty groups and add a placeholder segment to them
        // to make it more clear for the user that a group exists there.
        if (segment.segmentType === 'AND_SEGMENT' || segment.segmentType === 'OR_SEGMENT') {
            if (segment.children.length === 0) {
                this.addSegment(segment);
            } else {
                for (var i = 0; i < segment.children.length; i += 1) {
                    this.fillEmptyGroups(segment.children[i]);
                }
            }
        }
    },

    getSubtreesForUI: function (segmentTree) {
         // Given a root segmentTree, pluck out the two children segments for
         // display in the UI.  One of these will the 'inclusion' segment, and
         // one will be the 'exclusion' segment.
        var inclusionSegment, exclusionSegment;

        var firstSubtree = segmentTree.children[0];
        var secondSubtree = segmentTree.children[1];

        if (firstSubtree.isExclusion) {
            exclusionSegment = firstSubtree;
            inclusionSegment = secondSubtree;
        } else {
            inclusionSegment = firstSubtree;
            exclusionSegment = secondSubtree;
        }
        return {
            segmentTree: segmentTree,
            inclusionSegment: inclusionSegment,
            exclusionSegment: exclusionSegment
        };
    },

    querySegmentTree: function (component, rootSegmentId, callback) {
        // Get the segmentTree corresponding to rootSegmentId by calling the
        // getSerializedSegmentTree Apex controller method
        this.apexControllerMethod(
            component,
            'c.getSerializedSegmentTree',
            {
                rootSegmentId: rootSegmentId
            },
            function (err, serializedSegmentTree) {
                if (err) {
                    return callback(err);
                }

                var segmentTree;

                try {
                    segmentTree = JSON.parse(serializedSegmentTree);
                } catch (e) {
                    return callback([e]);
                }

                return callback(null, segmentTree);
            }
        );
    },

    verifyPermissions: function (component) {
        var this_ = this;
        this.apexControllerMethod(
            component,
            'c.checkPerms',
            {},
            function (err) {
                if (err) {
                    var initErrorLabel;
                    if (component.get('v.nsPrefix') === 'camptools') {
                        initErrorLabel = '$Label.camptools.PageMessagesError';
                    } else {
                        initErrorLabel = '$Label.c.PageMessagesError';
                    }
                    this_.addPageMessage(
                        'error',
                        $A.get(initErrorLabel),
                        err[0].message
                    );
                }
            }
        );
    },

    loadSegmentTreeData: function (component, rootSegmentId, callback) {
        // If a rootSegmentId is provided, then query for the segmentTree
        // corresponding to that rootSegmentId.  Otherwise, generate an empty
        // segmentTree.
        // Once a segmentTree is loaded, pluck out the two relevant subtrees
        // for the UI.
        var this_ = this;
        var next = function (err, segmentTree) {
            if (err) {
                return callback(err);
            }
            this_.fillEmptyGroups(segmentTree);
            this_.setParentReferences(segmentTree, null);
            return callback(null, this_.getSubtreesForUI(segmentTree));
        };

        if (rootSegmentId) {
            this.querySegmentTree(component, rootSegmentId, next);
        } else {
            next(null, this.getEmptySegmentTree());
        }
    },

    saveSegmentData: function (component, campaignId, segmentData, callback) {
        var serializableProperties = [
            'segmentId', 'segmentType', 'rootSegmentId', 'parentId', 'sourceId',
            'isExclusion', 'columnName', 'sourceName', 'children', 'statusIds'
        ];

        var serializedSegmentTree = JSON.stringify(
            segmentData.segmentTree,
            serializableProperties
        );
        this.apexControllerMethod(
            component,
            'c.saveCSegmentTree',
            {
                campaignId: campaignId,
                csegRoot: serializedSegmentTree
            },
            function (err) {
                if (err) {
                    return callback(err);
                }
                return callback(null);
            }
        );
    },

    addSegment: function (group) {
        var segmentType;
        var children = [];
        children = group.children;
        children.push({
            segmentType: segmentType,
            isExclusion: false,
            parent: group
        });
        group.children = children;
    },

    addGroup: function (group) {
        var segmentType;
        var children = [];
        children = group.children;
        var newGroup = {
            segmentType: 'AND_SEGMENT',
            isExclusion: false,
            parent: group,
            children: [
                {
                    segmentType: segmentType,
                    isExclusion: false
                }
            ]
        };

        newGroup.children[0].parent = newGroup;

        children.push(newGroup);
        group.children = children;
    },

    deleteSegment: function (segment) {
        if (segment.parent) {
            var siblings = [];
            siblings = segment.parent.children;
            siblings.splice(siblings.indexOf(segment), 1);
            segment.parent.children = siblings;
            if (siblings.length === 0) {
                this.deleteSegment(segment.parent);
            }
        }
    },

    addPageMessage: function (severity, summary, detail) {
        var addPageMessageEvent = $A.get('e.c:AddPageMessageEvent');
        addPageMessageEvent.setParams(
            {
                severity: severity,
                summary: summary,
                detail: detail
            }
        );
        addPageMessageEvent.fire();
    },

    apexControllerMethod: function (component, name, params, callback) {
        var action = component.get(name);
        action.setParams(params);
        action.setCallback(
            this,
            function (response) {
                if (!component.isValid()) {
                    var methodExceptionLabel;
                    if (component.get('v.nsPrefix') === 'camptools') {
                        methodExceptionLabel = '$Label.camptools.CampaignToolsEditorMethodException';
                    } else {
                        methodExceptionLabel = '$Label.c.CampaignToolsEditorMethodException';
                    }
                    return callback([new Error(
                        $A.get(methodExceptionLabel)
                    )]);
                }

                var state = response.getState();

                if (state === 'ERROR') {
                    return callback(response.getError());
                }

                return callback(null, response.getReturnValue());
            }
        );
        $A.enqueueAction(action);
    }
})