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
        for (i in segment.children) {
            this.setParentReferences(segment.children[i], segment);
        }
    },

    fillEmptyGroups: function (segment) {
        // Groups without child segments look weird in the UI.  This method
        // will find those empty groups and add a placeholder segment to them
        // to make it more clear for the user that a group exists there.
        if (segment.segmentType == 'AND_SEGMENT' || segment.segmentType == 'OR_SEGMENT') {
            if (segment.children.length == 0) {
                this.addSegment(segment);
            } else {
                for (i in segment.children) {
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
        var this_ = this;
        this.apexControllerMethod(
            component,
            'c.getSerializedSegmentTree',
            {
                rootSegmentId: rootSegmentId
            },
            function (err, serializedSegmentTree) {
                if (err) return callback(err);
                try {
                    var segmentTree = JSON.parse(serializedSegmentTree);
                } catch (e) {
                    return callback([e]);
                }
                return callback(null, segmentTree);
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
            if (err) return callback(err);
            this_.fillEmptyGroups(segmentTree);
            this_.setParentReferences(segmentTree, null);
            callback(null, this_.getSubtreesForUI(segmentTree));
        }

        if (rootSegmentId) {
            this.querySegmentTree(component, rootSegmentId, next);
        } else {
            next(null, this.getEmptySegmentTree());
        }
    },

    saveSegmentData: function (component, campaignId, segmentData, callback) {
        var serializableProperties = [
            'segmentType', 'rootSegmentId', 'parentId', 'sourceId',
            'isExclusion', 'columnName', 'sourceName', 'children'
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
            function (err, result) {
                if (err) return callback(err);
                callback(null);
            }
        );
    },

    addSegment: function (group) {
        group.children.push({
            isExclusion: false,
            parent: group
        });
    },

    addGroup: function (group) {
        var newGroup = {
            segmentType: 'AND_SEGMENT',
            isExclusion: false,
            parent: group,
            children: [
                {
                    isExclusion: false
                }
            ]
        };

        newGroup.children[0].parent = newGroup;

        group.children.push(newGroup);
    },

    deleteSegment: function (segment) {
        if (segment.parent) {
            var siblings = segment.parent.children;
            siblings.splice(siblings.indexOf(segment), 1);
            if (siblings.length == 0) {
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
                    return callback([new Error(
                        $A.get('$Label.c.CampaignToolsEditorMethodException')
                    )]);
                }

                var state = response.getState();

                if ('ERROR' == state) {
                    return callback(response.getError());
                }

                return callback(null, response.getReturnValue());
            }
        );
        $A.enqueueAction(action);
    }
})