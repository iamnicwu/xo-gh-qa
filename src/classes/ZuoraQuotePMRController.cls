/* 
<class>
  <name>ZuoraQuotePMRController</name>
  <purpose>Redirects user to either Payment Method form or Quote record depending on
  where or not the Quote is for a new Billing Account</purpose>
  <created>
    <by>Jonathan Satterfield & Hari Mohan</by>
    <date>7/29/2015</date>
    <ticket>SF-714, SF-715</ticket>
  </created>
</class>
*/
public with sharing class ZuoraQuotePMRController {
    public Id quoteId {get;set;}
    public Id oppId {get;set;}
    public String paymentType {get;set;}
    public String billingAccountID {get;set;}
    public String electronicPaymentID {get;set;}
    public String subscriptionType {get;set;}
    public zqu__Quote__c tempQuote {get;set;}
    
    /* 
    <method>
      <name>ZuoraQuotePMRController</name>
      <purpose>Constructor method</purpose>
      <created>
        <by>Jonathan Satterfield & Hari Mohan</by>
        <date>7/29/2015</date>
        <ticket>SF-714, SF-715</ticket>
      </created>
    </method>
    */ 
    public ZuoraQuotePMRController(ApexPages.StandardController standardController) {

        quoteId = null;
        // Retrieve the quote
        zqu__Quote__c quote = (zqu__Quote__c)standardController.getRecord();
        if(quote != null) {
            quoteId = quote.id;
            tempQuote = [SELECT Id, zqu__SubscriptionType__c, zqu__ZuoraAccountID__c, zqu__Opportunity__c, zqu__PaymentMethod__c, zqu__ElectronicPaymentMethodId__c, zqu__Is_Charge_Expired__c, zqu__Opportunity__r.Date_Client_Approved__c,
                                                zqu__Customer_Acceptance_Date__c, zqu__TermStartDate__c, zqu__SubscriptionTermStartDate__c, zqu__StartDate__c, zqu__Service_Activation_Date__c, zqu__BillCycleDay__c FROM zqu__Quote__c WHERE Id = :quoteId];
            paymentType = tempQuote.zqu__PaymentMethod__c;
            billingAccountID = tempQuote.zqu__ZuoraAccountID__c;
            electronicPaymentID = tempQuote.zqu__ElectronicPaymentMethodId__c;
            oppId = tempQuote.zqu__Opportunity__c;
            subscriptionType = tempQuote.zqu__SubscriptionType__c;
        }
    }

    
    public ApexPages.PageReference updateDiscountsRunLocalProductRulesAndRedirect() {
        if (subscriptionType != 'Cancel Subscription') {
            updateDiscounts();
            // (SF-2036) this boolean needs to be set in order to run the zqu.zQuoteUtil.previewQuotes method on the ChooseNextAction page
            tempQuote.zqu__Is_Charge_Expired__c = True;
            List<zqu__Quote__c> qList = new List<zqu__Quote__c>();
            qList.add(tempQuote);
            OpportunitySendToZBillingController.SetQuoteDates(qList);
            update qList;
        }
        return redirect();
    }



    /* 
    <method>
      <name>redirect</name>
      <purpose>Redirects user to either Payment Method form or Quote record depending on
        where or not the Quote is for a new Billing Account</purpose>
      <created>
        <by>Jonathan Satterfield & Hari Mohan</by>
        <date>7/29/2015</date>
        <ticket>SF-714, SF-715</ticket>
      </created>
    </method>
    */
    public ApexPages.PageReference redirect() {
        // if new billing account and not a Check, return payment page if they have not entered a billing account or entered their payment ID
        if (
               (billingAccountID == null || billingAccountID == '') 
            && (electronicPaymentID == null || electronicPaymentID == '') 
            && (paymentType == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_CREDIT_CARD 
                || paymentType == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH)
           )
        {
            return new PageReference('/apex/CreateNewPaymentMethod?id='+(String)quoteId+'&quoteType=Subscription&stepNumber=5');
        }
        // if existing billing account, redirect to Choose Next Action page
        else {
            return new PageReference('/apex/ZuoraQuoteChooseNextAction?id='+(String)quoteId+'&oppId='+(String)oppId+'&quoteType=Subscription&stepNumber=6');
        }
    }



    public void updateDiscounts() {
    
        // the DiscountOverrideModified__c boolean is set to true to maintain the new Discount_Override__c value between page loads
        // (otherwise the Discount_Override__c field is set to the value that Steelbrick calculated)
        // this boolean is reset to False after the page reloads

        String theQuoteId = String.valueOf(quoteId).left(15);
        List<zqu__QuoteRatePlanCharge__c> quoteRatePlanCharges = [SELECT Id, Quote_Id__c, Discount_Override__c, zqu__Discount__c, Product_Type__c FROM zqu__QuoteRatePlanCharge__c WHERE Quote_Id__c = :theQuoteId];
        if (!quoteRatePlanCharges.isEmpty()) {
            
            Boolean returnNullFlag = False;

            Map<Id,String> qrpcIdToDiscountOverrideStringMap = new Map<Id,String>();

            String productLine;

            for (zqu__QuoteRatePlanCharge__c chargeRecord : quoteRatePlanCharges) {
                qrpcIdToDiscountOverrideStringMap.put(String.valueOf(chargeRecord.Id).left(15),String.valueOf(chargeRecord.Discount_Override__c));
                //qrpcIdToDiscountOverrideStringMap.put(String.valueOf(chargeRecord.Id).left(15),String.valueOf(chargeRecord.zqu__Discount__c));

                if (String.isBlank(productLine)) {
                    productLine = chargeRecord.Product_Type__c;
                }
            }

            List<zqu.zChargeGroup> chargeGroupsToUpdate = new List<zqu.zChargeGroup>();
            List<zqu.zChargeGroup> chargeGroups = zqu.zQuoteUtil.getChargeGroups(String.valueOf(quoteId));

            for (zqu.zChargeGroup chargeGroup : chargeGroups) {
                if (chargeGroup.groupType != zqu.zChargeGroup.TYPE_AMENDMENT_REMOVEPRODUCT && chargeGroup.groupType != zqu.zChargeGroup.TYPE_RENEWAL_RENEWED && (chargeGroup.groupType != zqu.zChargeGroup.TYPE_AMENDMENT_ORIGINAL)) {// && productLine != 'Direct Mail')) {
                    for (zqu.zCharge charge : chargeGroup.zCharges) {
                        charge.discount = qrpcIdToDiscountOverrideStringMap.get(String.valueOf(charge.Id).left(15));
                    }
                    chargeGroup.zCharges = zqu.zQuoteUtil.calculateChargesOnDiscountChange(chargeGroup.zCharges);
                    chargeGroupsToUpdate.add(chargeGroup);
                }
            }
            // TODO: put a try/catch block here
            // ex: https://knowledgecenter.zuora.com/CA_Commerce/E_Development_Resources/C_Component_Library/G_Component_Library_Sample_Code/B_Managing_Charges_with_the_Product_Catalog/B_Use_the_Product_Catalog_to_Add%2C_Update%2C_and_Delete_Charges
            
            if (!chargeGroupsToUpdate.isEmpty()) {
                chargeGroupsToUpdate = zqu.zQuoteUtil.updateChargeGroups(chargeGroupsToUpdate);
            }

            // TODO: is this necessary still?
            update quoteRatePlanCharges;
        }
    }    
}