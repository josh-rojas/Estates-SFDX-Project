/**
 * @description Comprehensive test data factory for DAF Account Succession Management
 * @author Salesforce Architecture Team
 * @date 2025-01-31
 * @brd /docs/product/daf-account-succession-brd.md
 * @plan /docs/test-data-plan-succession.md
 *
 * This factory generates context-aware, BRD-aligned test data for succession workflows.
 * Supports all three succession pathways: Final Grant, New DAF Account, Disclaim Assets.
 *
 * Usage Examples:
 * - SuccessionTestDataFactory.generateCompleteDataset()
 * - SuccessionTestDataFactory.generateHappyPathFinalGrant()
 * - new SuccessionTestDataFactory.DeceasedDonorBuilder().withName('John', 'Doe').buildAndInsert()
 */
public class SuccessionTestDataFactory {
  // ==================== STATIC RECORD TYPE IDS ====================

  private static Id personAccountRecordTypeId;
  private static Id businessAccountRecordTypeId;
  private static Id clientAssociateTaskRecordTypeId;
  private static Id clientAssociateEventRecordTypeId;

  static {
    // Query for PersonAccount record type (required for Person Accounts)
    List<RecordType> personAccountRecordTypes = [
      SELECT Id
      FROM RecordType
      WHERE
        SobjectType = 'Account'
        AND DeveloperName = 'PersonAccount'
        AND IsActive = TRUE
      LIMIT 1
    ];
    if (!personAccountRecordTypes.isEmpty()) {
      personAccountRecordTypeId = personAccountRecordTypes[0].Id;
    }

    // Query for Business record type (required for Business Accounts)
    List<RecordType> businessAccountRecordTypes = [
      SELECT Id
      FROM RecordType
      WHERE
        SobjectType = 'Account'
        AND DeveloperName = 'IndustriesBusiness'
        AND IsActive = TRUE
      LIMIT 1
    ];
    if (!businessAccountRecordTypes.isEmpty()) {
      businessAccountRecordTypeId = businessAccountRecordTypes[0].Id;
    }

    // Query for Activity record types
    List<RecordType> taskRecordTypes = [
      SELECT Id
      FROM RecordType
      WHERE
        SobjectType = 'Task'
        AND DeveloperName = 'ClientAssociateTask'
        AND IsActive = TRUE
      LIMIT 1
    ];
    if (!taskRecordTypes.isEmpty()) {
      clientAssociateTaskRecordTypeId = taskRecordTypes[0].Id;
    }

    List<RecordType> eventRecordTypes = [
      SELECT Id
      FROM RecordType
      WHERE
        SobjectType = 'Event'
        AND DeveloperName = 'ClientAssociateEvent'
        AND IsActive = TRUE
      LIMIT 1
    ];
    if (!eventRecordTypes.isEmpty()) {
      clientAssociateEventRecordTypeId = eventRecordTypes[0].Id;
    }
  }

  // ==================== DML OPTIONS ====================

  /**
   * @description Get DML options to bypass duplicate rules and allow partial success
   * @return Database.DMLOptions configured for test data
   */
  private static Database.DMLOptions getDmlOptions() {
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.AllowSave = true;
    dml.DuplicateRuleHeader.RunAsCurrentUser = true;
    dml.OptAllOrNone = false; // Allow partial success
    return dml;
  }

  // ==================== CONSTANTS ====================

  private static final String RECORD_TYPE_PERSON_ACCOUNT = 'PersonAccount';
  private static final String ACCOUNT_TYPE_DONOR = 'Donor';
  private static final String ACCOUNT_TYPE_PROSPECT = 'Prospect';
  private static final String ACCOUNT_TYPE_ADVISOR = 'Advisor';

  private static final String FA_TYPE_DAF = 'DAF/Donor Advised Fund';
  private static final String FA_STATUS_ACTIVE = 'Active';
  private static final String FA_STATUS_FROZEN = 'Frozen - Pending Estate Settlement';

  private static final String ROLE_SUCCESSOR = 'Successor';
  private static final String ROLE_ADVISOR = 'Advisor';
  private static final String ROLE_PRIMARY_OWNER = 'Primary Owner';

  private static final String CASE_TYPE_SUCCESSION = 'Named Successor Enactment';
  private static final String CASE_STATUS_NEW = 'New';
  private static final String CASE_STATUS_IN_PROGRESS = 'In Progress';
  private static final String CASE_STATUS_CLOSED = 'Closed';

  private static Integer accountCounter = 1000;
  private static Integer caseCounter = 1;

  // ==================== LOGGING & TIMING HELPERS ====================

  private static Long nowMs() {
    return System.now().getTime();
  }

  // TODO: Route structured logs through a central LoggingService once available so these builders can participate in org-wide telemetry.
  private static String formatLog(
    String category,
    String message,
    Map<String, Object> context
  ) {
    StringBuilder log = new StringBuilder(
      '[SuccessionTestDataFactory][' + category + '] ' + message
    );
    if (context != null && !context.isEmpty()) {
      log.append(' | context=' + JSON.serialize(context));
    }
    return log.toString();
  }

  private static void logInfo(
    String category,
    String message,
    Map<String, Object> context
  ) {
    System.debug(LoggingLevel.INFO, formatLog(category, message, context));
  }

  private static void logDebug(
    String category,
    String message,
    Map<String, Object> context
  ) {
    System.debug(LoggingLevel.DEBUG, formatLog(category, message, context));
  }

  private static void logWarn(
    String category,
    String message,
    Map<String, Object> context
  ) {
    System.debug(LoggingLevel.WARN, formatLog(category, message, context));
  }

  private static void logError(
    String category,
    String message,
    Map<String, Object> context
  ) {
    System.debug(LoggingLevel.ERROR, formatLog(category, message, context));
  }

  private static Map<String, Object> describeRecord(SObject record) {
    Map<String, Object> description = new Map<String, Object>();
    description.put('type', record.getSObjectType().getDescribe().getName());
    description.put('fields', record.getPopulatedFieldsAsMap());
    return description;
  }

  private static Map<String, Object> dmlContext(
    String builderName,
    SObject record
  ) {
    Map<String, Object> ctx = describeRecord(record);
    ctx.put('builder', builderName);
    return ctx;
  }

  private static Map<String, Object> dmlResultContext(
    String builderName,
    Id recordId,
    Long durationMs
  ) {
    Map<String, Object> ctx = new Map<String, Object>();
    ctx.put('builder', builderName);
    ctx.put('recordId', recordId);
    ctx.put('durationMs', durationMs);
    return ctx;
  }

  private static Map<String, Object> dmlErrorContext(
    String builderName,
    SObject record,
    List<Database.Error> errors,
    Long durationMs
  ) {
    Map<String, Object> ctx = dmlContext(builderName, record);
    ctx.put('durationMs', durationMs);
    List<Map<String, Object>> errorSummaries = new List<Map<String, Object>>();
    for (Database.Error error : errors) {
      Map<String, Object> errorMap = new Map<String, Object>();
      errorMap.put('statusCode', String.valueOf(error.getStatusCode()));
      errorMap.put('message', error.getMessage());
      errorMap.put('fields', error.getFields());
      errorSummaries.add(errorMap);
    }
    ctx.put('errors', errorSummaries);
    return ctx;
  }

  private static String joinErrorMessages(List<Database.Error> errors) {
    List<String> messages = new List<String>();
    for (Database.Error e : errors) {
      messages.add(
        '[' + String.valueOf(e.getStatusCode()) + '] ' + e.getMessage()
      );
    }
    return String.join(messages, ' | ');
  }

  private static void logBuilder(
    String builderName,
    String step,
    Map<String, Object> context
  ) {
    Map<String, Object> ctx = context == null
      ? new Map<String, Object>()
      : context.clone();
    ctx.put('builder', builderName);
    logDebug('Builder', step, ctx);
  }

  private static Long scenarioStart(String scenarioName) {
    logInfo('Scenario', 'Starting ' + scenarioName, null);
    return nowMs();
  }

  private static Long scenarioEnd(
    String scenarioName,
    Long startMs,
    Map<String, Object> context
  ) {
    Long duration = nowMs() - startMs;
    Map<String, Object> ctx = context == null
      ? new Map<String, Object>()
      : context.clone();
    ctx.put('durationMs', duration);
    logInfo('Scenario', 'Completed ' + scenarioName, ctx);
    return duration;
  }

  private static void insertWithLogging(
    String builderName,
    SObject record,
    Database.DMLOptions options
  ) {
    Long start = nowMs();
    logInfo(
      'DML',
      builderName + ' insert attempt',
      dmlContext(builderName, record)
    );
    Database.SaveResult result = Database.insert(record, options);
    Long duration = nowMs() - start;
    if (result.isSuccess()) {
      logInfo(
        'DML',
        builderName + ' insert success',
        dmlResultContext(builderName, result.getId(), duration)
      );
    } else {
      List<Database.Error> errors = new List<Database.Error>(
        result.getErrors()
      );
      logError(
        'DML',
        builderName + ' insert failed',
        dmlErrorContext(builderName, record, errors, duration)
      );
      System.assert(
        false,
        builderName + ' insert failed: ' + joinErrorMessages(errors)
      );
    }
  }

  private static void insertWithLogging(
    String contextLabel,
    List<SObject> records
  ) {
    if (records == null || records.isEmpty()) {
      logInfo('DML', contextLabel + ' insert skipped (no records)', null);
      return;
    }
    Long start = nowMs();
    Map<String, Object> ctx = new Map<String, Object>();
    ctx.put('count', records.size());
    ctx.put('type', records[0].getSObjectType().getDescribe().getName());
    logInfo('DML', contextLabel + ' bulk insert attempt', ctx);
    Database.SaveResult[] results = Database.insert(records, false);
    Long duration = nowMs() - start;
    List<String> failures = new List<String>();
    for (Integer i = 0; i < results.size(); i++) {
      if (!results[i].isSuccess()) {
        List<Database.Error> errors = new List<Database.Error>(
          results[i].getErrors()
        );
        Map<String, Object> errorContext = dmlErrorContext(
          contextLabel + ' bulk',
          records[i],
          errors,
          duration
        );
        logError('DML', contextLabel + ' bulk insert failure', errorContext);
        failures.add(joinErrorMessages(errors));
      }
    }
    if (!failures.isEmpty()) {
      System.assert(
        false,
        contextLabel +
          ' bulk insert encountered errors: ' +
          String.join(failures, ' || ')
      );
    } else {
      Map<String, Object> successCtx = new Map<String, Object>();
      successCtx.put('count', records.size());
      successCtx.put('durationMs', duration);
      logInfo('DML', contextLabel + ' bulk insert success', successCtx);
    }
  }

  private static void updateWithLogging(String builderName, SObject record) {
    Long start = nowMs();
    logInfo(
      'DML',
      builderName + ' update attempt',
      dmlContext(builderName, record)
    );
    Database.SaveResult result = Database.update(record, false);
    Long duration = nowMs() - start;
    if (result.isSuccess()) {
      logInfo(
        'DML',
        builderName + ' update success',
        dmlResultContext(builderName, result.getId(), duration)
      );
    } else {
      List<Database.Error> errors = new List<Database.Error>(
        result.getErrors()
      );
      logError(
        'DML',
        builderName + ' update failed',
        dmlErrorContext(builderName, record, errors, duration)
      );
      System.assert(
        false,
        builderName + ' update failed: ' + joinErrorMessages(errors)
      );
    }
  }

