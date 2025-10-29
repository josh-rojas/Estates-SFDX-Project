/**
 * Test class for SuccessionChatterPoster
 *
 * Tests all transition types and error handling for succession workflow Chatter posts.
 *
 * @author Claude Code
 * @date 2025-10-28
 */
@isTest
private class SuccessionChatterPoster_Test {
  /**
   * Setup test data for all test methods
   */
  @TestSetup
  static void setupTestData() {
    // Get EstateAdministration record type
    Id estateRtId = SuccessionUtilities.getEstateAdministrationRecordTypeId();

    // Create test case
    Case testCase = new Case(
      Subject = 'Test Succession Case',
      RecordTypeId = estateRtId,
      Type = 'Named Successor Enactment',
      Status = 'New',
      Origin = 'Phone'
    );
    insert testCase;
  }

  /**
   * Test CONTACT_ESTABLISHED transition
   */
  @isTest
  static void testContactEstablishedTransition() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    // Create request
    SuccessionChatterPoster.TransitionRequest req = new SuccessionChatterPoster.TransitionRequest();
    req.caseId = testCase.Id;
    req.transitionType = 'CONTACT_ESTABLISHED';

    Test.startTest();
    List<SuccessionChatterPoster.TransitionResponse> responses = SuccessionChatterPoster.postTransitions(
      new List<SuccessionChatterPoster.TransitionRequest>{ req }
    );
    Test.stopTest();

    // Verify response
    Assert.areEqual(1, responses.size(), 'Should return 1 response');
    Assert.isTrue(
      responses[0].postCreated,
      'Post should be created successfully'
    );
    Assert.isNotNull(
      responses[0].feedItemId,
      'Feed item ID should be populated'
    );
    Assert.isTrue(
      responses[0].message.contains('CONTACT_ESTABLISHED'),
      'Message should reference transition type'
    );

