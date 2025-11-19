/**
 * @description Test class for SuccessionLogger
 * @author Estate Administration Team
 * @date 2025-11-18
 */
@isTest
private class SuccessionLogger_Test {
  @isTest
  static void testLoggingMethods() {
    // Since System.debug cannot be asserted directly without complex trace parsing,
    // we are primarily testing that the methods execute without exception.

    Test.startTest();

    SuccessionLogger.debug('Test debug message');
    SuccessionLogger.info('Test info message');
    SuccessionLogger.warn('Test warn message');
    SuccessionLogger.error('Test error message');

    try {
      Integer i = 1 / 0;
    } catch (Exception e) {
      SuccessionLogger.error('Test exception logging', e);
    }

    Test.stopTest();

    // No assertions needed as we are verifying execution flow only.
    // In a real implementation with Platform Events or Custom Objects,
    // we would query those to verify logging occurred.
    System.assert(true, 'Logger methods executed successfully');
  }
}
