/**
 * @description Generates pathway tasks for Succession Cases based on Action Plan Template structure
 * @author Salesforce
 * @date October 2025
 *
 * Creates a series of milestone tasks when Case.Pathway_Confirmed__c is set, mirroring
 * the structure of Action Plan Templates but using standard Task objects.
 *
 * Benefits over Action Plans:
 * - Can be deployed via Apex (no metadata API limitations)
 * - Appears in standard Activities timeline
 * - Fully automated trigger-based creation
 * - No UI clicks required
 *
 * Template Structure:
 * Final Grant: 5 tasks over 20 days
 * New DAF Account: 4 tasks over 18 days
 * Disclaim Assets: 4 tasks over 20 days
 */
public with sharing class SuccessionTaskGenerator {
  /**
   * @description Creates pathway tasks for Cases with confirmed pathways
   * @param newCases List of Cases being updated
   * @param oldCaseMap Map of old Case values
   */
  public static void createPathwayTasks(
    List<Case> newCases,
    Map<Id, Case> oldCaseMap
  ) {
    List<Task> tasksToCreate = new List<Task>();
    Map<Id, String> chatterPostsByCaseId = new Map<Id, String>();

    // Guard against null oldCaseMap (shouldn't happen in after update, but defensive)
    if (oldCaseMap == null) {
      return;
    }

    // Collect case IDs for pathway confirmation changes
    Set<Id> caseIdsForPathwayTasks = new Set<Id>();
    for (Case c : newCases) {
      Case oldCase = oldCaseMap.get(c.Id);
      if (
        c.Pathway_Confirmed__c != null &&
        (oldCase == null ||
        c.Pathway_Confirmed__c != oldCase.Pathway_Confirmed__c)
      ) {
        caseIdsForPathwayTasks.add(c.Id);
      }
    }

    // Query existing pathway tasks to prevent duplicates
    Map<Id, Set<String>> existingTasksByCaseId = new Map<Id, Set<String>>();
    if (!caseIdsForPathwayTasks.isEmpty()) {
      Set<String> allPathwaySubjects = getAllPathwayTaskSubjects();
      for (Task t : [
        SELECT WhatId, Subject
        FROM Task
        WHERE
          WhatId IN :caseIdsForPathwayTasks
          AND Subject IN :allPathwaySubjects
        WITH SYSTEM_MODE
      ]) {
        if (!existingTasksByCaseId.containsKey(t.WhatId)) {
          existingTasksByCaseId.put(t.WhatId, new Set<String>());
        }
        existingTasksByCaseId.get(t.WhatId).add(t.Subject);
      }
    }

    for (Case c : newCases) {
      Case oldCase = oldCaseMap.get(c.Id);

      // Check if Pathway_Confirmed__c just changed
      if (
        c.Pathway_Confirmed__c != null &&
        (oldCase == null ||
        c.Pathway_Confirmed__c != oldCase.Pathway_Confirmed__c)
      ) {
        Date startDate = c.Form_Completed_Date__c != null
          ? c.Form_Completed_Date__c.date()
          : Date.today();
        List<Task> pathwayTasks = null;

        // Generate tasks based on pathway
        if (c.Pathway_Confirmed__c == 'Final Grant') {
          pathwayTasks = generateFinalGrantTasks(c.Id, c.OwnerId, startDate);
        } else if (c.Pathway_Confirmed__c == 'New DAF Account') {
          pathwayTasks = generateNewDAFTasks(c.Id, c.OwnerId, startDate);
        } else if (c.Pathway_Confirmed__c == 'Disclaim Assets') {
          pathwayTasks = generateDisclaimTasks(c.Id, c.OwnerId, startDate);
        }

        if (pathwayTasks != null && !pathwayTasks.isEmpty()) {
          // Filter out duplicate tasks
          Set<String> existingForCase = existingTasksByCaseId.get(c.Id);
          List<Task> tasksToAdd = new List<Task>();
          Integer skippedCount = 0;

          for (Task t : pathwayTasks) {
            if (
              existingForCase == null || !existingForCase.contains(t.Subject)
            ) {
              tasksToAdd.add(t);
            } else {
              SuccessionLogger.debug(
                'Skipping duplicate task for case ' + c.Id + ': ' + t.Subject
              );
              skippedCount++;
            }
          }

          if (!tasksToAdd.isEmpty()) {
            tasksToCreate.addAll(tasksToAdd);

            // Prepare Chatter post using SuccessionUtilities for consistent formatting
            String postBody = SuccessionUtilities.buildPathwayTaskPostBody(
              c.Pathway_Confirmed__c,
              tasksToAdd.size()
            );
            chatterPostsByCaseId.put(c.Id, postBody);
          } else if (skippedCount > 0) {
            SuccessionLogger.debug(
              'All ' +
                skippedCount +
                ' pathway tasks already exist for case ' +
                c.Id
            );
          }
        }
      }
    }

    // SYSTEM_MODE required because:
    // 1. Guest users submit pathway forms triggering this automation via trigger
    // 2. Guest user profile lacks Task create permission by security design
    // 3. Alternative (scheduled batch job) would create poor UX with delayed task creation
    // 4. Tasks are system-generated workflow milestones, not user-created activities
    if (!tasksToCreate.isEmpty()) {
      try {
        Database.insert(tasksToCreate, false, AccessLevel.SYSTEM_MODE);
        SuccessionLogger.debug(
          'Created ' + tasksToCreate.size() + ' pathway tasks'
        );
      } catch (DmlException e) {
        SuccessionLogger.error(
          'Error creating pathway tasks: ' + e.getMessage()
        );
      }
    }

    // Create Chatter posts using SuccessionUtilities with Case links
    if (!chatterPostsByCaseId.isEmpty()) {
      // Bulk query Case details for link titles
      Map<Id, Case> casesById = new Map<Id, Case>(
        [
          SELECT Id, CaseNumber, Subject
          FROM Case
          WHERE Id IN :chatterPostsByCaseId.keySet()
        ]
      );

      List<SuccessionUtilities.PostRequest> postRequests = new List<SuccessionUtilities.PostRequest>();

      for (Id caseId : chatterPostsByCaseId.keySet()) {
        // Get Case details for link title
        String linkTitle = 'View Case';
        Case caseRecord = casesById.get(caseId);
        if (caseRecord != null) {
          // Prefer CaseNumber, fallback to Subject
          linkTitle = String.isNotBlank(caseRecord.CaseNumber)
            ? caseRecord.CaseNumber
            : (String.isNotBlank(caseRecord.Subject)
                ? caseRecord.Subject
                : 'Case ' + caseId);
        }

        postRequests.add(
          new SuccessionUtilities.PostRequest(
            caseId,
            chatterPostsByCaseId.get(caseId),
            caseId,
            linkTitle
          )
        );
      }

      // Use bulk creation method
      if (!postRequests.isEmpty()) {
        SuccessionUtilities.createChatterPostsWithRecordLinks(
          postRequests,
          true // Use SYSTEM_MODE for automation reliability
        );
      }
    }
  }

  /**
   * @description Returns all possible pathway task subjects for duplicate detection
   */
  private static Set<String> getAllPathwayTaskSubjects() {
    Set<String> subjects = new Set<String>();

    // Final Grant subjects
    subjects.add('Review Grant Direction & Beneficiaries');
    subjects.add('Coordinate Trading / Liquidation');
    subjects.add('Process Grant Recommendations');
    subjects.add('Confirm Distributions & Settlement');
    subjects.add('Finalize Case Documentation');

    // New DAF Account subjects
    subjects.add('Review New Account Application');
    subjects.add('Process Transfer Authorization');
    subjects.add('Update Account Relationships & Status');
    subjects.add('Finalize Transfer & Close Case');

    // Disclaim Assets subjects
    subjects.add('Review Disclaimer Documentation');
    subjects.add('Identify Alternate Distribution Path');
    subjects.add('Process Asset Distribution');
    subjects.add('Complete Disclaimer Processing & Close');

    return subjects;
  }

  /**
   * @description Generates Final Grant pathway tasks (5 tasks over 20 days)
   */
  private static List<Task> generateFinalGrantTasks(
    Id caseId,
    Id ownerId,
    Date startDate
  ) {
    return new List<Task>{
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Review Grant Direction & Beneficiaries',
        Description = 'Review the successor\'s grant direction from the pathway form. Verify charity information against IRS database. Contact successor if clarification needed on beneficiary details or grant amounts. Guidance checkpoint—use judgment on next steps.',
        Priority = 'High',
        ActivityDate = startDate.addDays(2),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Coordinate Trading / Liquidation',
        Description = 'If the account holds investments requiring liquidation, coordinate with MyQ/G360 for trading. Monitor settlement (typically T+3). No action needed if account is already in cash. Document coordination insights in Chatter.',
        Priority = 'High',
        ActivityDate = startDate.addDays(5),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Process Grant Recommendations',
        Description = 'Enter grant instructions in Charities Profile and route through Internal Grants Office approval. Ensure documentation is complete before submission. Note any compliance concerns for follow-up.',
        Priority = 'High',
        ActivityDate = startDate.addDays(10),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Confirm Distributions & Settlement',
        Description = 'Verify all grant distributions completed successfully. Coordinate with Finance if settlement confirmation is needed. Capture final payout notes on the case timeline.',
        Priority = 'Normal',
        ActivityDate = startDate.addDays(15),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Finalize Case Documentation',
        Description = 'Complete final case summary, attach supporting documents, and update Financial Account status. Prepare the case for closure review with leadership.',
        Priority = 'Normal',
        ActivityDate = startDate.addDays(20),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      )
    };
  }

  /**
   * @description Generates New DAF pathway tasks (4 tasks over 18 days)
   */
  private static List<Task> generateNewDAFTasks(
    Id caseId,
    Id ownerId,
    Date startDate
  ) {
    return new List<Task>{
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Review New Account Application',
        Description = 'Review the successor\'s new account application for completeness. Reach out if any fields need clarification. Capture key notes so downstream teams understand context.',
        Priority = 'High',
        ActivityDate = startDate.addDays(2),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Process Transfer Authorization',
        Description = 'Coordinate internal journal entry to move assets to the successor\'s new DAF. Suppress external documentation per policy. Track progress in case chatter.',
        Priority = 'High',
        ActivityDate = startDate.addDays(7),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Update Account Relationships & Status',
        Description = 'Update both the legacy and new Financial Account records. Confirm successor portal access and document the outcome for reporting.',
        Priority = 'Normal',
        ActivityDate = startDate.addDays(12),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Finalize Transfer & Close Case',
        Description = 'Confirm asset transfer completion, capture successor satisfaction notes, and prepare the case for closure with summarized outcomes.',
        Priority = 'Normal',
        ActivityDate = startDate.addDays(18),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      )
    };
  }

  /**
   * @description Generates Disclaim pathway tasks (4 tasks over 20 days)
   */
  private static List<Task> generateDisclaimTasks(
    Id caseId,
    Id ownerId,
    Date startDate
  ) {
    return new List<Task>{
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Review Disclaimer Documentation',
        Description = 'Review formal disclaimer submission for completeness and validity. Escalate to legal if anything is unclear or missing. Capture key notes for the audit trail.',
        Priority = 'High',
        ActivityDate = startDate.addDays(3),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Identify Alternate Distribution Path',
        Description = 'Review succession plan for alternate successors or beneficiary charities. If none exist, consult philanthropy guidelines to determine next best distribution. Document reasoning clearly.',
        Priority = 'High',
        ActivityDate = startDate.addDays(8),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Process Asset Distribution',
        Description = 'Execute the planned distribution (alternate successor, charity, or Philanthropy Fund). Coordinate with MyQ/G360 if trading or liquidation required. Capture updates in Chatter.',
        Priority = 'Normal',
        ActivityDate = startDate.addDays(15),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      ),
      new Task(
        WhatId = caseId,
        OwnerId = ownerId,
        Subject = 'Complete Disclaimer Processing & Close',
        Description = 'Finalize compliance review, update Financial Account status, and summarize outcomes. Prepare the case for leadership sign-off and closure.',
        Priority = 'Normal',
        ActivityDate = startDate.addDays(20),
        Status = 'Not Started',
        TaskSubtype = 'Task'
      )
    };
  }
}
