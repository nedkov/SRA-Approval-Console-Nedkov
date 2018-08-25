/**
* @author IBM
* @date 4 June, 2018
*
* @group CH
*
* @description Test class for CH_CTRL_ApprovalItems
*/
@isTest
public class CH_CTRL_ApprovalItems_Test {
    
    private static final String ARTICLE_TITLE = 'testArticle';
    private static final String ARTICLE_STATUS = 'Pending Editor Updates';
    private static final String RELATED_HELPDESK = 'Finance';
    private static final String HELPDESK_CATEGORY ='Intercompany';
    private static final String KNOWLEDGE_RECORD_TYPE_NAME = 'Standard Template';
    private static final String APPROVAL_PROCESS_DEFINITION_NAME = 'CH_Knowledge_Content_Publishing_Finance';
    private static final String TESTUSER_USERNAME = 'testEmailTestUser1@testApprovalItems.com';
    private static final String TEST_PROFILE_NAME = 'IH Content Owner';
    private static final String ASSERT_APPROVAL_ITEM = 'Unable to get Approval records';
    private static final String ASSERT_APPROVAL ='The record should be in Approved Status';
    private static final String ASSERT_REJECTION ='The record should be in Rejected Status';
    private static final String APPROVAL_COMMENT ='APPROVING';
    private static final String REJECTION_COMMENT ='REJECTING';
    private static final String APPROVAL_ACTION ='Approve';
    private static final String REJECTION_ACTION ='Reject';
    /**
    * @description method to setup Data
    * @params Nothing
    * @return Nothing
    */ 
    @testSetup
    public static void prepareData(){
        
        
        Profile profile = [SELECT Id FROM Profile WHERE name =: TEST_PROFILE_NAME LIMIT 1];
        User testUser = (User)new SObjectBuilder(User.SObjectType)
            .put(User.Username, TESTUSER_USERNAME)
            .put(User.ProfileId, profile)
            .put(User.IH_Employee_Type__c,99)
            .put(User.IH_Country__c,'US') 
            .create()
            .getRecord();
        
        Id rid = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get(KNOWLEDGE_RECORD_TYPE_NAME).getRecordTypeId();
        
        Knowledge__kav testArticle = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .put(Knowledge__kav.RecordTypeId,rid)
            .put(Knowledge__kav.Title,ARTICLE_TITLE)
            .put(Knowledge__kav.IH_Content_Owner__c,testUser.Id)
            .put(Knowledge__kav.IH_Article_Status__c,ARTICLE_STATUS)
            .put(Knowledge__kav.IH_Related_Help_Desk__c,RELATED_HELPDESK)
            .put(Knowledge__kav.CH_Help_Desk_Category__c,HELPDESK_CATEGORY)
            .create()
            .getRecord();
        testArticle = [SELECT Id, KnowledgeArticleId,Title FROM Knowledge__kav WHERE Id = :testArticle.Id];  
        KbManagement.PublishingService.publishArticle(testArticle.KnowledgeArticleId, true);
        prepareQueue();
    }
    
