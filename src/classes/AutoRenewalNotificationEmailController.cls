public with sharing class AutoRenewalNotificationEmailController {
	public Id quoteId {get;set;}
	public zqu__Quote__c zQuote {
		get{
			if (zQuote == null) {
					zQuote = new zqu__Quote__c();
			}
			List<zqu__Quote__c> quoteList = [SELECT Id,Name,zqu__Account__r.Name, Preferred_Payment_Schedule__c, zqu__BillCycleDay__c,zqu__BillingCycleDay__c, 
																					True_TCV__c, zqu__SubscriptionTermEndDate__c, 
																					zqu__Opportunity__r.Renew_Subscription__r.Zuora__NextRenewalDate__c, zqu__Account__r.Owner.FirstName, zqu__Account__r.Owner.LastName, 
																					zqu__Account__r.Owner.Email, zqu__Account__r.Owner.Phone, zqu__Account__r.Strategy_Specialist__r.LastName,
																					zqu__Account__r.Strategy_Specialist__r.FirstName, zqu__Account__r.Strategy_Specialist__r.Email,True_TCV_JSON_Response__c,
																					zqu__Account__r.Strategy_Specialist__r.Phone, zqu__Previewed_TCV__c, zqu__InitialTerm__c, zqu__ZuoraAccountID__c,zqu__TermStartDate__c 
																			FROM zqu__Quote__c 
																			WHERE Id = :quoteId limit 1];
			if (quoteList.size()>0) {
				zQuote = (zqu__Quote__c)quoteList[0];
			}
			return zQuote;
		} 
		set;
	}

	public List<String> ratePlanNameList {
		get{
			if (ratePlanNameList == null ) {
				ratePlanNameList = new List<String>();
			}
			List<zqu__QuoteRatePlan__c> quoteRatePlanList = [SELECT Name
																			FROM zqu__QuoteRatePlan__c 
																			WHERE zqu__Quote__c = :quoteId ];
			if (quoteRatePlanList.size()>0) {
				for (Integer i = 0; i< quoteRatePlanList.size(); i++) {
					zqu__QuoteRatePlan__c quoteRatePlan = (zqu__QuoteRatePlan__c)quoteRatePlanList[i];
					ratePlanNameList.add(quoteRatePlan.Name);
				}
			}
			return ratePlanNameList;
		} 
		set;
	}

	// Breakdown the True_TCV_JSON_Response__c of quote to get the total Amount to billed
	public Decimal totalAmount{
		get{
			Decimal totalAmountPeriod = 0;

			if (zQuote != null) {
				// CSP-2667 Adding more than 60 services
				// Used an attachment to store the True_TCV_JSON_Response__c if the response is too long
				// if the True_TCV_JSON_Response__c is blank, we query the response attachment
				String attName = String.valueOf(zQuote.Id) + 'JSON.txt';
				List<Attachment> attList = new List<Attachment>();
				if (String.isBlank(zQuote.True_TCV_JSON_Response__c)) {
					attList = [SELECT Id,Body FROM Attachment WHERE ParentId =: zQuote.Id AND Name = : attName LIMIT 1];
				}
				

				if (String.isNotBlank(zQuote.True_TCV_JSON_Response__c) || !attList.isEmpty()) {
					String jsonResponse = '';
					// if the True_TCV_JSON_Response__c is not blank, we use True_TCV_JSON_Response__c to generate totalAmountPeriod
					if (String.isNotBlank(zQuote.True_TCV_JSON_Response__c)){
						jsonResponse = zQuote.True_TCV_JSON_Response__c;
					}
					else{
						jsonResponse = attList[0].Body.toString();
					}
					// breakdown the response JSON
					// PaymentSchBreakdownController.ZuoraSubscPreview jsonSubPreview = (PaymentSchBreakDownController.ZuoraSubscPreview)JSON.deserialize(zQuote.True_TCV_JSON_Response__c, PaymentSchBreakDownController.ZuoraSubscPreview.class);
          PaymentSchBreakdownController.ZuoraSubscPreview jsonSubPreview = (PaymentSchBreakDownController.ZuoraSubscPreview)JSON.deserialize(jsonResponse, PaymentSchBreakDownController.ZuoraSubscPreview.class);
          List<PaymentSchBreakdownController.InvoiceItems> jsonInvoiceItems = jsonSubPreview.invoiceItems;

          // get the StartDate and Enddate
          Date subscriptionStartDate = zQuote.zqu__TermStartDate__c;
          Date subscriptionEndDate;
          if(zQuote.zqu__SubscriptionTermEndDate__c != null) {
            subscriptionEndDate = zQuote.zqu__SubscriptionTermEndDate__c;
          } else {
            subscriptionEndDate = zQuote.zqu__TermStartDate__c.addMonths(Integer.valueOf(zQuote.zqu__InitialTerm__c));
          }

          Date bcdAlignmentDate = Date.newInstance(subscriptionStartDate.year(), subscriptionStartDate.month(), Integer.valueOf(zQuote.zqu__BillCycleDay__c));

          // get the tatal Amount base the StartDate and billed date
          while(bcdAlignmentDate <= subscriptionEndDate) {
            Decimal grandTotal = 0;

            for(Integer i = 0; i < jsonInvoiceItems.size(); i++) {
            	PaymentSchBreakdownController.InvoiceItems currentInvoiceItem = jsonInvoiceItems[i];
              if(currentInvoiceItem.serviceStartDate <= bcdAlignmentDate) {
                grandTotal += currentInvoiceItem.chargeAmount;
                jsonInvoiceItems.remove(i);
                i--;
              }
            }

            if(totalAmountPeriod < grandTotal) {
            	totalAmountPeriod = grandTotal;
            }

            bcdAlignmentDate = bcdAlignmentDate.addMonths(1);
          }
				}
				
			}
			return totalAmountPeriod;
		} 
		set;
	}

	// get the billed period base the Preferred_Payment_Schedule__c of quote
	public String totalAmountToBilled{
		get{
			String totalAmountToBilled = '';
			if (zQuote.Preferred_Payment_Schedule__c =='Month') {
				totalAmountToBilled = 'each Month';
			}
			else if(zQuote.Preferred_Payment_Schedule__c =='Quarter'){
				totalAmountToBilled = 'each Quarterly';
			}
			else if (String.isNotBlank(zQuote.Preferred_Payment_Schedule__c)) {
				totalAmountToBilled = zQuote.Preferred_Payment_Schedule__c + 'ly';
			}
			return totalAmountToBilled;
		}
		set;
	}

	// Get the url of JPike Signature picture
	public String signatureDucomentId{
		get{
			String emailSignatureName = Label.AutoRenewalNotificationEmail4;
			String signatureDucomentId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.ImageServer?id=';
			List<Document> documentList = [select Id from Document where DeveloperName =: emailSignatureName];
			if (!documentList.isEmpty()) {
		  	signatureDucomentId +=  String.valueOf(documentList[0].Id);
			}
			signatureDucomentId += '&oid=' + UserInfo.getOrganizationId();
			return signatureDucomentId;
		}
		set;
	}
	public AutoRenewalNotificationEmailController() {
		
	}
}