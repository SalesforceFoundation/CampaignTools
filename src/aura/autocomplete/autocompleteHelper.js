({  
    initHandlers: function(component) {
        if (typeof jQuery !== "undefined" && typeof $j === "undefined") {
            $j = jQuery.noConflict(true);;
        }        
        
        if (typeof $j === "undefined")
            return;
        
        var ctx = component.getElement();
        
        $j(".autocomplete", ctx).autocomplete({
            minLength: 2,
            delay: 500,
            source: function(request, response) {
                var action = component.get("c.getSuggestions");
                var fieldsToGet = component.get("v.fields");
               
                action.setParams({
                    "sObjectType": component.get("v.sObjectType"),
                    "term": request.term,
                    "fieldsToGet": fieldsToGet.join(),
                    "limitSize": component.get("v.limit")
                });
                
                action.setCallback(this, function(a) {
                	var suggestions = a.getReturnValue();
                    suggestions.forEach(function(s) {
                        s["label"] = s.Name,
                        s["value"] = s.Id
                    });
                    response(suggestions);
                });
                
                $A.run(function() {
                    $A.enqueueAction(action); 
                });
            },
            select: function(event, ui) {  
                event.preventDefault();
                var ctx = component.getElement();
                $j(".autocomplete", ctx).val(ui.item.label);
                    
                var selectionEvent = component.getEvent("autocompleteEvent");
                selectionEvent.setParams({
                    "selectedOption": ui.item 
                });
                selectionEvent.fire();
            },
            focus: function(event, ui) {
            	event.preventDefault(); // to stop the textbox from being updated with the item's value.    
            },
        });
    }

})