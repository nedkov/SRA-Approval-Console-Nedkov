({
	getApprovalItems : function(component, event) {
		var action = component.get("c.getApprovalItems");
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                component.set("v.approvalItems",response.getReturnValue());
            }
            
        });
        
        $A.enqueueAction(action);
	},
})