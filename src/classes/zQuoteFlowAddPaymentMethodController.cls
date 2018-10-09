public with sharing class zQuoteFlowAddPaymentMethodController extends zqu.BaseQuoteWizardController {
    /*URL Parameters
    CreatePaymentMethod?
    Id=a0pg0000000rbfVAAQ
    &quoteType=Subscription
    &retUrl=%2F006g0000006nIRVAA2
    &stepNumber=3*/

	// The Zuora id of the payment page
    public String pageId {
        get {
            if(pageId == null) pageId = '';
            return pageId;
        }
        set;
    }
      
    // Constructor, determines the Zuora page Id based on payment method of the quote
    public zQuoteFlowAddPaymentMethodController(ApexPages.StandardController standardController) {
        super(standardController);
        // Ensure the payment method field is populated on the Quote sObject   
        //if(!Test.isRunningTest()) standardController.addFields(new List < String > {'zqu__PaymentMethod__c'});

        quoteId = ApexPages.currentPage().getParameters().get('Id');
        thisQuote = [SELECT Id, zqu__PaymentMethod__c FROM zqu__Quote__c WHERE Id = :quoteId];

        // Default payment method type to Credit Card
        String paymentMethodType = 'Credit Card';
          
        // Retrieve the quote and set the payment method type based on the quote's payment method
        //zqu__Quote__c quote = (zqu__Quote__c)standardController.getRecord();
        if(thisQuote != null) {
          if(thisQuote.zqu__PaymentMethod__c == 'ACH') paymentMethodType = 'ACH';
          else if(thisQuote.zqu__PaymentMethod__c == 'Wire Transfer') paymentMethodType = 'Bank Transfer';
        }
      
        // Query for settings
        List < zqu__HostedPageLiteSetting__c > settingList = [SELECT zqu__PageId__c, zqu__PaymentMethodType__c, zqu__ComponentName__c FROM zqu__HostedPageLiteSetting__c WHERE zqu__PaymentMethodType__c = :paymentMethodType LIMIT 1];
          
        if(settingList != null && !settingList.isEmpty()) {
            pageId = settingList[0].zqu__PageId__c;
        }
    }

}