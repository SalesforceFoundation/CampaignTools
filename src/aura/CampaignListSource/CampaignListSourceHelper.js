({
    fireUpdateEvent: function(component, eventName) {
        var event = component.getEvent(eventName);
        event.setParams({segment: component.get('{!v.source}')});
        event.fire();
    },

    updateReportColumns: function(component, helper, sourceSegment) {
        if (!sourceSegment || 'REPORT_SOURCE_SEGMENT' !== sourceSegment.segmentType) return;
        var columnNameComponent = component.find("columnName");
        var action = component.get("c.getReportIdColumns");
        action.setParams({"reportId": sourceSegment.sourceId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var columns = response.getReturnValue();
                var options = [{
                    label: $A.get('$Label.c.CampaignToolsListEditorSelectIdColumn'),
                    value: ''
                }];
                values = Object.keys(columns);
                for (i = 0; i < values.length; i++) {
                    var columnLabel = columns[values[i]];
                    var columnId = values[i];
                    var isSelected = (sourceSegment.columnName === values[i]);
                    options.push({
                        label: columnLabel,
                        value: columnId,
                        selected: isSelected
                    });
                }
                component.find("columnName").set("v.options", options);
            }
            else if (state === "ERROR") {
                // @todo what do we do if we can't find any id columns or the
                // report doesn't exist, etc?
                component.find("columnName").set(
                    "v.options",
                    [{
                        label: $A.get('$Label.c.CampaignToolsListEditorEmptyIdColumn'),
                        value: ''
                    }]
                );
            }
        });
        $A.enqueueAction(action);
    },
})