  private static void insertTaskList(String contextLabel, List<Task> tasks) {
    List<SObject> taskRecords = new List<SObject>();
    if (tasks != null) {
      taskRecords.addAll(tasks);
    }
    insertWithLogging(contextLabel, taskRecords);
    // TODO: Capture taskRecords IDs for downstream sequencing audits (e.g., to confirm call/email cadence ordering during assertions).
  }

  private static ValidationReport buildScenarioValidation(
    String scenarioName,
    SuccessionScenarioData data
  ) {
    ValidationReport report = new ValidationReport();
    report.name = scenarioName;

    report.addCount(
      'successors',
      data.successors != null ? data.successors.size() : 0
    );
    report.addCount('roles', data.roles != null ? data.roles.size() : 0);
    report.addCount(
      'contactTasks',
      data.contactTasks != null ? data.contactTasks.size() : 0
    );
    report.addCount(
      'meetings',
      data.meetings != null ? data.meetings.size() : 0
    );
    report.addCount(
      'chatterPosts',
      data.chatterPosts != null ? data.chatterPosts.size() : 0
    );

    if (data.deceasedDonor == null) {
      report.errors.add('Scenario missing deceased donor account.');
    }
    if (data.financialAccount == null) {
      report.errors.add('Scenario missing financial account.');
    }
    if (data.successors == null || data.successors.isEmpty()) {
      report.errors.add('Scenario missing successor records.');
    }
    if (data.successionCase == null) {
      report.errors.add('Scenario missing succession case.');
    }
    if (data.roles == null || data.roles.isEmpty()) {
      report.warnings.add(
        'Scenario does not include any financial account roles.'
      );
    }
    if (data.contactTasks == null || data.contactTasks.isEmpty()) {
      report.warnings.add('Scenario does not include contact attempt tasks.');
    }
    if (
      data.successionCase != null &&
      String.isBlank(data.successionCase.Pathway_Confirmed__c)
    ) {
      report.warnings.add('Succession case has no confirmed pathway.');
    }
    // TODO: Enrich validation to verify allocations sum to 100% when multiple successors exist and to ensure task cadence aligns with BRD timelines.

    Map<String, Object> context = new Map<String, Object>();
    context.put('scenario', scenarioName);
    context.put('counts', report.counts);
    context.put('warnings', report.warnings.size());
    context.put('errors', report.errors.size());
    logInfo('Validation', 'Scenario validation completed', context);

    return report;
  }

  private static ValidationReport buildDatasetValidation(
    SuccessionTestData dataset
  ) {
    ValidationReport report = new ValidationReport();
    report.name = 'SuccessionTestDataDataset';

    report.addCount('deceasedDonors', dataset.deceasedDonors.size());
    report.addCount('successors', dataset.successors.size());
    report.addCount('advisorFirms', dataset.advisorFirms.size());
    report.addCount('financialAccounts', dataset.financialAccounts.size());
    report.addCount('roles', dataset.roles.size());
    report.addCount('cases', dataset.successionCases.size());
    report.addCount('tasks', dataset.contactTasks.size());
    report.addCount('meetings', dataset.meetings.size());
    report.addCount('chatterPosts', dataset.chatterPosts.size());

    if (dataset.deceasedDonors.isEmpty()) {
      report.errors.add('Dataset contains no deceased donors.');
    }
    if (dataset.successionCases.isEmpty()) {
      report.errors.add('Dataset contains no succession cases.');
    }
    if (dataset.roles.isEmpty()) {
      report.warnings.add('Dataset has no financial account roles.');
    }
    if (dataset.contactTasks.isEmpty()) {
      report.warnings.add('Dataset has no contact tasks.');
    }
    // TODO: Extend dataset-level validation to cross-check that each scenario contributes at least one chatter post and that advisor firms are reused within expected frequency bands.

    Map<String, Object> context = new Map<String, Object>();
    context.put('counts', report.counts);
    context.put('warnings', report.warnings.size());
    context.put('errors', report.errors.size());
    logInfo('Validation', 'Dataset validation completed', context);

    return report;
  }

  // ==================== BUILDER: DECEASED DONOR ====================

  /**
   * @description Builder for Person Account (Deceased Donor)
   */
  public class DeceasedDonorBuilder {
    private Account donor;

    public DeceasedDonorBuilder() {
      donor = new Account();

      // Set PersonAccount record type (required for Person Accounts)
      if (personAccountRecordTypeId != null) {
        donor.RecordTypeId = personAccountRecordTypeId;
      }

      // Default values per Section 4.1 of test-data-plan
      donor.FirstName = 'John';
      donor.LastName = 'Donor' + accountCounter++;
      donor.Salutation = 'Mr.';
      donor.PersonBirthdate = Date.newInstance(1945, 6, 15);
      donor.Type = ACCOUNT_TYPE_DONOR;
      donor.Deceased__c = true;
      donor.Date_of_Death__c = Date.today().addDays(-30);

      donor.PersonEmail =
        donor.FirstName.toLowerCase() +
        '.' +
        donor.LastName.toLowerCase() +
        '@legacy-estate.example.com';
      donor.PersonMobilePhone =
        '(555) 000-' +
        String.valueOf(Math.round(Math.random() * 9999)).leftPad(4, '0');
      donor.PersonHomePhone =
        '(555) 001-' +
        String.valueOf(Math.round(Math.random() * 9999)).leftPad(4, '0');

      donor.PersonMailingStreet = '123 Estate Lane';
      donor.PersonMailingCity = 'San Francisco';
      donor.PersonMailingState = 'CA';
      donor.PersonMailingPostalCode = '94102';
      donor.PersonMailingCountry = 'United States';

      donor.FinServ__ClientCategory__c = 'Gold';
      donor.FinServ__NetWorth__c = 5000000;
      // donor.FinServ__AnnualIncome__c = 500000; // Not available in this org
      donor.FinServ__Status__c = 'Closed';
      donor.FinServ__InvestmentObjectives__c = 'Conservative Income;Income';
      donor.FinServ__RiskTolerance__c = 'Conservative';

      donor.DAF_Accounts__c = 1;
      // donor.SC_Premier_Service_DST__c = false; // Read-only field
      // donor.Schwab_Chairman_s_Circle_SCC__c = false; // Read-only field

      logBuilder(
        'DeceasedDonorBuilder',
        'Initialized defaults',
        new Map<String, Object>{ 'fields' => donor.getPopulatedFieldsAsMap() }
      );
    }

    public DeceasedDonorBuilder withName(String firstName, String lastName) {
      donor.FirstName = firstName;
      donor.LastName = lastName;
      donor.PersonEmail =
        firstName.toLowerCase() +
        '.' +
        lastName.toLowerCase() +
        '@legacy-estate.example.com';
      logBuilder(
        'DeceasedDonorBuilder',
        'withName',
        new Map<String, Object>{
          'firstName' => firstName,
          'lastName' => lastName
        }
      );
      return this;
    }

    public DeceasedDonorBuilder withNetWorth(Decimal netWorth) {
      donor.FinServ__NetWorth__c = netWorth;
      logBuilder(
        'DeceasedDonorBuilder',
        'withNetWorth',
        new Map<String, Object>{ 'netWorth' => netWorth }
      );
      return this;
    }

    public DeceasedDonorBuilder withDateOfDeath(Date deathDate) {
      donor.Date_of_Death__c = deathDate;
      logBuilder(
        'DeceasedDonorBuilder',
        'withDateOfDeath',
        new Map<String, Object>{ 'deathDate' => deathDate }
      );
      return this;
    }

    public DeceasedDonorBuilder withAddress(String city, String state) {
      donor.PersonMailingCity = city;
      donor.PersonMailingState = state;
      logBuilder(
        'DeceasedDonorBuilder',
        'withAddress',
        new Map<String, Object>{ 'city' => city, 'state' => state }
      );
      return this;
    }

    public DeceasedDonorBuilder asPremierDonor() {
      donor.FinServ__ClientCategory__c = 'Platinum';
      // Set Self_Qualified_Premier__c to drive SC_Premier_Service_DST__c formula
      donor.Self_Qualified_Premier__c = true;
      logBuilder(
        'DeceasedDonorBuilder',
        'asPremierDonor',
        new Map<String, Object>{ 'Self_Qualified_Premier__c' => true }
      );
      return this;
    }

    public Account build() {
      return donor;
    }

    public Account buildAndInsert() {
      Account built = build();
      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('DeceasedDonorBuilder', built, dml);
      return built;
    }
  }

  // ==================== BUILDER: LIVING SUCCESSOR ====================

  /**
   * @description Builder for Person Account (Living Successor)
   */
  public class SuccessorBuilder {
    private Account successor;

    public SuccessorBuilder() {
      successor = new Account();

      // Set PersonAccount record type (required for Person Accounts)
      if (personAccountRecordTypeId != null) {
        successor.RecordTypeId = personAccountRecordTypeId;
      }

      // Default values per Section 4.2 of test-data-plan
      successor.FirstName = 'Jane';
      successor.LastName = 'Successor' + accountCounter++;
      successor.Salutation = 'Ms.';
      successor.PersonBirthdate = Date.newInstance(1975, 3, 20);
      successor.Type = ACCOUNT_TYPE_PROSPECT;
      successor.Deceased__c = false;

      successor.PersonEmail =
        successor.FirstName.toLowerCase() +
        '.' +
        successor.LastName.toLowerCase() +
        '@email.example.com';
      successor.PersonMobilePhone =
        '(555) 100-' +
        String.valueOf(Math.round(Math.random() * 9999)).leftPad(4, '0');

      successor.PersonMailingStreet = '456 Successor Ave';
      successor.PersonMailingCity = 'Los Angeles';
      successor.PersonMailingState = 'CA';
      successor.PersonMailingPostalCode = '90001';
      successor.PersonMailingCountry = 'United States';

      // successor.FinServ__CurrentEmployer__c = 'Tech Corp'; // Not available in this org
      // successor.FinServ__Occupation__c = 'Software Engineer'; // Not available in this org
      // successor.FinServ__MaritalStatus__c = 'Married'; // Not available in this org
      // successor.FinServ__NumberOfChildren__c = 2; // Not available in this org
      successor.FinServ__ClientCategory__c = 'Silver';
      successor.Area_of_Interest__c = 'Family Philanthropy / Legacy Planning';

      logBuilder(
        'SuccessorBuilder',
        'Initialized defaults',
        new Map<String, Object>{
          'fields' => successor.getPopulatedFieldsAsMap()
        }
      );
    }

    public SuccessorBuilder withName(String firstName, String lastName) {
      successor.FirstName = firstName;
      successor.LastName = lastName;
      successor.PersonEmail =
        firstName.toLowerCase() +
        '.' +
        lastName.toLowerCase() +
        '@email.example.com';
      logBuilder(
        'SuccessorBuilder',
        'withName',
        new Map<String, Object>{
          'firstName' => firstName,
          'lastName' => lastName
        }
      );
      return this;
    }

    public SuccessorBuilder withEmail(String email) {
      successor.PersonEmail = email;
      logBuilder(
        'SuccessorBuilder',
        'withEmail',
        new Map<String, Object>{ 'email' => email }
      );
      return this;
    }

    public SuccessorBuilder withPhone(String phone) {
      successor.PersonMobilePhone = phone;
      logBuilder(
        'SuccessorBuilder',
        'withPhone',
        new Map<String, Object>{ 'phone' => phone }
      );
      return this;
    }

    public SuccessorBuilder withAddress(String city, String state) {
      successor.PersonMailingCity = city;
      successor.PersonMailingState = state;
      logBuilder(
        'SuccessorBuilder',
        'withAddress',
        new Map<String, Object>{ 'city' => city, 'state' => state }
      );
      return this;
    }

