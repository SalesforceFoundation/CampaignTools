({
    afterRender: function(component, helper) {
        this.superAfterRender();
        var sourceSegment = component.get("v.source");
        helper.updateReportColumns(component, helper, sourceSegment);
    }
})