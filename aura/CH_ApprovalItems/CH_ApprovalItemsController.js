({
    doInit : function(component, event, helper) {
        helper.getApprovalItems(component, event);
    },
    
    navToObj : function(component, event, helper){
        var objId = event.currentTarget.id;
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        sObjectEvent.setParams({
            "recordId": objId
        })
        sObjectEvent.fire();
    },
    
    navToUser : function(component, event, helper){
        var objId = event.currentTarget.id;
        var navUser = $A.get("e.force:navigateToSObject");
        navUser.setParams({
            "recordId": objId
        })
        navUser.fire();
    },
    
    approveItem : function(component, event, helper){
        var objId = event.currentTarget.id;
        var params = objId.split(' ');
        component.set("v.currentItemId",params[0]);
        component.set("v.currentActorId",params[1]);
        component.set("v.commentType","Approve");
        component.set("v.showModal",true);
        
      
    },
    
    rejectItem : function(component, event, helper){
        
        
         var objId = event.currentTarget.id;
        var params = objId.split(' ');
        
        component.set("v.currentItemId",params[0]);
        component.set("v.currentActorId",params[1]);
        component.set("v.commentType","Reject");
        component.set("v.showModal",true);
      
    },
    

    
})