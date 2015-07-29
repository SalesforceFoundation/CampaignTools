({
	handleSourceType: function(component, event, helper) {
		var selectCmp = component.find("sourceType");
        var source = component.get('v.source');
        source.sourceType = selectCmp.get("v.value")
        component.set("v.source", source);
	}
})