    public SuccessorBuilder asResponsive() {
      successor.PersonHasOptedOutOfEmail = false;
      successor.PersonDoNotCall = false;
      logBuilder('SuccessorBuilder', 'asResponsive', null);
      return this;
    }

    public SuccessorBuilder asUnresponsive() {
      successor.PersonEmail = null;
      successor.PersonMobilePhone = null;
      logBuilder('SuccessorBuilder', 'asUnresponsive', null);
      return this;
    }

    public Account build() {
      return successor;
    }

    public Account buildAndInsert() {
      Account built = build();
      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('SuccessorBuilder', built, dml);
      return built;
    }
  }

  // ==================== BUILDER: ADVISOR FIRM ====================

  /**
   * @description Builder for Business Account (Advisor Firm)
   */
  public class AdvisorFirmBuilder {
    private Account firm;

    public AdvisorFirmBuilder() {
      firm = new Account();

      // Set Business record type (required for Business Accounts)
      if (businessAccountRecordTypeId != null) {
        firm.RecordTypeId = businessAccountRecordTypeId;
      }

      firm.Name = 'Advisor Firm ' + accountCounter++;
      firm.Type = ACCOUNT_TYPE_ADVISOR;
      firm.Phone =
        '(555) 200-' +
        String.valueOf(Math.round(Math.random() * 9999)).leftPad(4, '0');

      firm.BillingStreet = '789 Financial Plaza';
      firm.BillingCity = 'New York';
      firm.BillingState = 'NY';
      firm.BillingPostalCode = '10001';
      firm.BillingCountry = 'United States';

      firm.AS_Segment__c = 'Star';
      firm.AS_Region__c = 'NY METRO';
      firm.FinServ__Status__c = 'Active';

      logBuilder(
        'AdvisorFirmBuilder',
        'Initialized defaults',
        new Map<String, Object>{ 'fields' => firm.getPopulatedFieldsAsMap() }
      );
    }

    public AdvisorFirmBuilder withName(String name) {
      firm.Name = name;
      logBuilder(
        'AdvisorFirmBuilder',
        'withName',
        new Map<String, Object>{ 'name' => name }
      );
      return this;
    }

    public AdvisorFirmBuilder withRegion(String region) {
      firm.AS_Region__c = region;
      logBuilder(
        'AdvisorFirmBuilder',
        'withRegion',
        new Map<String, Object>{ 'region' => region }
      );
      return this;
    }

    public AdvisorFirmBuilder withSegment(String segment) {
      firm.AS_Segment__c = segment;
      logBuilder(
        'AdvisorFirmBuilder',
        'withSegment',
        new Map<String, Object>{ 'segment' => segment }
      );
      return this;
    }

    public Account build() {
      return firm;
    }

    public Account buildAndInsert() {
      Account built = build();
      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('AdvisorFirmBuilder', built, dml);
      return built;
    }
  }

  // ==================== BUILDER: FINANCIAL ACCOUNT ====================

  /**
   * @description Builder for Financial Account (DAF)
   */
  public class FinancialAccountBuilder {
    private FinServ__FinancialAccount__c dafAccount;

    public FinancialAccountBuilder(Id primaryOwnerId) {
      dafAccount = new FinServ__FinancialAccount__c();

      // Default values per Section 4.3 of test-data-plan
      dafAccount.Name = 'Family Fund ' + accountCounter;
      dafAccount.FinServ__FinancialAccountNumber__c =
        'DAF-' +
        String.valueOf(10000000 + Math.round(Math.random() * 89999999));
      dafAccount.FinServ__FinancialAccountType__c = FA_TYPE_DAF;
      dafAccount.Program__c = 'ASDAF';
      dafAccount.FinServ__Status__c = FA_STATUS_ACTIVE;

      dafAccount.FinServ__Balance__c = 500000;
      dafAccount.Balance_As_Of__c = Date.today().addDays(-2);

      dafAccount.FinServ__OpenDate__c = Date.today().addYears(-5);
      dafAccount.First_Contribution_Date__c = dafAccount.FinServ__OpenDate__c;
      dafAccount.Most_Recent_Grant_Date__c = Date.today().addDays(-90);

      // dafAccount.Lifetime_Contribution__c = 750000; // Read-only field
      // dafAccount.Total_Granted_Lifetime__c = 250000; // Read-only field

      // dafAccount.FYTD_New_Contribution__c = 25000; // Read-only field
      // dafAccount.FYTD_Recontribution__c = 5000; // Read-only field
      // dafAccount.Total_Granted_FYTD__c = 15000; // Read-only field

      // Distribute grants by category
      dafAccount.Arts_Culture_Humanities_Lifetime__c = 50000;
      dafAccount.Education_Lifetime__c = 75000;
      dafAccount.Health_Lifetime__c = 37500;
      dafAccount.Human_Services_Lifetime__c = 50000;
      dafAccount.Religion_Related_Lifetime__c = 25000;
      dafAccount.Environmental_and_Animals_Lifetime__c = 12500;

      dafAccount.FinServ__PrimaryOwner__c = primaryOwnerId;
      dafAccount.FinServ__Ownership__c = 'Individual';
      // Workaround for validation rule bug: explicitly set JointOwner to null
      // to avoid null = null comparison issue in PrimaryAndJointOwnerCannotBeSame validation
      dafAccount.FinServ__JointOwner__c = null;
      // dafAccount.SC_Premier_Service_DST__c = false; // Read-only field
      dafAccount.Separately_Managed_Account__c = false;
      dafAccount.Legacy_Account__c = false;
      dafAccount.Beneficiary_Account__c = false;

      logBuilder(
        'FinancialAccountBuilder',
        'Initialized defaults',
        new Map<String, Object>{
          'fields' => dafAccount.getPopulatedFieldsAsMap()
        }
      );
    }

    public FinancialAccountBuilder withProgram(String program) {
      dafAccount.Program__c = program;
      if (program == 'PMA') {
        dafAccount.Separately_Managed_Account__c = true;
      }
      logBuilder(
        'FinancialAccountBuilder',
        'withProgram',
        new Map<String, Object>{ 'program' => program }
      );
      return this;
    }

    public FinancialAccountBuilder withBalance(Decimal balance) {
      dafAccount.FinServ__Balance__c = balance;
      // dafAccount.Lifetime_Contribution__c = balance * 2; // Read-only field
      // dafAccount.Total_Granted_Lifetime__c = balance * 0.5; // Read-only field

      // Note: SC_Premier_Service_DST__c is a formula field on FinancialAccount
      // It's driven by the related Advisor's flags (SCF_Premier_Advisor__c, Family_Office__c)
      // which are set via FinAcct_Update_Batch, not directly on the Financial Account
      logBuilder(
        'FinancialAccountBuilder',
        'withBalance',
        new Map<String, Object>{ 'balance' => balance }
      );
      return this;
    }

    public FinancialAccountBuilder withAccountNumber(String accountNum) {
      dafAccount.FinServ__FinancialAccountNumber__c = accountNum;
      logBuilder(
        'FinancialAccountBuilder',
        'withAccountNumber',
        new Map<String, Object>{ 'accountNumber' => accountNum }
      );
      return this;
    }

    public FinancialAccountBuilder asFrozen() {
      dafAccount.FinServ__Status__c = FA_STATUS_FROZEN;
      logBuilder('FinancialAccountBuilder', 'asFrozen', null);
      return this;
    }

    public FinancialAccountBuilder withAdvisor(Id advisorId) {
      dafAccount.Advisor__c = advisorId;
      logBuilder(
        'FinancialAccountBuilder',
        'withAdvisor',
        new Map<String, Object>{ 'advisorId' => advisorId }
      );
      return this;
    }

    public FinancialAccountBuilder withName(String name) {
      dafAccount.Name = name;
      logBuilder(
        'FinancialAccountBuilder',
        'withName',
        new Map<String, Object>{ 'name' => name }
      );
      return this;
    }

    public FinServ__FinancialAccount__c build() {
      return dafAccount;
    }

    public FinServ__FinancialAccount__c buildAndInsert() {
      FinServ__FinancialAccount__c built = build();
      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('FinancialAccountBuilder', built, dml);
      return built;
    }
  }

  // ==================== BUILDER: FINANCIAL ACCOUNT ROLE ====================

  /**
   * @description Builder for FinancialAccountRole
   */
  public class FinancialAccountRoleBuilder {
    private FinServ__FinancialAccountRole__c role;

    public FinancialAccountRoleBuilder(Id financialAccountId) {
      role = new FinServ__FinancialAccountRole__c();

      role.FinServ__FinancialAccount__c = financialAccountId;
      role.FinServ__Active__c = true;
      role.FinServ__StartDate__c = Date.today().addYears(-5);

      logBuilder(
        'FinancialAccountRoleBuilder',
        'Initialized defaults',
        new Map<String, Object>{ 'fields' => role.getPopulatedFieldsAsMap() }
      );
    }

    public FinancialAccountRoleBuilder asSuccessor(Id successorId) {
      role.FinServ__RelatedAccount__c = successorId;
      role.FinServ__Role__c = ROLE_SUCCESSOR;
      role.SuccessorAllocation__c = 100;
      logBuilder(
        'FinancialAccountRoleBuilder',
        'asSuccessor',
        new Map<String, Object>{ 'successorId' => successorId }
      );
      return this;
    }

    public FinancialAccountRoleBuilder asAdvisor(Id advisorId) {
      role.FinServ__RelatedAccount__c = advisorId;
      role.FinServ__Role__c = ROLE_ADVISOR;
      logBuilder(
        'FinancialAccountRoleBuilder',
        'asAdvisor',
        new Map<String, Object>{ 'advisorId' => advisorId }
      );
      return this;
    }

    public FinancialAccountRoleBuilder asPrimaryOwner(Id ownerId) {
      role.FinServ__RelatedAccount__c = ownerId;
      role.FinServ__Role__c = ROLE_PRIMARY_OWNER;
      logBuilder(
        'FinancialAccountRoleBuilder',
        'asPrimaryOwner',
        new Map<String, Object>{ 'ownerId' => ownerId }
      );
      return this;
    }

    public FinancialAccountRoleBuilder withAllocation(Decimal percentage) {
      role.SuccessorAllocation__c = percentage;
      logBuilder(
        'FinancialAccountRoleBuilder',
        'withAllocation',
        new Map<String, Object>{ 'allocation' => percentage }
      );
      return this;
    }

    public FinServ__FinancialAccountRole__c build() {
      return role;
    }

    public FinServ__FinancialAccountRole__c buildAndInsert() {
      FinServ__FinancialAccountRole__c built = build();
      System.assertNotEquals(
        null,
        built.FinServ__FinancialAccount__c,
        'FinancialAccountRole requires FinServ__FinancialAccount__c'
      );
      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('FinancialAccountRoleBuilder', built, dml);
      return built;
    }
  }

  // ==================== BUILDER: SUCCESSION CASE ====================

  /**
   * @description Builder for Succession Case
   */
  public class SuccessionCaseBuilder {
    private Case successionCase;
    private Boolean closedRequested = false;

