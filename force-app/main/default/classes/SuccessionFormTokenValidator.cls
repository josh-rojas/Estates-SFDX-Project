/**
 * @description Validates and decrypts succession form tokens from unique URLs
 * @author Claude Code
 * @date 2025-10-02
 *
 * USAGE (in Screen Flow):
 *   ValidationResult result = SuccessionFormTokenValidator.validateToken(tokenFromURL);
 *   if (result.isValid) {
 *       // Load Case data using result.caseId
 *   }
 *
 * VALIDATION CHECKS:
 *   1. Token can be decrypted
 *   2. HMAC signature matches (prevents tampering)
 *   3. Token has not expired
 *   4. Case ID exists and is correct type
 *   5. Token has not been used (one-time use)
 *
 * REVISION HISTORY
 * 2025-10-02 - Initial creation for Screen Flow migration
 */
public with sharing class SuccessionFormTokenValidator {

    // Constants
    private static final String ENCRYPTION_ALGORITHM = 'AES256';
    private static final String TOKEN_DELIMITER = '\\|';

    /**
     * @description Validates token and returns Case ID if valid
     * @param token URL-safe encrypted token
     * @return ValidationResult with validity status and Case ID
     */
    public static ValidationResult validateToken(String token) {
        ValidationResult result = new ValidationResult();
        result.isValid = false;

        if (String.isBlank(token)) {
            result.errorMessage = 'No token provided';
            return result;
        }

        try {
            // Step 1: Decode URL-safe token
            String decodedToken = token.replace('-', '+').replace('_', '/').replace('~', '=');
            Blob encryptedBlob = EncodingUtil.base64Decode(decodedToken);

            // Step 2: Decrypt token
            Blob decryptionKey = getEncryptionKey();
            Blob decrypted = Crypto.decrypt(ENCRYPTION_ALGORITHM, decryptionKey, encryptedBlob);
            String tokenData = decrypted.toString();

            // Step 3: Parse token components
            List<String> parts = tokenData.split(TOKEN_DELIMITER);
            if (parts.size() != 3) {
                result.errorMessage = 'Invalid token format';
                return result;
            }

            String caseIdString = parts[0];
            Long expirationEpoch = Long.valueOf(parts[1]);
            String providedHMAC = parts[2];

            // Step 4: Validate HMAC (prevents tampering)
            String expectedHMAC = generateHMAC(caseIdString + '|' + String.valueOf(expirationEpoch));
            if (providedHMAC != expectedHMAC) {
                result.errorMessage = 'Token has been tampered with';
                return result;
            }

            // Step 5: Check expiration
            DateTime expiration = DateTime.newInstance(expirationEpoch);
            if (expiration < DateTime.now()) {
                result.errorMessage = 'This link has expired. Please contact support for a new link.';
                result.isExpired = true;
                return result;
            }

            // Step 6: Validate Case exists and is correct type
            Id caseId = Id.valueOf(caseIdString);
            List<Case> cases = [
                SELECT Id, CaseNumber, Type, RecordType.DeveloperName,
                       Token_Used__c, Token_Expiration__c,
                       Contact_Established__c, Pathway_Confirmed__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            if (cases.isEmpty()) {
                result.errorMessage = 'Case not found';
                return result;
            }

            Case c = cases[0];

            // Step 7: Validate Case type
            if (c.RecordType.DeveloperName != 'EstateAdministration' ||
                c.Type != 'Named Successor Enactment') {
                result.errorMessage = 'Invalid case type';
                return result;
            }

            // Step 8: Check if token already used (one-time use)
            if (c.Token_Used__c == true) {
                result.errorMessage = 'This link has already been used. Your form was previously submitted.';
                result.isAlreadyUsed = true;
                return result;
            }

            // Step 9: Check if pathway already confirmed (form completed)
            if (String.isNotBlank(c.Pathway_Confirmed__c)) {
                result.errorMessage = 'Your succession pathway has already been confirmed. If you need to make changes, please contact support.';
                result.isAlreadyUsed = true;
                return result;
            }

            // Step 10: Check if contact was established (required before form access)
            if (c.Contact_Established__c != true) {
                result.errorMessage = 'This form cannot be accessed at this time. Our team needs to establish contact first.';
                return result;
            }

            // All validations passed!
            result.isValid = true;
            result.caseId = caseId;
            result.caseNumber = c.CaseNumber;
            result.expirationDate = expiration;

        } catch (Exception e) {
            result.errorMessage = 'Invalid or corrupted token: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Token validation error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }

        return result;
    }

    /**
     * @description Marks token as used after successful form submission
     * @param caseId The Case ID whose token to mark as used
     */
    public static void markTokenAsUsed(Id caseId) {
        Case c = new Case(
            Id = caseId,
            Token_Used__c = true
        );
        update c;
    }

    /**
     * @description Generates HMAC signature (must match generator)
     * @param data The data to sign
     * @return HMAC signature as hex string
     */
    private static String generateHMAC(String data) {
        Blob mac = Crypto.generateMac('HMacSHA256', Blob.valueOf(data), getEncryptionKey());
        return EncodingUtil.convertToHex(mac).substring(0, 32);
    }

    /**
     * @description Gets org-specific encryption key (must match generator)
     * @return Encryption key blob
     */
    @TestVisible
    private static Blob getEncryptionKey() {
        String orgId = UserInfo.getOrganizationId();
        String keyMaterial = 'SuccessionForm' + orgId + 'SecureKey2025';
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(keyMaterial));
        return hash;
    }

    /**
     * @description Invocable method for Screen Flow
     * @param requests List of validation requests
     * @return List of validation results
     */
    @InvocableMethod(label='Validate Succession Form Token'
                     description='Validates secure token from URL and returns Case ID if valid'
                     category='Succession Management')
    public static List<ValidationResult> validateTokensForFlow(List<ValidationRequest> requests) {
        List<ValidationResult> results = new List<ValidationResult>();

        for (ValidationRequest req : requests) {
            results.add(validateToken(req.token));
        }

        return results;
    }

    // Inner classes for Flow integration
    public class ValidationRequest {
        @InvocableVariable(required=true label='Token' description='The encrypted token from URL parameter')
        public String token;
    }

    public class ValidationResult {
        @InvocableVariable(label='Is Valid' description='Whether token is valid and not expired/used')
        public Boolean isValid;

        @InvocableVariable(label='Case ID' description='The Case ID if token is valid')
        public Id caseId;

        @InvocableVariable(label='Case Number' description='The Case Number if token is valid')
        public String caseNumber;

        @InvocableVariable(label='Expiration Date' description='When this token expires')
        public DateTime expirationDate;

        @InvocableVariable(label='Error Message' description='User-friendly error message if invalid')
        public String errorMessage;

        @InvocableVariable(label='Is Expired' description='True if token has expired')
        public Boolean isExpired;

        @InvocableVariable(label='Is Already Used' description='True if token was already used or form submitted')
        public Boolean isAlreadyUsed;

        public ValidationResult() {
            this.isValid = false;
            this.isExpired = false;
            this.isAlreadyUsed = false;
        }
    }
}