    // Verify FeedItem created
    List<FeedItem> posts = [
      SELECT Id, Body, ParentId
      FROM FeedItem
      WHERE ParentId = :testCase.Id
    ];
    Assert.areEqual(1, posts.size(), 'Should create 1 Chatter post');
    Assert.isTrue(
      posts[0].Body.contains('📞'),
      'Should contain contact emoji'
    );
    Assert.isTrue(
      posts[0].Body.contains('Contact established'),
      'Should contain transition description'
    );
  }

  /**
   * Test FORM_COMPLETED transition with pathway name
   */
  @isTest
  static void testFormCompletedTransition() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    // Create request
    SuccessionChatterPoster.TransitionRequest req = new SuccessionChatterPoster.TransitionRequest();
    req.caseId = testCase.Id;
    req.transitionType = 'FORM_COMPLETED';
    req.pathwayName = 'Final Grant';

    Test.startTest();
    List<SuccessionChatterPoster.TransitionResponse> responses = SuccessionChatterPoster.postTransitions(
      new List<SuccessionChatterPoster.TransitionRequest>{ req }
    );
    Test.stopTest();

    // Verify response
    Assert.isTrue(
      responses[0].postCreated,
      'Post should be created successfully'
    );

    // Verify FeedItem contains pathway
    List<FeedItem> posts = [
      SELECT Id, Body
      FROM FeedItem
      WHERE ParentId = :testCase.Id
    ];
    Assert.isTrue(
      posts[0].Body.contains('Final Grant'),
      'Should contain pathway name'
    );
    Assert.isTrue(
      posts[0].Body.contains('📋'),
      'Should contain form emoji'
    );
  }

  /**
   * Test PATHWAY_CONFIRMED transition
   */
  @isTest
  static void testPathwayConfirmedTransition() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    SuccessionChatterPoster.TransitionRequest req = new SuccessionChatterPoster.TransitionRequest();
    req.caseId = testCase.Id;
    req.transitionType = 'PATHWAY_CONFIRMED';
    req.pathwayName = 'New DAF Account';

    Test.startTest();
    List<SuccessionChatterPoster.TransitionResponse> responses = SuccessionChatterPoster.postTransitions(
      new List<SuccessionChatterPoster.TransitionRequest>{ req }
    );
    Test.stopTest();

    Assert.isTrue(
      responses[0].postCreated,
      'Post should be created successfully'
    );

    List<FeedItem> posts = [
      SELECT Id, Body
      FROM FeedItem
      WHERE ParentId = :testCase.Id
    ];
    Assert.isTrue(
      posts[0].Body.contains('🎯'),
      'Should contain target emoji'
    );
    Assert.isTrue(
      posts[0].Body.contains('New DAF Account'),
      'Should contain pathway name'
    );
  }

  /**
   * Test VERIFICATION_COMPLETE transition
   */
  @isTest
  static void testVerificationCompleteTransition() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    SuccessionChatterPoster.TransitionRequest req = new SuccessionChatterPoster.TransitionRequest();
    req.caseId = testCase.Id;
    req.transitionType = 'VERIFICATION_COMPLETE';

    Test.startTest();
    List<SuccessionChatterPoster.TransitionResponse> responses = SuccessionChatterPoster.postTransitions(
      new List<SuccessionChatterPoster.TransitionRequest>{ req }
    );
    Test.stopTest();

    Assert.isTrue(
      responses[0].postCreated,
      'Post should be created successfully'
    );

    List<FeedItem> posts = [
      SELECT Id, Body
      FROM FeedItem
      WHERE ParentId = :testCase.Id
    ];
    Assert.isTrue(
      posts[0].Body.contains('Verification phase completed'),
      'Should contain verification message'
    );
  }

  /**
   * Test EXECUTION_COMPLETE transition
   */
  @isTest
  static void testExecutionCompleteTransition() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    SuccessionChatterPoster.TransitionRequest req = new SuccessionChatterPoster.TransitionRequest();
    req.caseId = testCase.Id;
    req.transitionType = 'EXECUTION_COMPLETE';

    Test.startTest();
    List<SuccessionChatterPoster.TransitionResponse> responses = SuccessionChatterPoster.postTransitions(
      new List<SuccessionChatterPoster.TransitionRequest>{ req }
    );
    Test.stopTest();

    Assert.isTrue(
      responses[0].postCreated,
      'Post should be created successfully'
    );

    List<FeedItem> posts = [
      SELECT Id, Body
      FROM FeedItem
      WHERE ParentId = :testCase.Id
    ];
    Assert.isTrue(
      posts[0].Body.contains('🏁'),
      'Should contain finish flag emoji'
    );
    Assert.isTrue(
      posts[0].Body.contains('execution completed'),
      'Should contain completion message'
    );
  }

  /**
   * Test transition with additional context
   */
  @isTest
  static void testTransitionWithAdditionalContext() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    SuccessionChatterPoster.TransitionRequest req = new SuccessionChatterPoster.TransitionRequest();
    req.caseId = testCase.Id;
    req.transitionType = 'CONTACT_ESTABLISHED';
    req.additionalContext = 'Spoke with successor via phone. Email confirmed.';

    Test.startTest();
    List<SuccessionChatterPoster.TransitionResponse> responses = SuccessionChatterPoster.postTransitions(
      new List<SuccessionChatterPoster.TransitionRequest>{ req }
    );
    Test.stopTest();

    List<FeedItem> posts = [
      SELECT Id, Body
      FROM FeedItem
      WHERE ParentId = :testCase.Id
    ];
    Assert.isTrue(
      posts[0].Body.contains('Additional Notes'),
      'Should contain additional notes header'
    );
    Assert.isTrue(
      posts[0].Body.contains('Spoke with successor'),
      'Should contain additional context'
    );
  }

  /**
   * Test invalid transition type
   */
  @isTest
  static void testInvalidTransitionType() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    SuccessionChatterPoster.TransitionRequest req = new SuccessionChatterPoster.TransitionRequest();
    req.caseId = testCase.Id;
    req.transitionType = 'INVALID_TYPE';

    Test.startTest();
    List<SuccessionChatterPoster.TransitionResponse> responses = SuccessionChatterPoster.postTransitions(
      new List<SuccessionChatterPoster.TransitionRequest>{ req }
    );
    Test.stopTest();

    // Verify error response
    Assert.areEqual(1, responses.size(), 'Should return 1 response');
    Assert.isFalse(
      responses[0].postCreated,
      'Post should not be created for invalid type'
    );
    Assert.isTrue(
      responses[0].message.contains('Invalid transition type'),
      'Should return error message'
    );

    // Verify no FeedItem created
    List<FeedItem> posts = [
      SELECT Id
      FROM FeedItem
      WHERE ParentId = :testCase.Id
    ];
    Assert.areEqual(0, posts.size(), 'Should not create Chatter post');
  }

  /**
   * Test bulk processing of multiple transitions
   */
  @isTest
  static void testBulkTransitions() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    // Create multiple requests
    List<SuccessionChatterPoster.TransitionRequest> requests = new List<SuccessionChatterPoster.TransitionRequest>();

    SuccessionChatterPoster.TransitionRequest req1 = new SuccessionChatterPoster.TransitionRequest();
    req1.caseId = testCase.Id;
    req1.transitionType = 'VERIFICATION_COMPLETE';
    requests.add(req1);

    SuccessionChatterPoster.TransitionRequest req2 = new SuccessionChatterPoster.TransitionRequest();
    req2.caseId = testCase.Id;
    req2.transitionType = 'CONTACT_ESTABLISHED';
    requests.add(req2);

    SuccessionChatterPoster.TransitionRequest req3 = new SuccessionChatterPoster.TransitionRequest();
    req3.caseId = testCase.Id;
    req3.transitionType = 'FORM_COMPLETED';
    req3.pathwayName = 'Disclaim Assets';
    requests.add(req3);

    Test.startTest();
    List<SuccessionChatterPoster.TransitionResponse> responses = SuccessionChatterPoster.postTransitions(
      requests
    );
    Test.stopTest();

    // Verify all responses
    Assert.areEqual(3, responses.size(), 'Should return 3 responses');
    for (SuccessionChatterPoster.TransitionResponse resp : responses) {
      Assert.isTrue(resp.postCreated, 'All posts should be created');
      Assert.isNotNull(resp.feedItemId, 'All should have feed item IDs');
    }

    // Verify 3 FeedItems created
    List<FeedItem> posts = [
      SELECT Id
      FROM FeedItem
      WHERE ParentId = :testCase.Id
    ];
    Assert.areEqual(3, posts.size(), 'Should create 3 Chatter posts');
  }

  /**
   * Test case-insensitive transition type matching
   */
  @isTest
  static void testCaseInsensitiveTransitionType() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    SuccessionChatterPoster.TransitionRequest req = new SuccessionChatterPoster.TransitionRequest();
    req.caseId = testCase.Id;
    req.transitionType = 'contact_established'; // lowercase

    Test.startTest();
    List<SuccessionChatterPoster.TransitionResponse> responses = SuccessionChatterPoster.postTransitions(
      new List<SuccessionChatterPoster.TransitionRequest>{ req }
    );
    Test.stopTest();

    Assert.isTrue(
      responses[0].postCreated,
      'Should handle lowercase transition type'
    );
  }

  /**
   * Test getAvailableTransitionTypes helper method
   */
  @isTest
  static void testGetAvailableTransitionTypes() {
    Test.startTest();
    List<String> types = SuccessionChatterPoster.getAvailableTransitionTypes();
    Test.stopTest();

    Assert.areEqual(5, types.size(), 'Should return 5 transition types');
    Assert.isTrue(
      types.contains('CONTACT_ESTABLISHED'),
      'Should include CONTACT_ESTABLISHED'
    );
    Assert.isTrue(
      types.contains('FORM_COMPLETED'),
      'Should include FORM_COMPLETED'
    );
    Assert.isTrue(
      types.contains('PATHWAY_CONFIRMED'),
      'Should include PATHWAY_CONFIRMED'
    );
    Assert.isTrue(
      types.contains('VERIFICATION_COMPLETE'),
      'Should include VERIFICATION_COMPLETE'
    );
    Assert.isTrue(
      types.contains('EXECUTION_COMPLETE'),
      'Should include EXECUTION_COMPLETE'
    );
  }
}
