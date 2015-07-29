({
	addSource: function(component, event, helper) {
		var group = component.get('v.group');
        
        group.items.push({
            id: window.getNextId(),
            parent: group.id,
            type: 'filter'
        });
        
        component.set('v.group', group);
	}
})