    public SuccessionCaseBuilder(Id deceasedDonorId, Id financialAccountId) {
      successionCase = new Case();

      // Default values per Section 4.5 of test-data-plan
      successionCase.Type = CASE_TYPE_SUCCESSION;
      successionCase.Subject = 'Succession - Case ' + caseCounter++;
      successionCase.Status = CASE_STATUS_IN_PROGRESS;
      successionCase.Priority = 'Medium';
      successionCase.Origin = 'Phone';

      successionCase.AccountId = deceasedDonorId;
      successionCase.FinServ__FinancialAccount__c = financialAccountId;
      successionCase.Deceased_Donor__c = deceasedDonorId;

      successionCase.Verification_Status__c = 'Complete - Verified';
      successionCase.Contact_Attempt_Count__c = 1;
      successionCase.Contact_Established__c = false;
      successionCase.Pathway_Confirmed__c = 'Not Selected';

      // Set default Next Contact Due to satisfy validation when attempts remain and contact not established
      // BRD cadence suggests Day 5 after initial attempt
      successionCase.Next_Contact_Due__c = Date.today().addDays(5);

      successionCase.Notification_Source__c = 'Financial Advisor';

      successionCase.Description = 'Succession case created for test data generation.';

      logBuilder(
        'SuccessionCaseBuilder',
        'Initialized defaults',
        new Map<String, Object>{
          'fields' => successionCase.getPopulatedFieldsAsMap()
        }
      );
    }

    public SuccessionCaseBuilder withSuccessor(Id successorContactId) {
      successionCase.ContactId = successorContactId;
      logBuilder(
        'SuccessionCaseBuilder',
        'withSuccessor',
        new Map<String, Object>{ 'contactId' => successorContactId }
      );
      return this;
    }

    public SuccessionCaseBuilder withContactAttempts(Integer attempts) {
      successionCase.Contact_Attempt_Count__c = attempts;

      // Set Next_Contact_Due based on attempts
      if (attempts == 0) {
        successionCase.Next_Contact_Due__c = Date.today();
      } else if (attempts == 1) {
        successionCase.Next_Contact_Due__c = Date.today().addDays(5);
      } else if (attempts == 2) {
        successionCase.Next_Contact_Due__c = Date.today().addDays(35);
      } else if (attempts == 3) {
        successionCase.Next_Contact_Due__c = Date.today().addDays(65);
      } else {
        successionCase.Next_Contact_Due__c = Date.today().addDays(95);
      }

      if (attempts > 0) {
        successionCase.Last_Contact_Attempt__c = DateTime.now().addDays(-5);
      }

      logBuilder(
        'SuccessionCaseBuilder',
        'withContactAttempts',
        new Map<String, Object>{ 'attempts' => attempts }
      );
      return this;
    }

    public SuccessionCaseBuilder withContactEstablished() {
      successionCase.Contact_Established__c = true;
      successionCase.Contact_Established_Date__c = DateTime.now().addDays(-7);
      successionCase.Form_Sent_Date__c = DateTime.now().addDays(-5);
      logBuilder('SuccessionCaseBuilder', 'withContactEstablished', null);
      return this;
    }

    public SuccessionCaseBuilder withPathway(String pathway) {
      successionCase.Pathway_Confirmed__c = pathway;
      logBuilder(
        'SuccessionCaseBuilder',
        'withPathway',
        new Map<String, Object>{ 'pathway' => pathway }
      );
      return this;
    }

    public SuccessionCaseBuilder withVerificationStatus(String status) {
      successionCase.Verification_Status__c = status;
      logBuilder(
        'SuccessionCaseBuilder',
        'withVerificationStatus',
        new Map<String, Object>{ 'status' => status }
      );
      return this;
    }

    public SuccessionCaseBuilder asEscalated() {
      successionCase.IsEscalated = true;
      successionCase.Contact_Attempt_Count__c = 4;
      successionCase.Contact_Established__c = false;
      logBuilder('SuccessionCaseBuilder', 'asEscalated', null);
      return this;
    }

    public SuccessionCaseBuilder asClosed() {
      successionCase.Status = CASE_STATUS_CLOSED;
      // Defer ClosedDate assignment to post-insert to ensure it is after CreatedDate
      closedRequested = true;
      logBuilder('SuccessionCaseBuilder', 'asClosed', null);
      return this;
    }

    public SuccessionCaseBuilder withFormCompleted() {
      successionCase.Form_Completed_Date__c = DateTime.now().addDays(-3);
      logBuilder('SuccessionCaseBuilder', 'withFormCompleted', null);
      return this;
    }

    public SuccessionCaseBuilder withEstateAdministrationRecordType() {
      // Query for EstateAdministration record type (012Dg000000B0plIAC in schwab-sandbox)
      List<RecordType> recordTypes = [
        SELECT Id
        FROM RecordType
        WHERE
          SobjectType = 'Case'
          AND DeveloperName = 'EstateAdministration'
          AND IsActive = TRUE
        LIMIT 1
      ];
      if (!recordTypes.isEmpty()) {
        successionCase.RecordTypeId = recordTypes[0].Id;
      }
      logBuilder(
        'SuccessionCaseBuilder',
        'withEstateAdministrationRecordType',
        new Map<String, Object>{ 'recordTypeId' => successionCase.RecordTypeId }
      );
      return this;
    }

    public Case build() {
      return successionCase;
    }

    public Case buildAndInsert() {
      Case built = build();
      // Ensure Next_Contact_Due__c is present when required by validation
      if (
        built.Contact_Established__c != true &&
        built.Contact_Attempt_Count__c != null &&
        built.Contact_Attempt_Count__c < 5 &&
        built.Next_Contact_Due__c == null
      ) {
        built.Next_Contact_Due__c = Date.today().addDays(5);
      }

      // In test context, temporarily set Verification_Status to avoid triggering the Contact Cadence flow
      // Flow entry criteria: RecordType = EstateAdministration AND Type = Named Successor Enactment AND Verification_Status = "Complete - Verified"
      String originalVerificationStatus = built.Verification_Status__c;
      if (Test.isRunningTest()) {
        built.Verification_Status__c = 'Pending Verification';
      }

      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('SuccessionCaseBuilder', built, dml);

      // Restore verification status after insert to avoid flow trigger
      if (Test.isRunningTest() && originalVerificationStatus != null) {
        built.Verification_Status__c = originalVerificationStatus;
        updateWithLogging('SuccessionCaseBuilder.RestoreVerification', built);
      }

      // If a closed status was requested, set ClosedDate to after CreatedDate
      if (closedRequested == true && built.Status == CASE_STATUS_CLOSED) {
        built.ClosedDate = Datetime.now().addMinutes(2);
        updateWithLogging('SuccessionCaseBuilder.Close', built);
      }
      return built;
    }
  }

  // ==================== BUILDER: TASK (ACTIVITY) ====================

  /**
   * @description Builder for Task (contact attempts, follow-ups, emails)
   * Supports succession-specific fields and contact cadence workflow
   */
  public class TaskBuilder {
    private Task taskRecord;
    // Note: clientAssociateTaskRecordTypeId moved to top-level static variable

    public TaskBuilder(Id caseId, Id contactId) {
      taskRecord = new Task();

      // Set record type if available
      if (clientAssociateTaskRecordTypeId != null) {
        taskRecord.RecordTypeId = clientAssociateTaskRecordTypeId;
      }

      // Link to Case and Contact
      taskRecord.WhatId = caseId;
      taskRecord.WhoId = contactId;

      // Default values
      taskRecord.Subject = 'Succession Contact Attempt';
      taskRecord.Status = 'Completed';
      taskRecord.Priority = 'Normal';
      taskRecord.Type = 'Call';
      taskRecord.TaskSubtype = 'Call';
      taskRecord.ActivityDate = Date.today();

      // Succession-specific defaults
      taskRecord.Contact_Attempt_Number__c = 1;
      taskRecord.Succession_Contact_Established__c = false;

      logBuilder(
        'TaskBuilder',
        'Initialized defaults',
        new Map<String, Object>{
          'fields' => taskRecord.getPopulatedFieldsAsMap()
        }
      );
    }

    public TaskBuilder withSubject(String subject) {
      taskRecord.Subject = subject;
      logBuilder(
        'TaskBuilder',
        'withSubject',
        new Map<String, Object>{ 'subject' => subject }
      );
      return this;
    }

    public TaskBuilder withType(String taskType) {
      taskRecord.Type = taskType; // Call, Meeting, Other
      logBuilder(
        'TaskBuilder',
        'withType',
        new Map<String, Object>{ 'type' => taskType }
      );
      return this;
    }

    public TaskBuilder withTaskSubtype(String subtype) {
      taskRecord.TaskSubtype = subtype; // Task, Email, Call, LinkedIn
      logBuilder(
        'TaskBuilder',
        'withTaskSubtype',
        new Map<String, Object>{ 'subtype' => subtype }
      );
      return this;
    }

    public TaskBuilder withStatus(String status) {
      taskRecord.Status = status; // Open, In Progress, Completed, Cancelled
      logBuilder(
        'TaskBuilder',
        'withStatus',
        new Map<String, Object>{ 'status' => status }
      );
      return this;
    }

    public TaskBuilder withPriority(String priority) {
      taskRecord.Priority = priority; // High, Normal
      logBuilder(
        'TaskBuilder',
        'withPriority',
        new Map<String, Object>{ 'priority' => priority }
      );
      return this;
    }

    public TaskBuilder withActivityDate(Date activityDate) {
      taskRecord.ActivityDate = activityDate;
      logBuilder(
        'TaskBuilder',
        'withActivityDate',
        new Map<String, Object>{ 'date' => activityDate }
      );
      return this;
    }

    public TaskBuilder withContactAttemptNumber(Integer attemptNumber) {
      taskRecord.Contact_Attempt_Number__c = attemptNumber;
      logBuilder(
        'TaskBuilder',
        'withContactAttemptNumber',
        new Map<String, Object>{ 'attempt' => attemptNumber }
      );
      return this;
    }

    public TaskBuilder withContactEstablished(Boolean established) {
      taskRecord.Succession_Contact_Established__c = established;
      logBuilder(
        'TaskBuilder',
        'withContactEstablished',
        new Map<String, Object>{ 'established' => established }
      );
      return this;
    }

    public TaskBuilder withCallType(String callType) {
      taskRecord.CallType = callType; // Internal, Inbound, Outbound
      logBuilder(
        'TaskBuilder',
        'withCallType',
        new Map<String, Object>{ 'callType' => callType }
      );
      return this;
    }

    public TaskBuilder withCallDisposition(String disposition) {
      taskRecord.CallDisposition = disposition;
      logBuilder(
        'TaskBuilder',
        'withCallDisposition',
        new Map<String, Object>{ 'disposition' => disposition }
      );
      return this;
    }

    public TaskBuilder withCallDuration(Integer seconds) {
      taskRecord.CallDurationInSeconds = seconds;
      logBuilder(
        'TaskBuilder',
        'withCallDuration',
        new Map<String, Object>{ 'seconds' => seconds }
      );
      return this;
    }

    public TaskBuilder withDescription(String description) {
      taskRecord.Description = description;
      logBuilder(
        'TaskBuilder',
        'withDescription',
        new Map<String, Object>{ 'description' => description }
      );
      return this;
    }

    public TaskBuilder asCall() {
      taskRecord.Type = 'Call';
      taskRecord.TaskSubtype = 'Call';
      taskRecord.CallType = 'Outbound';
      logBuilder('TaskBuilder', 'asCall', null);
      return this;
    }

    public TaskBuilder asEmail() {
      taskRecord.Type = 'Call'; // Email task type is "Call" with TaskSubtype = "Email"
      taskRecord.TaskSubtype = 'Email';
      taskRecord.CallType = null;
      logBuilder('TaskBuilder', 'asEmail', null);
      return this;
    }

    public TaskBuilder asMeeting() {
      taskRecord.Type = 'Meeting';
      taskRecord.TaskSubtype = 'Task';
      logBuilder('TaskBuilder', 'asMeeting', null);
      return this;
    }

    public Task build() {
      return taskRecord;
    }

    public Task buildAndInsert() {
      Task built = build();
      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('TaskBuilder', built, dml);
      return built;
    }
  }

  // ==================== BUILDER: EVENT ====================

