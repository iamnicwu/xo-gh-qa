global without sharing class CreateNewPaymentMethodController {
	
	// The Zuora id of the payment page
	global String pageId {
		get {
			if(pageId == null) {
				pageId = '';
			}
			
			return pageId;
		}
		set;
	}
		
	// Constructor, determines the Zuora page Id based on payment method of the quote
	global CreateNewPaymentMethodController(ApexPages.StandardController standardController) {
				
		// Ensure the payment method field is populated on the Quote sObject
		if(!Test.isRunningTest()) {
			standardController.addFields(new List <String> {'zqu__PaymentMethod__c'});
		}
			
		// Retrieve the quote and set the payment method type based on the quote's payment method
		zqu__Quote__c quote = (zqu__Quote__c)standardController.getRecord();
		
		System.Debug(quote.Id);
		String paymentMethodType = quote.zqu__PaymentMethod__c;
		
		// Query for settings
		List < zqu__HostedPageLiteSetting__c > settingList = [SELECT zqu__PageId__c, zqu__PaymentMethodType__c, zqu__ComponentName__c 
																													FROM zqu__HostedPageLiteSetting__c 
																													WHERE zqu__PaymentMethodType__c = :paymentMethodType LIMIT 1];

		if(settingList != null && !settingList.isEmpty()) {
			pageId = settingList[0].zqu__PageId__c;
		}
	}

	/**
	 *   Add RemoteAction method to seperate NVM callout and Zuora Payment Method page callout.
	 *
	 *   @author Scott Yang
	 *   @date   2017-04-13
	 *   @return results of call Recording 
	 */
	@RemoteAction
	global static String pauseCallRecording(){
		String resPaused;
		resPaused = NewVoiceMediaUtility.pauseOrResumeCallRecording('Paused');
		System.debug(LoggingLevel.INFO, '*** resPaused: ' + resPaused);
		return resPaused;
	}

	/**
	 *   CSP-2096
	 *   Add RemoteAction method to resume NVM Call Recording 
	 *
	 *   @author Scott Yang
	 *   @date   2017-04-19
	 *   @return results of resume call Recording 
	 */
	@RemoteAction
	global static String resumeCallRecording(){
		String resStarted;
		resStarted = NewVoiceMediaUtility.pauseOrResumeCallRecording('Started');
		System.debug(LoggingLevel.INFO, '*** resStarted: ' + resStarted);
		// ExceptionUtility.consumeException('test NVM Resume call recording' + String.valueOf(System.Now()),'test NVM Resume call recording',true, '');
		return resStarted;
	}
}