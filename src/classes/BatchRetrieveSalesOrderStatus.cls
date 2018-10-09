/* 
	@Purpose: 1 Retrieve the salesorder from Operative.One by API Call for the Prospecting National Opportunity
						2 Check the Status of Salesorder, if the Status is "Final Order Creation", 
										created the task "RFP has been approved and ready to be pitched to client" 
										and auto closed the task "RFP has been submitted"
	@Created By: Tony Liu
	@Created Date: 09/26/2017
	@Ticket: CSP-1700
*/
global class BatchRetrieveSalesOrderStatus implements Database.Batchable<sObject>, Database.AllowsCallouts{
	private static final String OPPORTUNITY_QUERY = 'SELECT '
																								+ 'Id, '
																								+ 'OwnerId, '
																								+   'Name, '
																								+   'OrderNumber__c, '
																								+   '(SELECT '
																										+   'Id, '
																										+   'PricebookEntryId '
																								+   ' FROM '
																										+   'OpportunityLineItems'
																								+   ' WHERE '
																										+ '{OLIWHERECLAUSE}'
																								+ '), '
																								+   '(SELECT '
																										+   'Id, '
																										+   'Name, '
																										+ 'Internal_Due_Date__c, '
																										+ 'Opportunity__c, '
																										+ 'Opportunity__r.OwnerId '
																								+   ' FROM '
																										+   'ThoughtStarters_RFPs__r'
																								+ ' WHERE '
																										+ 'RecordType.Name = \'RFP\''
																								+ ') '
																							+   ' FROM '
																								+   'Opportunity'
																							+   ' WHERE '
																								+ 'OrderNumber__c != \'\''
																								+ ' AND '
																								+ 'OrderNumber__c != null'
																								+ ' AND '
																								+ 'StageName = \'Prospecting\''
																								+   '{WHERECLAUSE}';

	// get the subject of task and the endpoint URL 
	private static final String RFPPENDINGPITCHEDTASKSUBJECT = system.label.RFPPendingPitchTaskSubject;
	private static final String RFPSUBMITTEDTASKSUBJECT = system.label.RFPSubmittedTaskSubject;
	private static final String ENDPOINTBASICURL = system.label.OperativeOneEndPointURL;
	private OperativeOne__OperativeIntegrationSettings__c operativeOneSetting = OperativeOne__OperativeIntegrationSettings__c.getOrgDefaults();
	public String queryString;
	private Id priceBook2Id;
	private Datetime durationTime;

	global BatchRetrieveSalesOrderStatus() {
		// get the Uncategorized Revenue PricBookId, 
		// the "Uncategorized Revenue" OpporunityLineItem under an Opp indicated that the Opp need not to retrieve the salesorder from Operative.One
		if(!Test.isRunningTest()){
			priceBook2Id = [select Id from PricebookEntry where Name = 'Uncategorized Revenue' and Pricebook2.IsActive = true and Pricebook2.IsStandard = true limit 1].Id;
		}else{
			priceBook2Id = [select Id from PricebookEntry where Name = 'Uncategorized Revenue' limit 1].Id;
		}

		// generated the timeduration for the lastmodifieddate of Opp, we only retrieve the salesorder for the lastmodifieddate in the timeduration
		Integer timeLenths = Integer.valueOf(system.Label.NationalOppRetrieveOrderTimeDuration);
		durationTime = Datetime.now().addminutes(-timeLenths);

		queryString = OPPORTUNITY_QUERY;
		queryString = queryString.replace('{OLIWHERECLAUSE}', 'PricebookEntryId != \'' + priceBook2Id + '\'');
		queryString = queryString.replace('{WHERECLAUSE}', ' AND lastmodifieddate >=: durationTime');
		System.debug(LoggingLevel.INFO, '***queryString : ' + queryString);
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(queryString);
	}

	global void execute(Database.BatchableContext BC, list<Opportunity> scope) {
		List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

		Set<Id> completeOpportunitySet = new Set<Id>();
		Set<Id> tsRFPIdSet = new Set<Id>();

		Map<Id,ThoughtStarter_RFP__c> rfpIdMap = new Map<Id,ThoughtStarter_RFP__c>();

		// Generate the Opportunity Id Set which has been created a task 'RFP has been approved and ready to be pitched to client'
		for (Opportunity opp : scope) {
			if (opp.ThoughtStarters_RFPs__r.size()>0) {
				tsRFPIdSet.add(opp.ThoughtStarters_RFPs__r[0].Id);
			}
		}
		
		if (!tsRFPIdSet.isEmpty()) {

			List<ThoughtStarter_RFP__c> rfpList = [SELECT id, name, Opportunity__c, 
																																													(SELECT id, WhatId, Subject 
																																															FROM Tasks 
																																															WHERE Subject =: RFPPENDINGPITCHEDTASKSUBJECT) 
																																									FROM ThoughtStarter_RFP__c 
																																									WHERE Id in: tsRFPIdSet];
			
			for (ThoughtStarter_RFP__c currentRFP : rfpList) {
				if (currentRFP.tasks.size()>0) {
					completeOpportunitySet.add(currentRFP.Opportunity__c);
				}
			}
		}


		Http h = new Http();

		Blob headerValue = Blob.valueOf(operativeOneSetting.OperativeOne__O1Credentials__c);
		String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);

		HttpRequest req = new HttpRequest();
		req.setTimeout(120000);
		req.setMethod('GET');
		req.setHeader('Content-Type', 'application/xml');
		req.setHeader('Authorization', authorizationHeader);
		req.setHeader('Cache-Control', 'no-cache');
		req.setHeader('version', 'v2');
		req.setHeader('Accept', 'application/json');

		for (Opportunity currentOpp : scope) {
			// we only retrieve the salesorder for the OPP which has no "Uncategorized Revenue" OpporunityLineItem 
			// and no task with subject 'RFP has been approved and ready to be pitched to client'
			System.debug(LoggingLevel.INFO, '***currentOpp.OpportunityLineItems.size() : ' + currentOpp.OpportunityLineItems.size());
			System.debug(LoggingLevel.INFO, '***completeOpportunitySet : ' + completeOpportunitySet);
			System.debug(LoggingLevel.INFO, '***currentOpp.Id : ' + currentOpp.Id);
			if (currentOpp.OpportunityLineItems.size() > 0 && !completeOpportunitySet.contains(currentOpp.Id)) {

				HttpRequest req1 = new HttpRequest();
				req1 = req;
				req1.setEndpoint(operativeOneSetting.OperativeOne__O1URL__c + ENDPOINTBASICURL+currentOpp.OrderNumber__c);
				HttpResponse res = h.send(req1);
				System.debug(LoggingLevel.INFO, '***res.getBody() : ' + res.getBody());
				String bodyString = String.valueOf(res.getBody());

				// bodyString = bodyString.replace('{\"org.springframework.validation.BindingResult.salesoderdetails\":','');
				// bodyString = bodyString.substring(0, bodyString.length()-1);
				// OperativeOneResponseWrapper operativeoneResponse = new OperativeOneResponseWrapper();
				// operativeoneResponse = (OperativeOneResponseWrapper)JSON.deserialize(bodyString, OperativeOneResponseWrapper.class);
				// if (operativeoneResponse.salesOrders[0].status == 'Final Order Creation') {
				//  rfpIdMap.put(currentOpp.ThoughtStarters_RFPs__r[0].Id, currentOpp.ThoughtStarters_RFPs__r[0]);
				// }
				
				// if (bodyString.containsIgnoreCase('Proposal Creation')) {

				// if the salesorder's Status is 'Final Order Creation', we should create a new task for the child RFP and complete the task "RFP has been submitted"
				if (bodyString.containsIgnoreCase('Final Order Creation')) {
						rfpIdMap.put(currentOpp.ThoughtStarters_RFPs__r[0].Id, currentOpp.ThoughtStarters_RFPs__r[0]);
				}
			}
		}

		if (!rfpIdMap.isEmpty()) {
			List<Task> newTaskList = new List<Task>();
			
			// auto close the task "RFP has been submitted"
			List<Task> autoClosedTaskList = [Select id, Status from Task where Subject =:RFPSUBMITTEDTASKSUBJECT AND WhatId in: rfpIdMap.keySet() ];
			if (!autoClosedTaskList.isEmpty()) {
				for (Task currentTask: autoClosedTaskList) {
					currentTask.Status = 'Completed'; 
				}

				Database.DMLOptions dmlo = new Database.DMLOptions();
				dmlo.EmailHeader.triggerUserEmail = true;
				List<Database.SaveResult> saveResultsList = Database.update(autoClosedTaskList, dmlo);

				xoExceptionList.addAll(ExceptionUtility.consumeException(saveResultsList));
			}

			// auto create the task "RFP has been approved and ready to be pitched to client!" for child RFP
			for (Id  rfpId: rfpIdMap.keySet()) {
				Task newTask = new Task();
				newTask.Subject = RFPPENDINGPITCHEDTASKSUBJECT;
				newTask.WhatId = rfpId;
				newTask.OwnerId = rfpIdMap.get(rfpId).Opportunity__r.OwnerId;
				newTask.Type = 'Other';
				newTask.Purpose__c = 'Pitch RFP to Client';
				newTask.ActivityDate = rfpIdMap.get(rfpId).Internal_Due_Date__c;
				newTaskList.add(newTask);
			}

			if (!newTaskList.isEmpty()) {
				Database.DMLOptions dmlo = new Database.DMLOptions();
				dmlo.EmailHeader.triggerUserEmail = true;
				List<Database.SaveResult> saveResultsList = Database.insert(newTaskList, dmlo);
				xoExceptionList.addAll(ExceptionUtility.consumeException(saveResultsList));
			}
		}

		if (!xoExceptionList.isEmpty()) {
			insert xoExceptionList;
		}

	}

	global void finish(Database.BatchableContext BC) {

	}
}