  /**
   * @description Builder for Event (meetings, appointments)
   * Supports succession planning meetings and consultation events
   */
  public class EventBuilder {
    private Event eventRecord;
    // Note: clientAssociateEventRecordTypeId moved to top-level static variable

    public EventBuilder(Id relatedToId, Id contactId) {
      eventRecord = new Event();

      // Set record type if available
      if (clientAssociateEventRecordTypeId != null) {
        eventRecord.RecordTypeId = clientAssociateEventRecordTypeId;
      }

      // Link to related record (Case/Account) and Contact
      eventRecord.WhatId = relatedToId;
      eventRecord.WhoId = contactId;

      // Default values - 1 hour meeting starting tomorrow at 10 AM
      Date tomorrow = Date.today().addDays(1);
      DateTime startTime = DateTime.newInstance(
        tomorrow.year(),
        tomorrow.month(),
        tomorrow.day(),
        10,
        0,
        0
      );
      eventRecord.Subject = 'Succession Planning Meeting';
      eventRecord.StartDateTime = startTime;
      eventRecord.EndDateTime = startTime.addHours(1);
      eventRecord.DurationInMinutes = 60;
      eventRecord.Location = 'Virtual - Zoom';
      eventRecord.Type = 'Meeting, Client';
      eventRecord.ShowAs = 'Busy';

      logBuilder(
        'EventBuilder',
        'Initialized defaults',
        new Map<String, Object>{
          'fields' => eventRecord.getPopulatedFieldsAsMap()
        }
      );
    }

    public EventBuilder withSubject(String subject) {
      eventRecord.Subject = subject;
      logBuilder(
        'EventBuilder',
        'withSubject',
        new Map<String, Object>{ 'subject' => subject }
      );
      return this;
    }

    public EventBuilder withStartDateTime(DateTime startTime) {
      eventRecord.StartDateTime = startTime;
      // Update end time to maintain duration
      Integer duration = eventRecord.DurationInMinutes != null
        ? eventRecord.DurationInMinutes
        : 60;
      eventRecord.EndDateTime = startTime.addMinutes(duration);
      logBuilder(
        'EventBuilder',
        'withStartDateTime',
        new Map<String, Object>{
          'start' => startTime,
          'durationMinutes' => duration
        }
      );
      return this;
    }

    public EventBuilder withDuration(Integer minutes) {
      eventRecord.DurationInMinutes = minutes;
      if (eventRecord.StartDateTime != null) {
        eventRecord.EndDateTime = eventRecord.StartDateTime.addMinutes(minutes);
      }
      logBuilder(
        'EventBuilder',
        'withDuration',
        new Map<String, Object>{ 'minutes' => minutes }
      );
      return this;
    }

    public EventBuilder withLocation(String location) {
      eventRecord.Location = location;
      logBuilder(
        'EventBuilder',
        'withLocation',
        new Map<String, Object>{ 'location' => location }
      );
      return this;
    }

    public EventBuilder withType(String eventType) {
      eventRecord.Type = eventType;
      logBuilder(
        'EventBuilder',
        'withType',
        new Map<String, Object>{ 'type' => eventType }
      );
      return this;
    }

    public EventBuilder withDescription(String description) {
      eventRecord.Description = description;
      logBuilder(
        'EventBuilder',
        'withDescription',
        new Map<String, Object>{ 'description' => description }
      );
      return this;
    }

    public EventBuilder asVirtualMeeting() {
      eventRecord.Location = 'Virtual - Zoom';
      eventRecord.Type = 'Meeting, Client';
      logBuilder('EventBuilder', 'asVirtualMeeting', null);
      return this;
    }

    public EventBuilder asInPersonMeeting(String officeLocation) {
      eventRecord.Location = officeLocation;
      eventRecord.Type = 'Meeting, Client';
      logBuilder(
        'EventBuilder',
        'asInPersonMeeting',
        new Map<String, Object>{ 'location' => officeLocation }
      );
      return this;
    }

    public EventBuilder asConference() {
      eventRecord.Type = 'Conference, Event';
      logBuilder('EventBuilder', 'asConference', null);
      return this;
    }

    public Event build() {
      return eventRecord;
    }

    public Event buildAndInsert() {
      Event built = build();
      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('EventBuilder', built, dml);
      return built;
    }
  }

  // ==================== BUILDER: CHATTER POST ====================

  /**
   * @description Builder for Chatter FeedItem (posts on records)
   * Supports succession-specific posts and internal team collaboration
   */
  public class ChatterPostBuilder {
    private FeedItem post;

    public ChatterPostBuilder(Id parentId) {
      post = new FeedItem();
      post.ParentId = parentId;
      post.Type = 'TextPost';
      post.Visibility = 'InternalUsers';

      logBuilder(
        'ChatterPostBuilder',
        'Initialized defaults',
        new Map<String, Object>{ 'parentId' => parentId }
      );
    }

    public ChatterPostBuilder withBody(String body) {
      post.Body = body;
      logBuilder(
        'ChatterPostBuilder',
        'withBody',
        new Map<String, Object>{ 'body' => body }
      );
      return this;
    }

    public ChatterPostBuilder withCreatedDate(DateTime createdDate) {
      // Note: CreatedDate is auto-set, but we track for sequencing
      return this;
    }

    public FeedItem build() {
      return post;
    }

    public FeedItem buildAndInsert() {
      FeedItem built = build();
      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('ChatterPostBuilder', built, dml);
      return built;
    }
  }

  /**
   * @description Builder for Chatter FeedComment (replies to posts)
   */
  public class ChatterCommentBuilder {
    private FeedComment comment;

    public ChatterCommentBuilder(Id feedItemId) {
      comment = new FeedComment();
      comment.FeedItemId = feedItemId;
      comment.CommentType = 'TextComment';

      logBuilder(
        'ChatterCommentBuilder',
        'Initialized defaults',
        new Map<String, Object>{ 'feedItemId' => feedItemId }
      );
    }

    public ChatterCommentBuilder withBody(String body) {
      comment.CommentBody = body;
      logBuilder(
        'ChatterCommentBuilder',
        'withBody',
        new Map<String, Object>{ 'body' => body }
      );
      return this;
    }

    public FeedComment build() {
      return comment;
    }

    public FeedComment buildAndInsert() {
      FeedComment built = build();
      Database.DMLOptions dml = getDmlOptions();
      insertWithLogging('ChatterCommentBuilder', built, dml);
      return built;
    }
  }

  // ==================== HELPER: GENERATE CHATTER FEED ====================

  /**
   * @description Generate Chatter feed posts and comments for succession cases
   * @param caseId The succession case ID
   * @param accountId The deceased donor account ID
   * @param pathway The succession pathway (Final Grant, New DAF, Disclaim)
   * @param contactEstablished Whether contact was successfully established
   * @param isEscalated Whether the case was escalated
   * @return List of FeedItem records (inserted with comments)
   */
  private static List<FeedItem> generateChatterFeed(
    Id caseId,
    Id accountId,
    String pathway,
    Boolean contactEstablished,
    Boolean isEscalated
  ) {
    List<FeedItem> posts = new List<FeedItem>();

    // Post 1: Case opened (on Account)
    FeedItem accountPost = new ChatterPostBuilder(accountId)
      .withBody(
        'New succession case opened. Reviewing deceased donor documentation and preparing for successor outreach. Case assigned to Estates team.'
      )
      .buildAndInsert();
    posts.add(accountPost);

    // Post 2: Initial contact update (on Case)
    String contactUpdate;
    if (contactEstablished) {
      contactUpdate = 'Contact established with successor. Succession election form sent. Successor is responsive and engaged.';
    } else {
      contactUpdate = 'Initial contact attempts in progress. Left voicemail and sent follow-up email with succession information.';
    }

    FeedItem casePost1 = new ChatterPostBuilder(caseId)
      .withBody(contactUpdate)
      .buildAndInsert();
    posts.add(casePost1);

    // Add comment to case post
    new ChatterCommentBuilder(casePost1.Id)
      .withBody('Thanks for the update. Please keep me posted on timeline.')
      .buildAndInsert();

    // Post 3: Pathway confirmation (on Case)
    if (contactEstablished) {
      String pathwayUpdate = 'Succession pathway confirmed: ' + pathway + '. ';
      if (pathway == 'Final Grant') {
        pathwayUpdate += 'Processing final grant to designated charity. Account will be closed upon completion.';
      } else if (pathway == 'New DAF Account') {
        pathwayUpdate += 'Successor wishes to establish new DAF account. Coordinating with onboarding team.';
      } else if (pathway == 'Disclaim Assets') {
        pathwayUpdate += 'Successor disclaiming assets. Reviewing contingent beneficiary documentation.';
      }

      FeedItem casePost2 = new ChatterPostBuilder(caseId)
        .withBody(pathwayUpdate)
        .buildAndInsert();
      posts.add(casePost2);

      // Add comment
      new ChatterCommentBuilder(casePost2.Id)
        .withBody(
          'Great work on getting pathway confirmation. What\'s the expected timeline for completion?'
        )
        .buildAndInsert();
    }

    // Post 4: Escalation (if applicable)
    if (isEscalated) {
      FeedItem escalationPost = new ChatterPostBuilder(caseId)
        .withBody(
          'Case escalated due to unresponsive successor after multiple contact attempts (4+ attempts). Sent certified mail per SLA policy. Awaiting manager review for next steps.'
        )
        .buildAndInsert();
      posts.add(escalationPost);

      // Manager response
      new ChatterCommentBuilder(escalationPost.Id)
        .withBody(
          'Thanks for escalating. Let\'s give it 2 more weeks then consult with legal on alternative contact methods.'
        )
        .buildAndInsert();
    }

    return posts;
  }

  // ==================== HELPER: GENERATE CONTACT ATTEMPT TASKS ====================

  /**
   * @description Generate contact attempt tasks based on attempt count and outcome
   * @param caseId The succession case ID
   * @param contactId The successor PersonContactId
   * @param attemptCount Number of contact attempts (1-4)
   * @param contactEstablished Whether contact was successfully established
   * @return List of Task records (not inserted)
   */
  private static List<Task> generateContactAttemptTasks(
    Id caseId,
    Id contactId,
    Integer attemptCount,
    Boolean contactEstablished
  ) {
    List<Task> tasks = new List<Task>();

    for (Integer i = 1; i <= attemptCount; i++) {
      Task task;

      if (i == 1) {
        // First attempt - always a call
        task = new TaskBuilder(caseId, contactId)
          .withSubject('Contact Attempt 1 - Initial Outreach')
          .asCall()
          .withContactAttemptNumber(1)
          .withActivityDate(Date.today().addDays(-20))
          .withContactEstablished(contactEstablished && attemptCount == 1)
          .build();
      } else if (i == 2) {
        // Second attempt - email follow-up
        task = new TaskBuilder(caseId, contactId)
          .withSubject('Contact Attempt 2 - Email Follow-up')
          .asEmail()
          .withContactAttemptNumber(2)
          .withActivityDate(Date.today().addDays(-15))
          .withContactEstablished(contactEstablished && attemptCount == 2)
          .withDescription(
            'Follow-up email sent with succession information and next steps.'
          )
          .build();
      } else if (i == 3) {
        // Third attempt - another call
        task = new TaskBuilder(caseId, contactId)
          .withSubject('Contact Attempt 3 - Second Call Attempt')
          .asCall()
          .withContactAttemptNumber(3)
          .withActivityDate(Date.today().addDays(-10))
          .withContactEstablished(contactEstablished && attemptCount == 3)
          .build();
      } else {
        // Fourth+ attempt - final call before escalation
        task = new TaskBuilder(caseId, contactId)
          .withSubject('Contact Attempt ' + i + ' - Final Outreach')
          .asCall()
          .withContactAttemptNumber(i)
          .withActivityDate(Date.today().addDays(-5))
          .withPriority('High')
          .withContactEstablished(contactEstablished && attemptCount == i)
          .withDescription('Escalation pending if no response.')
          .build();
      }

      tasks.add(task);
    }

    // If contact was established, add follow-up tasks
    if (contactEstablished) {
      // Task: Send Succession Election Form
      Task formTask = new TaskBuilder(caseId, contactId)
        .withSubject('Send Succession Election Form')
        .asEmail()
        .withStatus('Completed')
        .withActivityDate(Date.today().addDays(-7))
        .withDescription(
          'Succession election form emailed to successor with instructions.'
        )
        .build();
      tasks.add(formTask);

      // Task: Review Completed Form
      Task reviewTask = new TaskBuilder(caseId, contactId)
        .withSubject('Review Completed Succession Form')
        .withType('Other')
        .withTaskSubtype('Task')
        .withStatus('Completed')
        .withActivityDate(Date.today().addDays(-3))
        .withDescription('Verify form completeness and accuracy.')
        .build();
      tasks.add(reviewTask);
    }

    return tasks;
  }

