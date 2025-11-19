/**
 * SuccessionPathwayEmailSender
 *
 * Invocable Apex class to send pathway form invitation emails to successors.
 * Supports both Person Accounts and Business Accounts with Contact.
 *
 * Called from Flow when Contact_Established__c is set to true.
 * Automatically sets Form_Sent_Date__c after successful email send.
 *
 * CRITICAL FIX (v1.2): Validates email based on successor's Account, not Case.AccountId.
 * Case.AccountId points to the deceased donor, not the successor.
 * This class queries the successor's Contact and Account to get correct email/opt-out status.
 *
 * @author Claude Code
 * @date 2025-01-29
 * @updated 2025-11-16 - Fixed Person Account email validation bug
 */
public with sharing class SuccessionPathwayEmailSender {
  /**
   * Request wrapper for invocable method
   */
  public class EmailRequest {
    @InvocableVariable(
      label='Case ID'
      description='ID of the Case to send pathway form email'
      required=true
    )
    public Id caseId;
  }

  /**
   * Response wrapper for invocable method
   */
  public class EmailResponse {
    @InvocableVariable(label='Success' description='Whether email was sent')
    public Boolean success;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(
      label='Email Sent Date'
      description='Date email was sent'
    )
    public Date emailSentDate;
  }

  /**
   * Send pathway form invitation email to successor
   *
   * PERSON ACCOUNT SUPPORT:
   * - Person Account: Sends to Case.Successor__c (PersonContactId) using successor's Account.PersonEmail
   * - Business Account: Sends to Case.Successor__c (ContactId) using Contact.Email
   *
   * NOTE: Case.AccountId points to deceased donor, not successor.
   * This method queries the successor's Contact and Account to validate email/opt-out status.
   *
   * @param requests List of EmailRequest with caseId
   * @return List of EmailResponse with success status
   */
  @InvocableMethod(
    label='Send Pathway Form Email'
    description='Sends pathway form invitation email to successor and sets Form_Sent_Date__c'
    category='Succession Management'
  )
  public static List<EmailResponse> sendPathwayFormEmail(
    List<EmailRequest> requests
  ) {
    List<EmailResponse> responses = new List<EmailResponse>();

    for (EmailRequest request : requests) {
      EmailResponse response = new EmailResponse();

      try {
        // Query case with successor information
        // NOTE: Case.AccountId points to deceased donor, not successor
        List<Case> cases = [
          SELECT Id, CaseNumber, Successor__c, Form_Sent_Date__c
          FROM Case
          WHERE Id = :request.caseId
          WITH USER_MODE
          LIMIT 1
        ];

        if (cases.isEmpty()) {
          response.success = false;
          response.message = 'Case not found: ' + request.caseId;
          responses.add(response);
          continue;
        }

        Case c = cases[0];

        // Check if email already sent
        if (c.Form_Sent_Date__c != null) {
          response.success = false;
          response.message = 'Pathway form email already sent for this case';
          response.emailSentDate = Date.valueOf(c.Form_Sent_Date__c);
          responses.add(response);
          continue;
        }

        // Validate successor exists
        if (c.Successor__c == null) {
          response.success = false;
          response.message = 'No successor found on case';
          responses.add(response);
          continue;
        }

        // Query successor's Account to get email/opt-out status
        // Successor__c is a Contact lookup, so we need to get the Account via Contact
        List<Contact> successorContacts = [
          SELECT
            Id,
            Email,
            HasOptedOutOfEmail,
            AccountId,
            Account.IsPersonAccount,
            Account.PersonEmail,
            Account.PersonHasOptedOutOfEmail
          FROM Contact
          WHERE Id = :c.Successor__c
          WITH USER_MODE
          LIMIT 1
        ];

        if (successorContacts.isEmpty()) {
          response.success = false;
          response.message = 'Successor contact not found';
          responses.add(response);
          continue;
        }

        Contact successorContact = successorContacts[0];

        // Validate email based on successor's account type
        String emailAddress;
        Boolean hasOptedOut;
        Boolean isPersonAccount = successorContact.Account?.IsPersonAccount ??
          false;

        if (isPersonAccount) {
          // Person Account: Use PersonEmail from successor's Account
          emailAddress = successorContact.Account.PersonEmail;
          hasOptedOut = successorContact.Account.PersonHasOptedOutOfEmail;
        } else {
          // Business Account: Use Contact.Email from successor Contact
          emailAddress = successorContact.Email;
          hasOptedOut = successorContact.HasOptedOutOfEmail;
        }

        // Validate email using SuccessionUtilities
        SuccessionUtilities.EmailValidationResult validation = SuccessionUtilities.validateEmail(
          emailAddress,
          hasOptedOut
        );

        if (!validation.hasEmail || !validation.hasValidFormat) {
          response.success = false;
          response.message = validation.warning;
          responses.add(response);
          continue;
        }

        if (validation.hasOptedOut) {
          response.success = false;
          response.message = 'Cannot send email: Successor has opted out of email communications';
          responses.add(response);
          continue;
        }

        // Get email template
        List<EmailTemplate> templates = [
          SELECT Id, DeveloperName
          FROM EmailTemplate
          WHERE DeveloperName = 'Pathway_Form_Invitation'
          WITH USER_MODE
          LIMIT 1
        ];

        if (templates.isEmpty()) {
          response.success = false;
          response.message = 'Email template not found: Pathway_Form_Invitation';
          responses.add(response);
          continue;
        }

        // Create single email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTemplateId(templates[0].Id);
        email.setTargetObjectId(c.Successor__c); // PersonContactId or ContactId
        email.setWhatId(c.Id); // Case for merge fields
        email.setSaveAsActivity(true); // Log email to Case timeline

        // Send email
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>{
          email
        };
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(
          emails,
          false
        ); // allOrNone = false

        // Check result
        if (results[0].isSuccess()) {
          // Update Form_Sent_Date__c on Case
          c.Form_Sent_Date__c = Date.today();
          Database.update(c, AccessLevel.USER_MODE);

          response.success = true;
          response.message =
            'Pathway form email sent successfully to ' + emailAddress;
          response.emailSentDate = Date.valueOf(c.Form_Sent_Date__c);

          // Create Chatter post
          SuccessionUtilities.createChatterPost(
            c.Id,
            '📧 Pathway form invitation email sent to ' +
              emailAddress +
              ' (' +
              c.Form_Sent_Date__c.format() +
              ')',
            false // useSystemMode
          );
        } else {
          response.success = false;
          response.message =
            'Email send failed: ' + results[0].getErrors()[0].getMessage();
        }
      } catch (Exception e) {
        response.success = false;
        response.message = 'Error sending email: ' + e.getMessage();
        SuccessionLogger.error(
          'Error in sendPathwayFormEmail: ' + e.getMessage()
        );
      }

      responses.add(response);
    }

    return responses;
  }
}
