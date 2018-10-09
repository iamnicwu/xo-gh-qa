@isTest
public with sharing class BatchCalculateLiveChargeTCVSchJobTest {

  @isTest static void testSchJob() {
		System.schedule('BatchCalculateLiveChargeTCVSchJobTest', '0 0 0 1 * ?', new BatchCalculateLiveChargeTCVSchJob());
	}
}