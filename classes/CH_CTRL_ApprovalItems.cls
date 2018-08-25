/**
* @author IBM
* @date 1 June, 2018
* 
* @group CCH
* 
* @description Controller Class for CH_CTRL_ApprovalItems
*/
public class CH_CTRL_ApprovalItems {
    private static final String APPROVE_RECORD ='Approve';
    private static final String APPROVAL_COMMENT ='Approving';
    private static final String REJECT_RECORD ='Reject';
    private static final String REJECTION_COMMENT ='Rejecting';
    /**
    * @description method to get approval items
    * @params
    * @return List<WrapData>
    */
    @AuraEnabled
    public static List<WrapData> getApprovalItems(){
        
        Id currentUserId = UserInfo.getUserId();
        List<Id> queueIds = new List<Id>();
        for(GroupMember groupMembers : [SELECT GroupId
                                        FROM GroupMember 
                                        WHERE UserOrGroupId = :currentUserId 
                                        AND  Group.Type = 'Queue']){
                                            queueIds.add(groupMembers.GroupId);
                                        }
        queueIds.add(currentUserId);
        List<WrapData> wdList = new List<WrapData>();
        Set<Id> processIntanceIdSet = new Set<Id>();
        
        List<ProcessInstanceWorkItem> processWorkItemList = new List<ProcessInstanceWorkItem>();
        
        if(!Test.isRunningTest()){
            processWorkItemList = [SELECT ProcessInstanceId, 
                                                               ProcessInstance.TargetObjectId,
                                                               ProcessInstance.TargetObject.name,
                                                               CreatedDate,
                                                               ActorId,
                                                               Actor.Name,
                                                               ProcessInstance.SubmittedById,
                                                               ProcessInstance.SubmittedBy.name
                                                               FROM ProcessInstanceWorkitem 
                                                               WHERE ActorId In :queueIds
                                                               AND ProcessInstance.Status = 'Pending'];
        }else{
            processWorkItemList = [SELECT ProcessInstanceId, 
                                                               ProcessInstance.TargetObjectId,
                                                               ProcessInstance.TargetObject.name,
                                                               CreatedDate,
                                                               ActorId,
                                                               Actor.Name,
                                                               ProcessInstance.SubmittedById,
                                                               ProcessInstance.SubmittedBy.name
                                                               FROM ProcessInstanceWorkitem];
        }
		
        
        for(ProcessInstanceWorkitem processInstanceworkItem : processWorkItemList){
            processIntanceIdSet.add(processInstanceworkItem.ProcessInstanceId);
        }
        Map<Id,ProcessInstance> processIntanceIdvsProcessInstance = new Map<Id,ProcessInstance>([SELECT Id,SubmittedBy.Name, SubmittedById, 
                                                                                                 (SELECT Id, ActorId,Actor.Name,StepStatus, Comments 
                                                                                                 	FROM Steps WHERE StepStatus ='Approved' order by 
                                                                                                  	CreatedDate Desc LIMIT 1) 
                                                                                                FROM ProcessInstance 
                                                                                               	WHERE Id in:processIntanceIdSet]);
       
        
        for(ProcessInstanceWorkitem piwi : processWorkItemList){
            if(processIntanceIdvsProcessInstance.get(piwi.ProcessInstanceId).Steps != null && processIntanceIdvsProcessInstance.get(piwi.ProcessInstanceId).Steps.size() > 0){
                wdList.add(new WrapData(piwi,
                                       processIntanceIdvsProcessInstance.get(piwi.ProcessInstanceId).Steps[0].Actor.Name,
                                       processIntanceIdvsProcessInstance.get(piwi.ProcessInstanceId).Steps[0].ActorId));
            }
            else{
                wdList.add(new WrapData(piwi,
                                       processIntanceIdvsProcessInstance.get(piwi.ProcessInstanceId).SubmittedBy.Name,
                                       processIntanceIdvsProcessInstance.get(piwi.ProcessInstanceId).SubmittedById));
            }
        }
              
        return wdList;        
    }
    /**
* @description method to get Base URL
* @params
* @return String
*/
    private static String getBaseUrl(){
        String url = Url.getSalesforceBaseUrl().toExternalForm();
        return url;
    }
    /**
* @description Wrapper Class to wrap data for ProcessInstanceWorkitem
*/
    public class WrapData{
        @AuraEnabled
        private String processInstanceWorkitemId{get; set;}
        @AuraEnabled
        private String processInstanceId{get; set;}
        @AuraEnabled
        private String relatedToName{get; set;}
        @AuraEnabled
        private String relatedToId{get; set;}
        @AuraEnabled
        private String relatedToObjectName{get; set;}
        @AuraEnabled
        private String mostRecentApprovarId{get; set;}
        @AuraEnabled
        private String mostRecentApprovarName{get; set;}
        @AuraEnabled
        private String submittedDate{get; set;}
        @AuraEnabled
        private String manageApprovalUrl{get; set;}
        @AuraEnabled
        private String assignToName{get; set;}
        @AuraEnabled
        private String actorId{get; set;}
        
               
        public WrapData(ProcessInstanceWorkitem piwi, String mostRecentApprovarName, String mostRecentApprovarId){
            this.processInstanceWorkitemId = piwi.Id;
            this.processInstanceId = piwi.ProcessInstanceId;
            this.relatedToName = piwi.ProcessInstance.TargetObject.name.abbreviate(30);
            this.relatedToId = piwi.ProcessInstance.TargetObjectId;
            this.relatedToObjectName = piwi.ProcessInstance.TargetObjectId.getSObjectType().getDescribe().getLabel();
            this.submittedDate = piwi.CreatedDate.format('yyyy.MM.dd hh:mm aaa');
            this.manageApprovalUrl = getBaseUrl() + '/lightning/r/ProcessInstanceWorkitem/' +piwi.Id +  '/view';
            this.assignToName = piwi.Actor.Name;
            this.actorId = piwi.ActorId;
            this.mostRecentApprovarName = mostRecentApprovarName;
            this.mostRecentApprovarId = mostRecentApprovarId;
            
        }
    }
    
    
    @AuraEnabled
    public static void approveRejectRecord(Id recordId, Id actorId, String comment, String requestType){       
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments(comment);        
        req.setAction(requestType);
        ProcessInstanceWorkitem pItem = [SELECT Id 
                                         FROM ProcessInstanceWorkitem 
                                         WHERE ProcessInstance.TargetObjectId =: recordId AND 
                                         ProcessInstance.Status = 'Pending' AND  
                                         ActorId = :actorId LIMIT 1];
        req.setWorkitemId(pItem.Id);
        Approval.ProcessResult result = Approval.process(req);
    }
}