    /**
    * @description method 
    * @params Nothing
    * @return Nothing
    */        
    @future
    public static void prepareQueue(){
        
        Group testgroup = new Group(Type='Queue', Name='Queue name');
        insert testgroup;
        
        GroupMember member = new GroupMember();
        member.UserOrGroupId = UserInfo.getUserId();
        member.GroupId = testgroup.Id;
        insert member;
        
        User testUser = [SELECT Id FROM User WHERE username = :TESTUSER_USERNAME LIMIT 1];
        
        GroupMember member2 = new GroupMember();
        member2.UserOrGroupId = testUser.Id;
        member2.GroupId = testgroup.Id;
        insert member2;
    }
   /**
    * @description: Method to submit article for approval to test getApprovalItems Method
    * @params : Article Id
    * @return : Nothing
    */  
    private static void submitForApproval(Id articleId){        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setObjectId(articleId);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setProcessDefinitionNameOrId(APPROVAL_PROCESS_DEFINITION_NAME);
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1); 
    }
    
	/**
    * @description testMethod to test getApprovalItems Method
    * @params Nothing
    * @return Nothing
    */
    @isTest
    private static void getApprovalItemsTest(){
        Knowledge__kav testArticle = [SELECT KnowledgeArticleId FROM Knowledge__kav 
                                      WHERE IH_Article_Status__c =:ARTICLE_STATUS 
                                      LIMIT 1]; 
        String returnId = KbManagement.PublishingService.editOnlineArticle (testArticle.KnowledgeArticleId, true);	
        List<CH_CTRL_ApprovalItems.WrapData> pp = new List<CH_CTRL_ApprovalItems.WrapData>();
        submitForApproval(returnId);
        Test.startTest();
			pp =  CH_CTRL_ApprovalItems.getApprovalItems();
        Test.stopTest();
        System.assert(pp.size() > 0, ASSERT_APPROVAL_ITEM);
    }
    /**
    * @description testMethod to test approverecord Method
    * @params Nothing
    * @return Nothing
    */
    @isTest
    private static void approveRecordTest(){
        Knowledge__kav testArticle = [SELECT KnowledgeArticleId FROM Knowledge__kav 
                                      WHERE Title=: ARTICLE_TITLE 
                                      LIMIT 1]; 
        User testUser = [SELECT Id FROM User WHERE 
                         username = :TESTUSER_USERNAME 
                         LIMIT 1];
        String returnId = KbManagement.PublishingService.editOnlineArticle (testArticle.KnowledgeArticleId, true);
        submitForApproval(returnId);
        Test.startTest();
        CH_CTRL_ApprovalItems.approveRejectRecord(returnId, testUser.Id,APPROVAL_COMMENT,APPROVAL_ACTION);
        test.stopTest();
        ProcessInstance pi = [SELECT Id,
                              (SELECT Id, ActorId,Actor.Name,StepStatus, Comments FROM Steps 
                               WHERE StepStatus ='Approved' order by CreatedDate Desc LIMIT 1)  
                              FROM ProcessInstance WHERE TargetObjectId =:returnId];
        System.assertEquals(UserInfo.getUserId(), pi.Steps[0].ActorId, ASSERT_APPROVAL);
    }
    /**
    * @description testMethod to test getApprovalItems Method's scenario
    * @params Nothing
    * @return Nothing
    */
    @isTest
    private static void getApprovalItems2(){
        Knowledge__kav testArticle = [SELECT KnowledgeArticleId FROM Knowledge__kav 
                                      WHERE Title=: ARTICLE_TITLE 
                                      LIMIT 1]; 
        User testUser = [SELECT Id FROM User WHERE 
                         username = :TESTUSER_USERNAME 
                         LIMIT 1];
        String returnId = KbManagement.PublishingService.editOnlineArticle (testArticle.KnowledgeArticleId, true);
        submitForApproval(returnId);
        CH_CTRL_ApprovalItems.approveRejectRecord(returnId, testUser.Id,APPROVAL_COMMENT,APPROVAL_ACTION);
        Test.startTest();
        CH_CTRL_ApprovalItems.getApprovalItems();
        test.stopTest();
        ProcessInstance pi = [SELECT Id,
                              (SELECT Id, ActorId,Actor.Name,StepStatus, Comments FROM Steps 
                               WHERE StepStatus ='Approved' order by CreatedDate Desc LIMIT 1) 
                              FROM ProcessInstance WHERE TargetObjectId =:returnId];
        System.assertEquals(UserInfo.getUserId(), pi.Steps[0].ActorId, ASSERT_APPROVAL);
    }
    /**
    * @description testMethod to test rejectRecord Method
    * @params Nothing
    * @return Nothing
    */
    @isTest
    private static void rejectRecordTest(){
        Knowledge__kav testArticle = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Title=: ARTICLE_TITLE LIMIT 1]; 
        User testUser = [SELECT Id FROM User WHERE username = :TESTUSER_USERNAME LIMIT 1];
        String returnId = KbManagement.PublishingService.editOnlineArticle (testArticle.KnowledgeArticleId, true);
        submitForApproval(returnId);
        Test.startTest();
        CH_CTRL_ApprovalItems.approveRejectRecord(returnId, testUser.Id,REJECTION_COMMENT,REJECTION_ACTION);
        test.stopTest();
        ProcessInstance pi = [SELECT Id,(SELECT Id, ActorId,Actor.Name,StepStatus, Comments FROM Steps where StepStatus ='Rejected' order by CreatedDate Desc LIMIT 1) FROM ProcessInstance WHERE TargetObjectId =:returnId];
    }
}