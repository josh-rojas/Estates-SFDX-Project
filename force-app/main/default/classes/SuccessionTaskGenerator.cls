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
 * New DAF: 4 tasks over 18 days
 * Disclaim: 4 tasks over 20 days
 */
public with sharing class SuccessionTaskGenerator {
    
    /**
     * @description Creates pathway tasks for Cases with confirmed pathways
     * @param newCases List of Cases being updated
     * @param oldCaseMap Map of old Case values
     */
    public static void createPathwayTasks(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        List<Task> tasksToCreate = new List<Task>();
        List<FeedItem> chatterPostsToCreate = new List<FeedItem>();
        
        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);
            
            // Check if Pathway_Confirmed__c just changed
            if (c.Pathway_Confirmed__c != null && 
                c.Pathway_Confirmed__c != oldCase.Pathway_Confirmed__c) {
                
                Date startDate = c.Form_Completed_Date__c != null ? c.Form_Completed_Date__c.date() : Date.today();
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
                    tasksToCreate.addAll(pathwayTasks);
                    
                    // Prepare Chatter post
                    FeedItem post = new FeedItem(
                        ParentId = c.Id,
                        Body = pathwayTasks.size() + ' pathway tasks created for: ' + c.Pathway_Confirmed__c + '. Review milestones in Activities to guide the case through completion.',
                        Type = 'TextPost'
                    );
                    chatterPostsToCreate.add(post);
                }
            }
        }
        
        // Insert Tasks
        if (!tasksToCreate.isEmpty()) {
            try {
                insert tasksToCreate;
                System.debug('Created ' + tasksToCreate.size() + ' pathway tasks');
            } catch (DmlException e) {
                System.debug('Error creating pathway tasks: ' + e.getMessage());
            }
        }
        
        // Insert Chatter posts
        if (!chatterPostsToCreate.isEmpty()) {
            try {
                insert chatterPostsToCreate;
            } catch (DmlException e) {
                System.debug('Error creating Chatter posts: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Generates Final Grant pathway tasks (5 tasks over 20 days)
     */
    private static List<Task> generateFinalGrantTasks(Id caseId, Id ownerId, Date startDate) {
        return new List<Task>{
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Review Grant Direction & Beneficiaries',
                Description = 'Review the successor\'s grant direction from the pathway form. Verify charity information against IRS database. Contact successor if clarification needed on beneficiary details or grant amounts. Guidance checkpoint—use judgment on next steps.',
                Priority = 'High',
                ActivityDate = startDate.addDays(2),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Coordinate Trading / Liquidation',
                Description = 'If the account holds investments requiring liquidation, coordinate with MyQ/G360 for trading. Monitor settlement (typically T+3). No action needed if account is already in cash. Document coordination insights in Chatter.',
                Priority = 'High',
                ActivityDate = startDate.addDays(5),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Process Grant Recommendations',
                Description = 'Enter grant instructions in Charities Profile and route through Internal Grants Office approval. Ensure documentation is complete before submission. Note any compliance concerns for follow-up.',
                Priority = 'High',
                ActivityDate = startDate.addDays(10),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Confirm Distributions & Settlement',
                Description = 'Verify all grant distributions completed successfully. Coordinate with Finance if settlement confirmation is needed. Capture final payout notes on the case timeline.',
                Priority = 'Normal',
                ActivityDate = startDate.addDays(15),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Finalize Case Documentation',
                Description = 'Complete final case summary, attach supporting documents, and update Financial Account status. Prepare the case for closure review with leadership.',
                Priority = 'Normal',
                ActivityDate = startDate.addDays(20),
                Status = 'Not Started'
            )
        };
    }
    
    /**
     * @description Generates New DAF pathway tasks (4 tasks over 18 days)
     */
    private static List<Task> generateNewDAFTasks(Id caseId, Id ownerId, Date startDate) {
        return new List<Task>{
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Review New Account Application',
                Description = 'Review the successor\'s new account application for completeness. Reach out if any fields need clarification. Capture key notes so downstream teams understand context.',
                Priority = 'High',
                ActivityDate = startDate.addDays(2),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Process Transfer Authorization',
                Description = 'Coordinate internal journal entry to move assets to the successor\'s new DAF. Suppress external documentation per policy. Track progress in case chatter.',
                Priority = 'High',
                ActivityDate = startDate.addDays(7),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Update Account Relationships & Status',
                Description = 'Update both the legacy and new Financial Account records. Confirm successor portal access and document the outcome for reporting.',
                Priority = 'Normal',
                ActivityDate = startDate.addDays(12),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Finalize Transfer & Close Case',
                Description = 'Confirm asset transfer completion, capture successor satisfaction notes, and prepare the case for closure with summarized outcomes.',
                Priority = 'Normal',
                ActivityDate = startDate.addDays(18),
                Status = 'Not Started'
            )
        };
    }
    
    /**
     * @description Generates Disclaim pathway tasks (4 tasks over 20 days)
     */
    private static List<Task> generateDisclaimTasks(Id caseId, Id ownerId, Date startDate) {
        return new List<Task>{
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Review Disclaimer Documentation',
                Description = 'Review formal disclaimer submission for completeness and validity. Escalate to legal if anything is unclear or missing. Capture key notes for the audit trail.',
                Priority = 'High',
                ActivityDate = startDate.addDays(3),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Identify Alternate Distribution Path',
                Description = 'Review succession plan for alternate successors or beneficiary charities. If none exist, consult philanthropy guidelines to determine next best distribution. Document reasoning clearly.',
                Priority = 'High',
                ActivityDate = startDate.addDays(8),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Process Asset Distribution',
                Description = 'Execute the planned distribution (alternate successor, charity, or Philanthropy Fund). Coordinate with MyQ/G360 if trading or liquidation required. Capture updates in Chatter.',
                Priority = 'Normal',
                ActivityDate = startDate.addDays(15),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = caseId,
                OwnerId = ownerId,
                Subject = 'Complete Disclaimer Processing & Close',
                Description = 'Finalize compliance review, update Financial Account status, and summarize outcomes. Prepare the case for leadership sign-off and closure.',
                Priority = 'Normal',
                ActivityDate = startDate.addDays(20),
                Status = 'Not Started'
            )
        };
    }
}
