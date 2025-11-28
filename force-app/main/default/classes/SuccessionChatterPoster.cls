/**
 * SuccessionChatterPoster
 *
 * Invocable Apex class for posting succession workflow transition messages to Chatter.
 * Centralizes all transition message templates and leverages SuccessionUtilities for
 * consistent Chatter post creation.
 *
 * USAGE: Call from Flow using "Post Succession Transition" action
 *
 * TRANSITION TYPES:
 * - CONTACT_ESTABLISHED: Successor contact made, ready to send form
 * - FORM_COMPLETED: Pathway form submitted by successor
 * - PATHWAY_CONFIRMED: Pathway execution tasks generated
 * - VERIFICATION_COMPLETE: Verification phase completed
 * - EXECUTION_COMPLETE: All pathway tasks completed
 *
 * @author Claude Code
 * @date 2025-10-28
 */
public with sharing class SuccessionChatterPoster {
  /**
   * Request wrapper for flow inputs
   */
  public class TransitionRequest {
    @InvocableVariable(
      label='Case ID'
      description='ID of the Case to post transition message to'
      required=true
    )
    public Id caseId;

    @InvocableVariable(
      label='Transition Type'
      description='Type of transition (CONTACT_ESTABLISHED, FORM_COMPLETED, PATHWAY_CONFIRMED, VERIFICATION_COMPLETE, EXECUTION_COMPLETE)'
      required=true
    )
    public String transitionType;

    @InvocableVariable(
      label='Pathway Name'
      description='Name of selected pathway (for FORM_COMPLETED and PATHWAY_CONFIRMED transitions)'
      required=false
    )
    public String pathwayName;

    @InvocableVariable(
      label='Additional Context'
      description='Optional additional context to include in message'
      required=false
    )
    public String additionalContext;
  }

  /**
   * Response wrapper for flow outputs
   */
  public class TransitionResponse {
    @InvocableVariable(
      label='Post Created'
      description='True if Chatter post was created successfully'
    )
    public Boolean postCreated;

    @InvocableVariable(
      label='Feed Item ID'
      description='ID of created FeedItem'
    )
    public Id feedItemId;

    @InvocableVariable(label='Message' description='Status message')
    public String message;
  }

  /**
   * Post succession workflow transition messages to Chatter
   * Invocable method callable from flows
   *
   * @param requests List of transition requests (supports bulk)
   * @return List of responses indicating success/failure
   */
  @InvocableMethod(
    label='Post Succession Transition'
    description='Posts a succession workflow transition message to the Case Chatter feed with standardized formatting.'
    category='Succession Management'
  )
  public static List<TransitionResponse> postTransitions(
    List<TransitionRequest> requests
  ) {
    List<TransitionResponse> responses = new List<TransitionResponse>();

    // Collect Case IDs for bulk query
    Set<Id> caseIds = new Set<Id>();
    for (TransitionRequest req : requests) {
      if (req.caseId != null) {
        caseIds.add(req.caseId);
      }
    }

    // Bulk query Case details for link titles
    Map<Id, Case> casesById = new Map<Id, Case>();
    if (!caseIds.isEmpty()) {
      for (Case c : [
        SELECT Id, CaseNumber, Subject
        FROM Case
        WHERE Id IN :caseIds
        WITH USER_MODE
      ]) {
        casesById.put(c.Id, c);
      }
    }

    for (TransitionRequest req : requests) {
      TransitionResponse response = new TransitionResponse();

      try {
        // Build transition message based on type
        String messageBody = buildTransitionMessage(
          req.transitionType,
          req.pathwayName,
          req.additionalContext
        );

        if (messageBody == null) {
          response.postCreated = false;
          response.message = 'Invalid transition type: ' + req.transitionType;
          responses.add(response);
          continue;
        }

        // Get Case details for link title
        String linkTitle = 'View Case';
        Case caseRecord = casesById.get(req.caseId);
        if (caseRecord != null) {
          // Prefer CaseNumber, fallback to Subject
          linkTitle = String.isNotBlank(caseRecord.CaseNumber)
            ? caseRecord.CaseNumber
            : (String.isNotBlank(caseRecord.Subject)
                ? caseRecord.Subject
                : 'Case ' + req.caseId);
        }

        // Create Chatter post using SuccessionUtilities with Case link
        // Use user mode (false) for flow context - respects sharing
        FeedItem post = SuccessionUtilities.createChatterPostWithRecordLink(
          req.caseId,
          messageBody,
          req.caseId,
          linkTitle,
          false
        );

        response.postCreated = true;
        response.feedItemId = post != null ? post.Id : null;
        response.message = 'Transition posted: ' + req.transitionType;
      } catch (Exception e) {
        response.postCreated = false;
        response.feedItemId = null;
        response.message = 'Error posting transition: ' + e.getMessage();
        SuccessionLogger.error(
          'SuccessionChatterPoster error: ' + e.getMessage()
        );
        SuccessionLogger.error('Stack trace: ' + e.getStackTraceString());
      }

      responses.add(response);
    }

    return responses;
  }

  /**
   * Build transition message based on type and context
   * Centralizes all succession workflow transition message templates
   *
   * @param transitionType Type of transition
   * @param pathwayName Optional pathway name for relevant transitions
   * @param additionalContext Optional additional context
   * @return Formatted message body or null if invalid type
   */
  private static String buildTransitionMessage(
    String transitionType,
    String pathwayName,
    String additionalContext
  ) {
    if (String.isBlank(transitionType)) {
      return null;
    }

    String message;

    switch on transitionType.toUpperCase() {
      when 'CONTACT_ESTABLISHED' {
        message =
          '📞 ✅ Workflow Transition: Contact established with successor.\n\n' +
          'Case moved to "Awaiting Form" segment.\n' +
          'Next: Send pathway selection form.';
      }
      when 'FORM_COMPLETED' {
        String pathway = String.isNotBlank(pathwayName)
          ? pathwayName
          : '[Not Specified]';
        message =
          '✅ 📋 Workflow Transition: Pathway form completed.\n\n' +
          'Pathway: ' +
          pathway +
          '\n' +
          'Case moved to "Form Completed" segment.\n' +
          'Next: Gather required documentation.';
      }
      when 'PATHWAY_CONFIRMED' {
        String pathway = String.isNotBlank(pathwayName)
          ? pathwayName
          : '[Not Specified]';
        message =
          '🎯 Workflow Transition: Pathway execution started.\n\n' +
          'Pathway: ' +
          pathway +
          '\n' +
          'Execution tasks have been created.\n' +
          'Next: Complete pathway-specific tasks.';
      }
      when 'VERIFICATION_COMPLETE' {
        message =
          '✅ Workflow Transition: Verification phase completed.\n\n' +
          'Case moved to "Contact Cadence" segment.\n' +
          'Next: Contact successor to establish communication.';
      }
      when 'EXECUTION_COMPLETE' {
        message =
          '🏁 Workflow Transition: Pathway execution completed.\n\n' +
          'All execution tasks completed successfully.\n' +
          'Next: Final case review and closure.';
      }
      when else {
        // Unknown transition type
        return null;
      }
    }

    // Append additional context if provided
    if (String.isNotBlank(additionalContext)) {
      message += '\n\nAdditional Notes:\n' + additionalContext;
    }

    return message;
  }

  /**
   * Get available transition types
   * Helper method for documentation and validation
   *
   * @return List of valid transition type values
   */
  public static List<String> getAvailableTransitionTypes() {
    return new List<String>{
      'CONTACT_ESTABLISHED',
      'FORM_COMPLETED',
      'PATHWAY_CONFIRMED',
      'VERIFICATION_COMPLETE',
      'EXECUTION_COMPLETE'
    };
  }
}