  // ==================== SCENARIO DATA WRAPPER ====================

  public class ValidationReport {
    public String name;
    public Long durationMs;
    public Map<String, Integer> counts;
    public List<String> warnings;
    public List<String> errors;

    public ValidationReport() {
      counts = new Map<String, Integer>();
      warnings = new List<String>();
      errors = new List<String>();
    }

    public void addCount(String key, Integer value) {
      counts.put(key, value);
    }

    public Boolean hasIssues() {
      return !warnings.isEmpty() || !errors.isEmpty();
    }
  }

  /**
   * @description Wrapper for complete succession scenario data
   */
  public class SuccessionScenarioData {
    public Account deceasedDonor;
    public List<Account> successors;
    public Account advisorFirm;
    public FinServ__FinancialAccount__c financialAccount;
    public List<FinServ__FinancialAccountRole__c> roles;
    public Case successionCase;
    public List<Task> contactTasks;
    public List<Event> meetings;
    public List<FeedItem> chatterPosts;
    public ValidationReport validationReport;

    public SuccessionScenarioData() {
      successors = new List<Account>();
      roles = new List<FinServ__FinancialAccountRole__c>();
      contactTasks = new List<Task>();
      meetings = new List<Event>();
      chatterPosts = new List<FeedItem>();
    }
  }

  /**
   * @description Wrapper for complete test dataset
   */
  public class SuccessionTestData {
    public List<Account> deceasedDonors;
    public List<Account> successors;
    public List<Account> advisorFirms;
    public List<FinServ__FinancialAccount__c> financialAccounts;
    public List<FinServ__FinancialAccountRole__c> roles;
    public List<Case> successionCases;
    public List<Task> contactTasks;
    public List<Event> meetings;
    public List<FeedItem> chatterPosts;
    public List<ValidationReport> validationReports;
    public ValidationReport summaryReport;

    public SuccessionTestData() {
      deceasedDonors = new List<Account>();
      successors = new List<Account>();
      advisorFirms = new List<Account>();
      financialAccounts = new List<FinServ__FinancialAccount__c>();
      roles = new List<FinServ__FinancialAccountRole__c>();
      successionCases = new List<Case>();
      contactTasks = new List<Task>();
      meetings = new List<Event>();
      chatterPosts = new List<FeedItem>();
      validationReports = new List<ValidationReport>();
    }
  }

  // ==================== SCENARIO GENERATORS ====================

  /**
   * @description Generate Happy Path scenario - Final Grant (Section 5.1)
   * Responsive successor, chooses Final Grant pathway, standard 65-day timeline
   */
  public static SuccessionScenarioData generateHappyPathFinalGrant() {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('HappyPathFinalGrant');

    // Create Advisor Firm
    data.advisorFirm = new AdvisorFirmBuilder()
      .withName('Pacific Heritage Group')
      .withRegion('SO. CALIFORNIA')
      .buildAndInsert();

    // Create Deceased Donor
    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName('Margaret', 'Thompson')
      .withNetWorth(5000000)
      .withDateOfDeath(Date.today().addDays(-30))
      .asPremierDonor()
      .buildAndInsert();

    // Create Financial Account
    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName('Thompson Family Fund')
      .withProgram('ASDAF')
      .withBalance(2500000)
      .withAdvisor(data.advisorFirm.Id)
      .buildAndInsert();

    // Create Successor
    Account successor = new SuccessorBuilder()
      .withName('Jennifer', 'Thompson')
      .withEmail('jennifer.thompson@email.example.com')
      .asResponsive()
      .buildAndInsert();
    data.successors.add(successor);

    // Create Roles
    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asSuccessor(successor.Id)
        .withAllocation(100)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asAdvisor(data.advisorFirm.Id)
        .buildAndInsert()
    );

