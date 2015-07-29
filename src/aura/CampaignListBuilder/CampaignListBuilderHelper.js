({
	getItems: function(component) {
        var self = this;

        if (!self.group) {
            self.currentId = 0;
            self.group = {
                items: []
            };

            window.getNextId = function() {
                self.currentId += 1;
                return self.currentId;
            }
        }

        component.set('v.group', self.group);
        component.set('v.excludes', {
            id: window.getNextId(),
            items: [],
            type: 'group'
        });
    },
})