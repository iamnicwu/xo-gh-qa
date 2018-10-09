public class AutoGenerateQuotePdf {
	
	public static Map<Id,Boolean> generatePdf(Map<Id, Id> quoOppIds, String tempId, String serverUrl, String sessionId, String endPoint){
		Map<Id, Boolean> pdfGenerationSuccessMap = new Map<Id, Boolean>();
		String ZSessionId = '';
		String url = '';
		
		Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, StageName, Zuora_Quote_PDF_Session_Id__c FROM Opportunity WHERE Id IN :quoOppIds.values()]);
		
		// first populate pdfGenerationSuccessMap with all 'true' values; negative values will be added below
		for (Opportunity oppRec : oppMap.values()) {
			pdfGenerationSuccessMap.put(oppRec.Id, true);
		}

		if(!Test.isRunningTest()){
			Zuora.ZApi zApiInstance = new Zuora.ZApi();
			Zuora.zApi.LoginResult loginResult = zApiInstance.zlogin();
			ZSessionId = loginResult.Session;
		}
		// CSP-904 for transactions quote template
		Map<Id, zqu__Quote__c> quoteMap = new Map<Id, zqu__Quote__c>([SELECT id, Name, zqu__QuoteTemplate__c, zqu__QuoteTemplate__r.zqu__Template_Id__c, Product_Line__c, zqu__Opportunity__r.Zuora_Quote_PDF_Session_Id__c FROM zqu__Quote__c WHERE Id IN: quoOppIds.keySet()]); 

		// used for exception handling (key: Opportunity Id | value: List<Exception>)
 		Map<Id, List<Exception>> exceptionMap = new Map<Id, List<Exception>>();

 		// used to insert Payment Schedule PDF Attachments
 		List<Attachment> paymentScheduleList = new List<Attachment>();

 		// set used for cloning/reordering Attachments
 		Set<Id> oppIdSet = new Set<Id>();

 		// this loop generates all the Zuora Quote Template PDFs
 		// a callout to Zuora is performed, where the PDF is generated and then sent back to Salesforce and attached to the Opportunity
 		
 		// CSP-1952 | need to cast to list for iteration
 		Integer connectionCancelledFailCount = 0;
 		List<Id> quoOppIdsKeySetList = new List<Id>(quoOppIds.keySet());
 		for (Integer i = 0; i < quoOppIdsKeySetList.size(); i++) {
 			Id qId = quoOppIdsKeySetList[i];
 			HttpRequest req = new HttpRequest();
			Id oppId = quoOppIds.get(qId);
			oppIdSet.add(oppId);
			String sessionId2 = '';
			if (oppMap.containsKey(oppId)) {
				sessionId2 = oppMap.get(oppId).Zuora_Quote_PDF_Session_Id__c;
			}
			
			//Set HTTPRequest Method
			req.setMethod('GET');
			String zuoraTempId = '';
			zuoraTempId = tempId;

			url = endPoint+'&quoteId='+qId+'&serverUrl='+serverUrl+'&sessionId='+sessionId2+'&templateId='+zuoraTempId+'&useSFDCLocale=1&zquotesMajorVersion=6'+
				  '&zquotesMinorVersion=53&ZSession='+ZSessionId;

			req.setEndpoint(url);
	
			Http http = new Http();

			try {
				//Execute web service call here		
				HTTPResponse res = http.send(req);
				System.debug(res.getBody());
				url = '';
			} catch(Exception e) {
				// CSP-1952 | retrying if we encounter the "connection was cancelled here" error
				if (String.isNotBlank(e.getMessage()) && e.getMessage().containsIgnoreCase('connection was cancelled here')) {
					// if connectionCancelledFailCount < 3 for this record, retry this record
					if (connectionCancelledFailCount < 3) {
						connectionCancelledFailCount++;
						i--; // this sets the FOR loop above to retry this record
						continue; // continue the FOR loop to escape the "reset" logic at the bottom of the loop
					}
					// otherwise add to failure list
					List<Exception> exceptionList = exceptionMap.containsKey(oppId) ? exceptionMap.get(oppId) : new List<Exception>();
					exceptionList.add(e);
					exceptionMap.put(oppId, exceptionList);
				}
				// this callout frequently "fails" due to timeouts, but we have yet to have it fail to produce a Quote Template PDF
				else if (String.isNotBlank(e.getMessage()) && !e.getMessage().containsIgnoreCase('read timed out')) {
					List<Exception> exceptionList = exceptionMap.containsKey(oppId) ? exceptionMap.get(oppId) : new List<Exception>();
					exceptionList.add(e);
					exceptionMap.put(oppId, exceptionList);
				}
			}

			// reset the connectionCancelledFailCount to zero
			connectionCancelledFailCount = 0;
		}

		// this loop generates all the Payment Schedule PDFs and adds them to a list to be inserted
		for (Id qId : quoOppIds.keySet()) {
			if (!quoOppIds.containsKey(qId) || !quoteMap.containsKey(qId)) {
				continue;
			}
			Id oppId = quoOppIds.get(qId);
			zqu__Quote__c zuoraQuoteRecord = quoteMap.get(qId);
			try {
				Attachment paymentSchedule = generatePaymentSchedulePDF(qId, oppId, zuoraQuoteRecord.Name);
				paymentScheduleList.add(paymentSchedule);
			} catch(Exception e) {
				if (String.isNotBlank(e.getMessage())) {
					List<Exception> exceptionList = exceptionMap.containsKey(oppId) ? exceptionMap.get(oppId) : new List<Exception>();
					exceptionList.add(e);
					exceptionMap.put(oppId, exceptionList);
				}
			}
		}

		// if Payment Schedule PDFs were generated, proceed to insert them into the database
		if (!paymentScheduleList.isEmpty()) {
			insert paymentScheduleList;
		}

		// if there were zero exceptions thrown for a specific Opportunity during this process, proceed to re-order the Opportunity's PDF attachments
		// so that they attached to the Echosign Agreement in the correct order (Echosign seems to query based on datetime inserted)
		// WARNING: THIS SECTION OF CODE DOES ***NOT*** FOLLOW BEST PRACTICES
		// the only reason why we are doing DML in a FOR loop is to explicitly insert them in order for Echosign
		AttachmentTriggerHanlder.forceDelete = true;	
		for (Id oppIdValue : oppIdSet) {
			if (exceptionMap.containsKey(oppIdValue)) {
				continue;
			}
			List<Attachment> attachmentList = [SELECT Id, IsDeleted, ParentId, Name, IsPrivate, ContentType, BodyLength, Body, OwnerId, CreatedById, Description FROM Attachment WHERE ParentId = :oppIdValue AND IsDeleted = false ORDER BY Name ASC];
			for (Attachment aRec : attachmentList) {
				insert aRec.clone(false, true, false, false);
			}
			delete attachmentList;
		}

		// lastly if there were exceptions thrown, handle them here
		if (!exceptionMap.isEmpty()) {
			// insert all Exceptions as XO_Exception__c records
			List<Exception> exceptionInsertList = new List<Exception>();
			List<XO_Exception__c> xoExceptionInsertList = new List<XO_Exception__c>();
			for (List<Exception> exceptionList : exceptionMap.values()) {
				exceptionInsertList.addAll(exceptionList);
			}
			for (Exception e : exceptionInsertList) {
				xoExceptionInsertList.add(ExceptionUtility.consumeException(e, false));
			}
			insert xoExceptionInsertList;
			// for all failures, update the pdfGenerationSuccessMap
			for (Id exceptionOppId : exceptionMap.keySet())	{
				pdfGenerationSuccessMap.put(exceptionOppId, false);
			}	
		}
		return pdfGenerationSuccessMap;
	}

	public static Attachment generatePaymentSchedulePDF(Id quoteId, Id opportunityId, String quoteName) {
		PageReference pdf = Page.ZuoraPaymentScheduleBreakdown;
		pdf.getParameters().put('quoteId',quoteId);

		// create the new attachment
		Attachment paymentBreakdownPDFAttachment = new Attachment();
		Blob body;
		// returns the output of the page as a PDF
		body = pdf.getContent();

		paymentBreakdownPDFAttachment.Body = body;
		paymentBreakdownPDFAttachment.Name = quoteName + '_PSB.pdf';
		paymentBreakdownPDFAttachment.IsPrivate = false;
		paymentBreakdownPDFAttachment.ParentId = opportunityId;
		return paymentBreakdownPDFAttachment;
	}	

    public class QueueableOne implements Queueable, Database.AllowsCallouts {

		private Map<Id, Id> quoOppIds;
		private String tempId;
		private String serverUrl;
		private String sessionId;
		private String endPoint;

	 	// Opp Id constructor
		public QueueableOne(Map<Id, Id> quoOppIds, String tempId, String serverUrl, String sessionId, String endPoint) {
			this.quoOppIds = quoOppIds;
			this.tempId = tempId;
			this.serverUrl = serverUrl;
			this.sessionId = sessionId;
			this.endPoint = endPoint;
		}

		public void execute(QueueableContext context) {
			System.debug('autogeneratequotepdf queued job running!!!!');
			System.debug(this.quoOppIds);
			System.debug(this.tempId);
			System.debug(this.serverUrl);
			System.debug(this.sessionId);
			System.debug(this.endPoint);
			generatePdf(this.quoOppIds, this.tempId, this.serverUrl, this.sessionId, this.endPoint);
		}
	}
}