    // Get PersonContactId for successor
    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    // Create Succession Case with Estate Administration record type
    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(1)
      .withContactEstablished()
      .withPathway('Final Grant')
      .withFormCompleted()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Generate Contact Attempt Tasks (1 attempt, contact established)
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      successorWithContact.PersonContactId,
      1,
      true
    );
    insertTaskList('HappyPathFinalGrant.contactTasks', data.contactTasks);

    // Generate Chatter Feed (Account + Case posts with comments)
    data.chatterPosts = generateChatterFeed(
      data.successionCase.Id,
      data.deceasedDonor.Id,
      'Final Grant',
      true, // Contact established
      false // Not escalated
    );
    // TODO: Add calendar events to represent estate review meetings once EventBuilder is fully wired for this scenario.

    ValidationReport validation = buildScenarioValidation(
      'HappyPathFinalGrant',
      data
    );
    Long duration = scenarioEnd(
      'HappyPathFinalGrant',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;
    return data;
  }

  /**
   * @description Generate New DAF Account scenario (Section 5.2)
   * Successor wants to continue philanthropy with new DAF
   */
  public static SuccessionScenarioData generateNewDAFScenario() {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('NewDAFScenario');

    data.advisorFirm = new AdvisorFirmBuilder()
      .withName('Wealthstone Financial Advisors')
      .withRegion('NY METRO')
      .buildAndInsert();

    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName('Robert', 'Chen')
      .withNetWorth(2000000)
      .withDateOfDeath(Date.today().addDays(-45))
      .buildAndInsert();

    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName('Chen Charitable Account')
      .withProgram('ISDAF')
      .withBalance(750000)
      .buildAndInsert();

    Account successor = new SuccessorBuilder()
      .withName('Lisa', 'Chen')
      .withEmail('lisa.chen@email.example.com')
      .asResponsive()
      .buildAndInsert();
    data.successors.add(successor);

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asSuccessor(successor.Id)
        .withAllocation(100)
        .buildAndInsert()
    );

    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(2)
      .withContactEstablished()
      .withPathway('New DAF Account')
      .withFormCompleted()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Generate Contact Attempt Tasks (2 attempts, contact established)
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      successorWithContact.PersonContactId,
      2,
      true
    );
    insertTaskList('NewDAFScenario.contactTasks', data.contactTasks);
    // TODO: Model onboarding tasks for new DAF scenarios (e.g., account opening checklist) using TaskBuilder once workflow steps are finalized.

    ValidationReport validation = buildScenarioValidation(
      'NewDAFScenario',
      data
    );
    Long duration = scenarioEnd(
      'NewDAFScenario',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;

    return data;
  }

  /**
   * @description Generate Disclaim Assets scenario (Section 5.3)
   * Successor disclaims in favor of contingent beneficiary
   */
  public static SuccessionScenarioData generateDisclaimScenario() {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('DisclaimScenario');

    data.advisorFirm = new AdvisorFirmBuilder()
      .withName('Premier Trust Associates')
      .withRegion('FLORIDA')
      .withSegment('Premium')
      .buildAndInsert();

    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName('Elizabeth', 'Martinez')
      .withNetWorth(3000000)
      .withDateOfDeath(Date.today().addDays(-60))
      .asPremierDonor()
      .buildAndInsert();

    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName('Martinez Family Foundation Account')
      .withProgram('ASDAF')
      .withBalance(1200000)
      .buildAndInsert();

    Account successor = new SuccessorBuilder()
      .withName('Carlos', 'Martinez')
      .withEmail('carlos.martinez@email.example.com')
      .asResponsive()
      .buildAndInsert();
    data.successors.add(successor);

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asSuccessor(successor.Id)
        .withAllocation(100)
        .buildAndInsert()
    );

    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(1)
      .withContactEstablished()
      .withPathway('Disclaim Assets')
      .withFormCompleted()
      .asClosed()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Generate Contact Attempt Tasks (1 attempt, contact established)
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      successorWithContact.PersonContactId,
      1,
      true
    );
    insertTaskList('DisclaimScenario.contactTasks', data.contactTasks);
    // TODO: Add contingent beneficiary notifications (tasks + chatter) when pathway = Disclaim Assets to exercise downstream automation.

    ValidationReport validation = buildScenarioValidation(
      'DisclaimScenario',
      data
    );
    Long duration = scenarioEnd(
      'DisclaimScenario',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;

    return data;
  }

  /**
   * @description Generate SLA Escalation scenario (Section 5.4)
   * Unresponsive successor, 4+ contact attempts, escalated
   */
  public static SuccessionScenarioData generateSLAEscalationScenario() {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('SLAEscalationScenario');

    data.advisorFirm = new AdvisorFirmBuilder()
      .withName('Heartland Wealth Management')
      .withRegion('HEARTLAND')
      .buildAndInsert();

    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName('James', 'OConnor')
      .withNetWorth(750000)
      .withDateOfDeath(Date.today().addDays(-70))
      .buildAndInsert();

    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName('OConnor Charitable Fund')
      .withProgram('ASDAF')
      .withBalance(250000)
      .buildAndInsert();

    Account successor = new SuccessorBuilder()
      .withName('Sean', 'OConnor')
      .asUnresponsive()
      .buildAndInsert();
    data.successors.add(successor);

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asSuccessor(successor.Id)
        .withAllocation(100)
        .buildAndInsert()
    );

    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(4)
      .asEscalated()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Generate Contact Attempt Tasks (4 attempts, NO contact established - escalated)
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      successorWithContact.PersonContactId,
      4,
      false // Contact NOT established
    );
    insertTaskList('SLAEscalationScenario.contactTasks', data.contactTasks);
    // TODO: Include certified-mail tracking tasks/events when SLA escalates to align with legal compliance documentation requirements.

    // Generate Chatter Feed (with escalation posts)
    data.chatterPosts = generateChatterFeed(
      data.successionCase.Id,
      data.deceasedDonor.Id,
      'Not Selected', // Pathway not confirmed yet
      false, // Contact NOT established
      true // IS escalated
    );

    ValidationReport validation = buildScenarioValidation(
      'SLAEscalationScenario',
      data
    );
    Long duration = scenarioEnd(
      'SLAEscalationScenario',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;
    return data;
  }

  /**
   * @description Generate Multiple Successors scenario
   * Creates DAF with 2 successors (50/50 split) - Patricia Williams → Amanda & Brandon Williams
   *
   * **IMPORTANT**: This creates only ONE initial Case for the first successor.
   * The Case_Multiple_Successors_Handler Flow automatically:
   * 1. Detects multiple FinancialAccountRoles with Role="Successor"
   * 2. Creates parent "Multi-Account Succession Master" Case
   * 3. Updates current Case to be Child 1 (with ParentId)
   * 4. Creates Child 2 Case for second successor
   * 5. Adds both successors as Case Team Members to parent
   *
   * This demonstrates the "Extend, Don't Create" principle - using standard Case hierarchy
   * and CaseTeamMember instead of creating custom objects.
   *
   * @return SuccessionScenarioData with deceasedDonor, 2 successors, financialAccount, roles, and INITIAL case
   */
  public static SuccessionScenarioData generateMultipleSuccessorsScenario() {
    return generateMultipleSuccessorsScenario(
      'Patricia',
      'Williams',
      new List<String>{ 'Amanda', 'Brandon' },
      new List<String>{ 'Williams', 'Williams' },
      new List<Decimal>{ 50, 50 },
      3500000,
      'ASDAF',
      'Williams Family Foundation Fund'
    );
  }

  /**
   * @description Generate complete test dataset with all scenarios
   * Creates expanded dataset with multiple instances of each scenario type
   *
   * Dataset Size:
   * - 15 deceased donors
   * - 20 living successors (includes co-successors)
   * - 8 advisor firms
   * - 18 financial accounts
   * - 54+ financial account roles
   * - 15 succession cases
   */
  public static SuccessionTestData generateCompleteDataset() {
    SuccessionTestData dataset = new SuccessionTestData();
    Long startMs = scenarioStart('CompleteDataset');

    // ========== SCENARIO 1: Happy Path - Final Grant (5 instances) ==========

    // Instance 1.1: Margaret Thompson (Premier, ASDAF, $2.5M)
    SuccessionScenarioData scenario1 = generateHappyPathFinalGrant();
    dataset.deceasedDonors.add(scenario1.deceasedDonor);
    dataset.successors.addAll(scenario1.successors);
    dataset.advisorFirms.add(scenario1.advisorFirm);
    dataset.financialAccounts.add(scenario1.financialAccount);
    dataset.roles.addAll(scenario1.roles);
    dataset.successionCases.add(scenario1.successionCase);
    dataset.contactTasks.addAll(scenario1.contactTasks);

    // Instance 1.2: Thomas Anderson (Standard, ASDAF, $850K)
    SuccessionScenarioData happyPath2 = generateHappyPathVariant(
      'Thomas',
      'Anderson',
      'Emily',
      'Anderson',
      850000,
      'ASDAF',
      'Anderson Family Fund',
      'Heartland Wealth Management',
      'HEARTLAND'
    );
    dataset.deceasedDonors.add(happyPath2.deceasedDonor);
    dataset.successors.addAll(happyPath2.successors);
    dataset.advisorFirms.add(happyPath2.advisorFirm);
    dataset.financialAccounts.add(happyPath2.financialAccount);
    dataset.roles.addAll(happyPath2.roles);
    dataset.successionCases.add(happyPath2.successionCase);
    dataset.contactTasks.addAll(happyPath2.contactTasks);

    // Instance 1.3: Susan Rodriguez (Arts Patron, ASDAF, $1.8M)
    SuccessionScenarioData happyPath3 = generateHappyPathVariant(
      'Susan',
      'Rodriguez',
      'Thomas',
      'Rodriguez',
      1800000,
      'ASDAF',
      'Rodriguez Arts Foundation',
      'Independent Financial Partners',
      'PACIFIC NORTHWEST'
    );
    dataset.deceasedDonors.add(happyPath3.deceasedDonor);
    dataset.successors.addAll(happyPath3.successors);
    dataset.advisorFirms.add(happyPath3.advisorFirm);
    dataset.financialAccounts.add(happyPath3.financialAccount);
    dataset.roles.addAll(happyPath3.roles);
    dataset.successionCases.add(happyPath3.successionCase);
    dataset.contactTasks.addAll(happyPath3.contactTasks);

    // Instance 1.4: Michael Johnson (Minimum Balance, ASDAF, $55K)
    SuccessionScenarioData happyPath4 = generateHappyPathVariant(
      'Michael',
      'Johnson',
      'Sarah',
      'Johnson',
      55000,
      'ASDAF',
      'Johnson Family Account',
      'Premier Trust Associates',
      'FLORIDA'
    );
    dataset.deceasedDonors.add(happyPath4.deceasedDonor);
    dataset.successors.addAll(happyPath4.successors);
    dataset.advisorFirms.add(happyPath4.advisorFirm);
    dataset.financialAccounts.add(happyPath4.financialAccount);
    dataset.roles.addAll(happyPath4.roles);
    dataset.successionCases.add(happyPath4.successionCase);
    dataset.contactTasks.addAll(happyPath4.contactTasks);

    // Instance 1.5: Dorothy White (Legacy Account, ISDAF, $1.2M)
    SuccessionScenarioData happyPath5 = generateHappyPathVariant(
      'Dorothy',
      'White',
      'Katherine',
      'White',
      1200000,
      'ISDAF',
      'White Memorial Fund',
      'Northstar Advisory Group',
      'NY METRO'
    );
    dataset.deceasedDonors.add(happyPath5.deceasedDonor);
    dataset.successors.addAll(happyPath5.successors);
    dataset.advisorFirms.add(happyPath5.advisorFirm);
    dataset.financialAccounts.add(happyPath5.financialAccount);
    dataset.roles.addAll(happyPath5.roles);
    dataset.successionCases.add(happyPath5.successionCase);
    dataset.contactTasks.addAll(happyPath5.contactTasks);

    // ========== SCENARIO 2: New DAF Account (3 instances) ==========

    // Instance 2.1: Robert Chen (Original)
    SuccessionScenarioData scenario2 = generateNewDAFScenario();
    dataset.deceasedDonors.add(scenario2.deceasedDonor);
    dataset.successors.addAll(scenario2.successors);
    dataset.advisorFirms.add(scenario2.advisorFirm);
    dataset.financialAccounts.add(scenario2.financialAccount);
    dataset.roles.addAll(scenario2.roles);
    dataset.successionCases.add(scenario2.successionCase);
    dataset.contactTasks.addAll(scenario2.contactTasks);

    // Instance 2.2: Richard Brown (Education Focus, ISDAF, $950K)
    SuccessionScenarioData newDAF2 = generateNewDAFVariant(
      'Richard',
      'Brown',
      'Michelle',
      'Brown',
      950000,
      'ISDAF',
      'Brown Education Fund'
    );
    dataset.deceasedDonors.add(newDAF2.deceasedDonor);
    dataset.successors.addAll(newDAF2.successors);
    dataset.financialAccounts.add(newDAF2.financialAccount);
    dataset.roles.addAll(newDAF2.roles);
    dataset.successionCases.add(newDAF2.successionCase);
    dataset.contactTasks.addAll(newDAF2.contactTasks);

    // Instance 2.3: Patricia Davis (Healthcare Focus, ASDAF, $1.5M)
    SuccessionScenarioData newDAF3 = generateNewDAFVariant(
      'Patricia',
      'Davis',
      'Daniel',
      'Davis',
      1500000,
      'ASDAF',
      'Davis Healthcare Foundation'
    );
    dataset.deceasedDonors.add(newDAF3.deceasedDonor);
    dataset.successors.addAll(newDAF3.successors);
    dataset.financialAccounts.add(newDAF3.financialAccount);
    dataset.roles.addAll(newDAF3.roles);
    dataset.successionCases.add(newDAF3.successionCase);
    dataset.contactTasks.addAll(newDAF3.contactTasks);

    // ========== SCENARIO 3: Disclaim Assets (2 instances) ==========

    // Instance 3.1: Elizabeth Martinez (Original)
    SuccessionScenarioData scenario3 = generateDisclaimScenario();
    dataset.deceasedDonors.add(scenario3.deceasedDonor);
    dataset.successors.addAll(scenario3.successors);
    dataset.advisorFirms.add(scenario3.advisorFirm);
    dataset.financialAccounts.add(scenario3.financialAccount);
    dataset.roles.addAll(scenario3.roles);
    dataset.successionCases.add(scenario3.successionCase);
    dataset.contactTasks.addAll(scenario3.contactTasks);

    // Instance 3.2: William Taylor (Religious Foundation, ASDAF, $680K)
    SuccessionScenarioData disclaim2 = generateDisclaimVariant(
      'William',
      'Taylor',
      'Rebecca',
      'Taylor',
      680000,
      'ASDAF',
      'Taylor Religious Foundation'
    );
    dataset.deceasedDonors.add(disclaim2.deceasedDonor);
    dataset.successors.addAll(disclaim2.successors);
    dataset.financialAccounts.add(disclaim2.financialAccount);
    dataset.roles.addAll(disclaim2.roles);
    dataset.successionCases.add(disclaim2.successionCase);
    dataset.contactTasks.addAll(disclaim2.contactTasks);

    // ========== SCENARIO 4: SLA Escalation (2 instances) ==========

    // Instance 4.1: James O'Connor (Original)
    SuccessionScenarioData scenario4 = generateSLAEscalationScenario();
    dataset.deceasedDonors.add(scenario4.deceasedDonor);
    dataset.successors.addAll(scenario4.successors);
    dataset.advisorFirms.add(scenario4.advisorFirm);
    dataset.financialAccounts.add(scenario4.financialAccount);
    dataset.roles.addAll(scenario4.roles);
    dataset.successionCases.add(scenario4.successionCase);
    dataset.contactTasks.addAll(scenario4.contactTasks);

    // Instance 4.2: George Wilson (Out of Country Successor, ASDAF, $420K)
    SuccessionScenarioData sla2 = generateSLAVariant(
      'George',
      'Wilson',
      'Christopher',
      'Wilson',
      420000,
      'ASDAF',
      'Wilson Charitable Account'
    );
    dataset.deceasedDonors.add(sla2.deceasedDonor);
    dataset.successors.addAll(sla2.successors);
    dataset.financialAccounts.add(sla2.financialAccount);
    dataset.roles.addAll(sla2.roles);
    dataset.successionCases.add(sla2.successionCase);
    dataset.contactTasks.addAll(sla2.contactTasks);

    // ========== SCENARIO 5: Multiple Successors (2 instances) ==========

    // Instance 5.1: Patricia Williams (50/50 split, ASDAF, $3.5M)
    SuccessionScenarioData multiSuccessor1 = generateMultipleSuccessorsScenario(
      'Patricia',
      'Williams',
      new List<String>{ 'Amanda', 'Brandon' },
      new List<String>{ 'Williams', 'Williams' },
      new List<Decimal>{ 50, 50 },
      3500000,
      'ASDAF',
      'Williams Family Foundation'
    );
    dataset.deceasedDonors.add(multiSuccessor1.deceasedDonor);
    dataset.successors.addAll(multiSuccessor1.successors);
    dataset.financialAccounts.add(multiSuccessor1.financialAccount);
    dataset.roles.addAll(multiSuccessor1.roles);
    dataset.successionCases.add(multiSuccessor1.successionCase);
    dataset.contactTasks.addAll(multiSuccessor1.contactTasks);

    // Instance 5.2: Harold Miller (3-way split, PMA, $5.2M)
    SuccessionScenarioData multiSuccessor2 = generateMultipleSuccessorsScenario(
      'Harold',
      'Miller',
      new List<String>{ 'Jessica', 'Andrew', 'Lauren' },
      new List<String>{ 'Miller', 'Miller', 'Thompson' },
      new List<Decimal>{ 40, 35, 25 },
      5200000,
      'PMA',
      'Miller Family Trust Account'
    );
    dataset.deceasedDonors.add(multiSuccessor2.deceasedDonor);
    dataset.successors.addAll(multiSuccessor2.successors);
    dataset.financialAccounts.add(multiSuccessor2.financialAccount);
    dataset.roles.addAll(multiSuccessor2.roles);
    dataset.successionCases.add(multiSuccessor2.successionCase);
    dataset.contactTasks.addAll(multiSuccessor2.contactTasks);

    // TODO: Append each scenario.validationReport into dataset.validationReports for downstream analytics.
    // TODO: Compute dataset.summaryReport = buildDatasetValidation(dataset) and log or assert on any errors surfaced.
    // TODO: Consider returning timing aggregates (scenarioEnd durations) for telemetry consumers once summaryReport is populated.

    return dataset;
  }

  // ==================== SCENARIO VARIANT GENERATORS ====================

  /**
   * @description Generate Happy Path variant with custom parameters
   */
  private static SuccessionScenarioData generateHappyPathVariant(
    String donorFirstName,
    String donorLastName,
    String successorFirstName,
    String successorLastName,
    Decimal balance,
    String program,
    String fundName,
    String advisorName,
    String advisorRegion
  ) {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('HappyPathVariant');

    data.advisorFirm = new AdvisorFirmBuilder()
      .withName(advisorName)
      .withRegion(advisorRegion)
      .buildAndInsert();

    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName(donorFirstName, donorLastName)
      .withNetWorth(balance * 2)
      .withDateOfDeath(Date.today().addDays(-35))
      .buildAndInsert();

    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName(fundName)
      .withProgram(program)
      .withBalance(balance)
      .withAdvisor(data.advisorFirm.Id)
      .buildAndInsert();

    Account successor = new SuccessorBuilder()
      .withName(successorFirstName, successorLastName)
      .withEmail(
        successorFirstName.toLowerCase() +
          '.' +
          successorLastName.toLowerCase() +
          '@email.example.com'
      )
      .asResponsive()
      .buildAndInsert();
    data.successors.add(successor);

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asSuccessor(successor.Id)
        .withAllocation(100)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asAdvisor(data.advisorFirm.Id)
        .buildAndInsert()
    );

    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(1)
      .withContactEstablished()
      .withPathway('Final Grant')
      .withFormCompleted()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Generate Contact Attempt Tasks
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      successorWithContact.PersonContactId,
      1,
      true
    );
    insertTaskList('HappyPathVariant.contactTasks', data.contactTasks);
    // TODO: Capture advisor touchpoints (EventBuilder + TaskBuilder) for variants to reflect multi-party collaboration outlined in the BRD.

    ValidationReport validation = buildScenarioValidation(
      'HappyPathVariant',
      data
    );
    Long duration = scenarioEnd(
      'HappyPathVariant',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;

    return data;
  }

  /**
   * @description Generate New DAF variant with custom parameters
   */
  private static SuccessionScenarioData generateNewDAFVariant(
    String donorFirstName,
    String donorLastName,
    String successorFirstName,
    String successorLastName,
    Decimal balance,
    String program,
    String fundName
  ) {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('NewDAFVariant');

    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName(donorFirstName, donorLastName)
      .withNetWorth(balance * 2.5)
      .withDateOfDeath(Date.today().addDays(-50))
      .buildAndInsert();

    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName(fundName)
      .withProgram(program)
      .withBalance(balance)
      .buildAndInsert();

    Account successor = new SuccessorBuilder()
      .withName(successorFirstName, successorLastName)
      .withEmail(
        successorFirstName.toLowerCase() +
          '.' +
          successorLastName.toLowerCase() +
          '@email.example.com'
      )
      .asResponsive()
      .buildAndInsert();
    data.successors.add(successor);

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asSuccessor(successor.Id)
        .withAllocation(100)
        .buildAndInsert()
    );

    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(2)
      .withContactEstablished()
      .withPathway('New DAF Account')
      .withFormCompleted()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Generate Contact Attempt Tasks
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      successorWithContact.PersonContactId,
      2,
      true
    );
    insertTaskList('NewDAFVariant.contactTasks', data.contactTasks);

    ValidationReport validation = buildScenarioValidation(
      'NewDAFVariant',
      data
    );
    Long duration = scenarioEnd(
      'NewDAFVariant',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;

    return data;
  }

  /**
   * @description Generate Disclaim variant with custom parameters
   */
  private static SuccessionScenarioData generateDisclaimVariant(
    String donorFirstName,
    String donorLastName,
    String successorFirstName,
    String successorLastName,
    Decimal balance,
    String program,
    String fundName
  ) {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('DisclaimVariant');

    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName(donorFirstName, donorLastName)
      .withNetWorth(balance * 3)
      .withDateOfDeath(Date.today().addDays(-65))
      .buildAndInsert();

    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName(fundName)
      .withProgram(program)
      .withBalance(balance)
      .buildAndInsert();

    Account successor = new SuccessorBuilder()
      .withName(successorFirstName, successorLastName)
      .withEmail(
        successorFirstName.toLowerCase() +
          '.' +
          successorLastName.toLowerCase() +
          '@email.example.com'
      )
      .asResponsive()
      .buildAndInsert();
    data.successors.add(successor);

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asSuccessor(successor.Id)
        .withAllocation(100)
        .buildAndInsert()
    );

    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(1)
      .withContactEstablished()
      .withPathway('Disclaim Assets')
      .withFormCompleted()
      .asClosed()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Generate Contact Attempt Tasks
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      successorWithContact.PersonContactId,
      1,
      true
    );
    insertTaskList('DisclaimVariant.contactTasks', data.contactTasks);

    ValidationReport validation = buildScenarioValidation(
      'DisclaimVariant',
      data
    );
    Long duration = scenarioEnd(
      'DisclaimVariant',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;

    return data;
  }

  /**
   * @description Generate SLA Escalation variant with custom parameters
   */
  private static SuccessionScenarioData generateSLAVariant(
    String donorFirstName,
    String donorLastName,
    String successorFirstName,
    String successorLastName,
    Decimal balance,
    String program,
    String fundName
  ) {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('SLAVariant');

    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName(donorFirstName, donorLastName)
      .withNetWorth(balance * 2)
      .withDateOfDeath(Date.today().addDays(-75))
      .buildAndInsert();

    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName(fundName)
      .withProgram(program)
      .withBalance(balance)
      .buildAndInsert();

    Account successor = new SuccessorBuilder()
      .withName(successorFirstName, successorLastName)
      .asUnresponsive()
      .buildAndInsert();
    data.successors.add(successor);

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asSuccessor(successor.Id)
        .withAllocation(100)
        .buildAndInsert()
    );

    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(4)
      .asEscalated()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Generate Contact Attempt Tasks (4 attempts, NO contact established)
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      successorWithContact.PersonContactId,
      4,
      false
    );
    insertTaskList('SLAVariant.contactTasks', data.contactTasks);
    // TODO: Once escalation workflow v2 ships, create follow-up case/team records here to validate ownership rotation.

    ValidationReport validation = buildScenarioValidation('SLAVariant', data);
    Long duration = scenarioEnd(
      'SLAVariant',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;

    return data;
  }

  /**
   * @description Generate Multiple Successors scenario
   */
  private static SuccessionScenarioData generateMultipleSuccessorsScenario(
    String donorFirstName,
    String donorLastName,
    List<String> successorFirstNames,
    List<String> successorLastNames,
    List<Decimal> allocations,
    Decimal balance,
    String program,
    String fundName
  ) {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('MultipleSuccessorsScenario');

    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName(donorFirstName, donorLastName)
      .withNetWorth(balance * 2)
      .withDateOfDeath(Date.today().addDays(-40))
      .asPremierDonor()
      .buildAndInsert();

    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName(fundName)
      .withProgram(program)
      .withBalance(balance)
      .buildAndInsert();

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    // Create multiple successors
    for (Integer i = 0; i < successorFirstNames.size(); i++) {
      Account successor = new SuccessorBuilder()
        .withName(successorFirstNames[i], successorLastNames[i])
        .withEmail(
          successorFirstNames[i].toLowerCase() +
            '.' +
            successorLastNames[i].toLowerCase() +
            '@email.example.com'
        )
        .asResponsive()
        .buildAndInsert();
      data.successors.add(successor);

      data.roles.add(
        new FinancialAccountRoleBuilder(data.financialAccount.Id)
          .asSuccessor(successor.Id)
          .withAllocation(allocations[i])
          .buildAndInsert()
      );
    }

    // Use first successor as primary contact
    Account firstSuccessor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :data.successors[0].Id
      LIMIT 1
    ];

    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(firstSuccessor.PersonContactId)
      .withContactAttempts(2)
      .withContactEstablished()
      .withPathway('Final Grant')
      .withFormCompleted()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Generate Contact Attempt Tasks
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      firstSuccessor.PersonContactId,
      2,
      true
    );
    insertTaskList(
      'MultipleSuccessorsScenario.contactTasks',
      data.contactTasks
    );
    // TODO: Retrieve and surface child cases created by Case_Multiple_Successors_Handler once flow assertions are added, ensuring both successors are represented.

    ValidationReport validation = buildScenarioValidation(
      'MultipleSuccessorsScenario',
      data
    );
    Long duration = scenarioEnd(
      'MultipleSuccessorsScenario',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;

    return data;
  }

  /**
   * @description Generate Fast-Track Urgent scenario
   */
  private static SuccessionScenarioData generateFastTrackScenario(
    String donorFirstName,
    String donorLastName,
    String successorFirstName,
    String successorLastName,
    Decimal balance,
    String program,
    String fundName
  ) {
    SuccessionScenarioData data = new SuccessionScenarioData();
    Long startMs = scenarioStart('FastTrackScenario');

    data.deceasedDonor = new DeceasedDonorBuilder()
      .withName(donorFirstName, donorLastName)
      .withNetWorth(balance * 2.5)
      .withDateOfDeath(Date.today().addDays(-10)) // Recent death
      .buildAndInsert();

    data.financialAccount = new FinancialAccountBuilder(data.deceasedDonor.Id)
      .withName(fundName)
      .withProgram(program)
      .withBalance(balance)
      .buildAndInsert();

    Account successor = new SuccessorBuilder()
      .withName(successorFirstName, successorLastName)
      .withEmail(
        successorFirstName.toLowerCase() +
          '.' +
          successorLastName.toLowerCase() +
          '@email.example.com'
      )
      .asResponsive()
      .buildAndInsert();
    data.successors.add(successor);

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asPrimaryOwner(data.deceasedDonor.Id)
        .buildAndInsert()
    );

    data.roles.add(
      new FinancialAccountRoleBuilder(data.financialAccount.Id)
        .asSuccessor(successor.Id)
        .withAllocation(100)
        .buildAndInsert()
    );

    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    data.successionCase = new SuccessionCaseBuilder(
        data.deceasedDonor.Id,
        data.financialAccount.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(1)
      .withContactEstablished()
      .withPathway('Final Grant')
      .withFormCompleted()
      .withEstateAdministrationRecordType()
      .buildAndInsert();

    // Mark as High Priority
    data.successionCase.Priority = 'High';
    updateWithLogging(
      'FastTrackScenario.casePriorityUpdate',
      data.successionCase
    );

    // Generate Contact Attempt Tasks (fast-track = quick response)
    data.contactTasks = generateContactAttemptTasks(
      data.successionCase.Id,
      successorWithContact.PersonContactId,
      1,
      true
    );
    insertTaskList('FastTrackScenario.contactTasks', data.contactTasks);

    ValidationReport validation = buildScenarioValidation(
      'FastTrackScenario',
      data
    );
    Long duration = scenarioEnd(
      'FastTrackScenario',
      startMs,
      new Map<String, Object>{ 'counts' => validation.counts }
    );
    validation.durationMs = duration;
    data.validationReport = validation;

    return data;
  }
}
