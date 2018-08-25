({
	closeModal : function(component, event, helper) {
		component.set("v.showModal", false);
	},
    
    save : function(component, event, helper) {
        var recordId = component.get("v.itemId");
        var action = component.get("c.approveRejectRecord");
        
        action.setParams({
            "recordId" : recordId,
            "actorId" : component.get("v.actorId"),
            "comment" : component.get("v.comment"),
            "requestType" : component.get("v.commentType")
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                
                /*Filter for Knowledge articles since they have an approval process.
                 * Using "window.parent.location" forces a full refresh so that if the approval
                 * process contains a field update. The record page of the knowledge article is 
                 * refreshed to attempt at show most up to date*/
                var isKnowledge = recordId.includes("ka0");
                if(isKnowledge){
                    var internalOrgUrl = $A.get("$Label.c.CH_Lightning_Experience_Organization_URL"); 
                    console.log(internalOrgUrl + 'r/Knowledge__kav/' + recordId + '/view');
                    window.parent.location = internalOrgUrl + 'r/Knowledge__kav/' + recordId + '/view';
                }
                else{
                    component.set("v.showModal", false);
                    var navUser = $A.get("e.force:navigateToSObject");
                    navUser.setParams({
                        "recordId": recordId
                    })
                    navUser.fire();
                }
            }
        });
        $A.enqueueAction(action);
    }
})