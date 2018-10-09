global class BatchEchoSignNotifications implements Database.Batchable<sObject> {
	//////////////////////
	// STATIC VARIABLES //
	//////////////////////
	private static final String OPP_CLIENT_APPROVAL = 'SELECT '
																											+	'Id, '
																											+	'StageName, '
																											+	'Three_Business_Days_From_Today__c, '
																											+	'EchoSign_Contract_Due_Date__c, '
																											+	'OwnerId '
																										+	' FROM '
																											+	' Opportunity '
																										+	' WHERE '
																											+	'{WHERECLAUSE}';

  // Query being used in Batch																											
	String query;
	
	global BatchEchoSignNotifications() {
		query = OPP_CLIENT_APPROVAL;
		
		String twoDayDate = DateTime.newInstance(DateUtility.addBusinessDays(Date.today(), 2), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
		String expireDate = DateTime.newInstance(DateUtility.addBusinessDays(Date.today(), -1), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
		
		// Replace {WHERECLAUSE} with needed statements to fulfill CSP-829
		query = query.replace('{WHERECLAUSE}',  ' (StageName = \'Pending Client Approval\' OR StageName = \'Quoting\')'
																							+ ' AND '
																						+ '(Three_Business_Days_From_Today__c = ' + twoDayDate + ' OR Three_Business_Days_From_Today__c = ' + expireDate + ')');
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
		// Instantiate dates which will be used to determine what notification and action to perform
		Date twoDayDate = DateUtility.addBusinessDays(Date.today(), 2);
		Date expireDate = DateUtility.addBusinessDays(Date.today(), -1);

		// Instantiate list of Opportunities to be updated and SingleEmailMessages to be sent
		List<Opportunity> expiredAgreementOppList = new List<Opportunity>();
		List<Messaging.SingleEmailMessage> notifEmailList = new List<Messaging.SingleEmailMessage>();
		
		// Get Organization Wide Email to use for sending out EchoSign Notifications. If no email is found build exception
		// record as this process happens in a batch.
		OrgWideEmailAddress orgEmail;
		try{
			orgEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@xogrp.com'];
		} catch(Exception e) {
			ExceptionUtility.consumeException(e, true);
		}

		// Loop through all retrieved records that need to be processed for notifications
		for(Integer i = 0; i < scope.size(); i++) {
			Opportunity currentOpp = (Opportunity)scope[i];

			// Prepare SingleEmailMessage to be used
			Messaging.SingleEmailMessage notifEmail;

			if(currentOpp.Three_Business_Days_From_Today__c == twoDayDate && currentOpp.StageName == 'Pending Client Approval') {
				// Two day notification messages:email
				notifEmail = EmailUtility.createTwoDayContractEmail(currentOpp);

			} else if(currentOpp.Three_Business_Days_From_Today__c == expireDate && (currentOpp.StageName == 'Quoting' || currentOpp.StageName == 'Pending Client Approval')) {
				// Contract expired notification messages:email
				notifEmail = EmailUtility.createExpiredContractEmail(currentOpp);

				// Update the Opportunity which has had its agreement expire to Quoting and add to a list for updating
				if(currentOpp.StageName == 'Pending Client Approval') {
					currentOpp.StageName = 'Quoting';
					expiredAgreementOppList.add(currentOpp);
				}
			}

			// If the orgEmail was previously retrieved without error add to the notification email being sent out
			if(orgEmail != null) {
				notifEmail.setOrgWideEmailAddressId(orgEmail.Id);
			}

			// Add notification email to notification email list
			notifEmailList.add(notifEmail);
		}

		

		// Update expired agreement Opportunities to have the stage "Quoting". If this action fails create an exception 
		// record using the ExceptionUtility class.
		try {
			//////////////////////////
			// UPDATE OPPORTUNITIES //
			//////////////////////////
			update expiredAgreementOppList;

			//////////////////////////////
			// SEND NOTIFICATION EMAILS //
			//////////////////////////////
			Messaging.sendEmail(notifEmailList);
		} catch(Exception e) {
			ExceptionUtility.consumeException(e, true);
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		// No logic needed here as of 05/17/2016
	}
	
}