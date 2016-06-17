({
    fireUpdateEvent: function(component, eventName) {
        var event = component.getEvent(eventName);
        event.setParams({segment: component.get('{!v.source}')});
        event.fire();
    },

    updateReportColumns: function(component, helper, sourceSegment) {
        if (!sourceSegment || sourceSegment.segmentType !== 'REPORT_SOURCE_SEGMENT') {
            return;
        }
        var columnNameComponent = component.find("columnName");
        var action = component.get("c.getReportIdColumns");
        action.setParams({"reportId": sourceSegment.sourceId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var columns = response.getReturnValue();
                var selectIdColumnLabel;
                if (component.get('v.nsPrefix') === 'camptools') {
                    selectIdColumnLabel = '$Label.camptools.CampaignToolsListEditorSelectIdColumn';
                } else {
                    selectIdColumnLabel = '$Label.c.CampaignToolsListEditorSelectIdColumn';
                }
                var options = [{
                    label: $A.get(selectIdColumnLabel),
                    value: ''
                }];
                var values = Object.keys(columns);
                for (var i = 0; i < values.length; i+=1) {
                    var columnLabel = columns[values[i]];
                    var columnId = values[i];
                    var isSelected = (sourceSegment.columnName === values[i]);
                    options.push({
                        label: columnLabel,
                        value: columnId,
                        selected: isSelected
                    });
                }
                if (columnNameComponent && columnNameComponent.isValid()) {
                    columnNameComponent.set("v.options", options);
                }
            } else if (state === "ERROR") {
                // @todo what do we do if we can't find any id columns or the
                // report doesn't exist, etc?
                if (columnNameComponent && columnNameComponent.isValid()) {
                    var emptyIdColumnLabel;
                    if (component.get('v.nsPrefix') === 'camptools') {
                        emptyIdColumnLabel = '$Label.camptools.CampaignToolsListEditorEmptyIdColumn';
                    } else {
                        emptyIdColumnLabel = '$Label.c.CampaignToolsListEditorEmptyIdColumn';
                    }
                    columnNameComponent.set(
                        "v.options",
                        [{
                            label: $A.get(emptyIdColumnLabel),
                            value: ''
                        }]
                    );
                }
            }
        });
        $A.enqueueAction(action);
    }
})