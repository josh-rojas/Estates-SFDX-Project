/**
 * @description Generates secure, encrypted tokens for succession form access via unique URLs
 * @author Claude Code
 * @date 2025-10-02
 *
 * USAGE:
 *   String token = SuccessionFormTokenGenerator.generateToken(caseId);
 *   String url = SuccessionFormTokenGenerator.generateFormURL(caseId);
 *
 * TOKEN FORMAT:
 *   Base64(Encrypt({CaseId}|{ExpirationEpoch}|{HMAC}))
 *
 * SECURITY:
 *   - AES256 encryption using org-specific key
 *   - 30-day expiration
 *   - HMAC signature prevents tampering
 *   - One-time use enforced via Case.Token_Used__c
 *
 * REVISION HISTORY
 * 2025-10-02 - Initial creation for Screen Flow migration
 */
public with sharing class SuccessionFormTokenGenerator {

    // Constants
    private static final Integer TOKEN_EXPIRATION_DAYS = 30;
    private static final String ENCRYPTION_ALGORITHM = 'AES256';
    private static final String TOKEN_DELIMITER = '|';

    /**
     * @description Generates encrypted token for a Case
     * @param caseId The Case ID to generate token for
     * @return Encrypted, URL-safe token string
     */
    public static String generateToken(Id caseId) {
        if (caseId == null) {
            throw new IllegalArgumentException('Case ID cannot be null');
        }

        // Validate Case exists and is correct type
        List<Case> cases = [
            SELECT Id, Type, RecordType.DeveloperName
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (cases.isEmpty()) {
            throw new IllegalArgumentException('Case not found: ' + caseId);
        }

        Case c = cases[0];
        if (c.RecordType.DeveloperName != 'EstateAdministration' ||
            c.Type != 'Named Successor Enactment') {
            throw new IllegalArgumentException('Invalid Case type for succession form');
        }

        // Generate token components
        Long expirationEpoch = DateTime.now().addDays(TOKEN_EXPIRATION_DAYS).getTime();
        String tokenData = String.valueOf(caseId) + TOKEN_DELIMITER + String.valueOf(expirationEpoch);

        // Generate HMAC signature
        String hmac = generateHMAC(tokenData);
        String fullTokenData = tokenData + TOKEN_DELIMITER + hmac;

        // Encrypt and encode
        Blob encryptionKey = getEncryptionKey();
        Blob encrypted = Crypto.encrypt(ENCRYPTION_ALGORITHM, encryptionKey, Blob.valueOf(fullTokenData));
        String token = EncodingUtil.base64Encode(encrypted);

        // Make URL-safe (replace +/= with -_~)
        token = token.replace('+', '-').replace('/', '_').replace('=', '~');

        return token;
    }

    /**
     * @description Generates complete form URL with token
     * @param caseId The Case ID to generate URL for
     * @return Full URL with embedded token
     */
    public static String generateFormURL(Id caseId) {
        String token = generateToken(caseId);
        String baseURL = getExperienceCloudBaseURL();
        return baseURL + '/succession-form?t=' + token;
    }

    /**
     * @description Updates Case with generated token and expiration
     * @param caseId The Case ID to update
     * @return Updated Case record
     */
    public static Case generateAndSaveToken(Id caseId) {
        String token = generateToken(caseId);
        DateTime expiration = DateTime.now().addDays(TOKEN_EXPIRATION_DAYS);

        Case c = new Case(
            Id = caseId,
            Succession_Form_Token__c = token,
            Token_Expiration__c = expiration,
            Token_Used__c = false
        );

        update c;
        return c;
    }

    /**
     * @description Generates HMAC signature for token validation
     * @param data The data to sign
     * @return HMAC signature as hex string
     */
    private static String generateHMAC(String data) {
        Blob mac = Crypto.generateMac('HMacSHA256', Blob.valueOf(data), getEncryptionKey());
        return EncodingUtil.convertToHex(mac).substring(0, 32); // First 32 chars
    }

    /**
     * @description Gets org-specific encryption key
     * @return Encryption key blob
     */
    @TestVisible
    private static Blob getEncryptionKey() {
        // Use org ID as part of key generation for org-specific encryption
        String orgId = UserInfo.getOrganizationId();
        String keyMaterial = 'SuccessionForm' + orgId + 'SecureKey2025';

        // Generate 256-bit key from key material
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(keyMaterial));
        return hash;
    }

    /**
     * @description Gets Experience Cloud site base URL
     * @return Base URL for Experience Cloud site
     */
    @TestVisible
    private static String getExperienceCloudBaseURL() {
        // Query Network (Experience Cloud site)
        List<Network> sites = [
            SELECT UrlPathPrefix, Status
            FROM Network
            WHERE Name = 'DAF Succession Portal' // Update with actual site name
            AND Status = 'Live'
            LIMIT 1
        ];

        if (sites.isEmpty()) {
            // Fallback: Use custom label or hardcoded sandbox URL
            // TODO: Create Custom Label 'Succession_Form_Base_URL'
            return URL.getSalesforceBaseUrl().toExternalForm() + '/succession';
        }

        // Build full URL from Network
        String domain = URL.getSalesforceBaseUrl().getHost();
        String communityPath = sites[0].UrlPathPrefix;

        // Format: https://{domain}/{communityPath}
        return 'https://' + domain + '/' + communityPath;
    }

    /**
     * @description Invocable method for Flow/Process Builder
     * @param requests List of token generation requests
     * @return List of token generation results
     */
    @InvocableMethod(label='Generate Succession Form Token'
                     description='Generates secure token and URL for succession form access'
                     category='Succession Management')
    public static List<TokenResult> generateTokensForFlow(List<TokenRequest> requests) {
        List<TokenResult> results = new List<TokenResult>();

        for (TokenRequest req : requests) {
            try {
                Case c = generateAndSaveToken(req.caseId);
                String url = generateFormURL(req.caseId);

                TokenResult result = new TokenResult();
                result.success = true;
                result.token = c.Succession_Form_Token__c;
                result.formURL = url;
                result.expirationDate = c.Token_Expiration__c;
                results.add(result);

            } catch (Exception e) {
                TokenResult result = new TokenResult();
                result.success = false;
                result.errorMessage = e.getMessage();
                results.add(result);
            }
        }

        return results;
    }

    // Inner classes for Flow integration
    public class TokenRequest {
        @InvocableVariable(required=true label='Case ID' description='The Case ID to generate token for')
        public Id caseId;
    }

    public class TokenResult {
        @InvocableVariable(label='Success' description='Whether token generation succeeded')
        public Boolean success;

        @InvocableVariable(label='Token' description='Generated encryption token')
        public String token;

        @InvocableVariable(label='Form URL' description='Complete form URL with token')
        public String formURL;

        @InvocableVariable(label='Expiration Date' description='Token expiration date/time')
        public DateTime expirationDate;

        @InvocableVariable(label='Error Message' description='Error message if generation failed')
        public String errorMessage;
    }
}
