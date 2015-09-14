({
    
	afterRender : function(component, helper) {
	    this.superAfterRender();
        helper.initHandlers(component);
	}
})