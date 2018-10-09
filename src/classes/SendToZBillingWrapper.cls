public class SendToZBillingWrapper {

    // can't serialize managed package objects,
    // so instead had to create our own wrapper class that stores the quote
    // values we need to build the request, and then create ZBillingQuoteCollection /
    // zqu.zQuoteUtil.ZBillingQuoteRequest objects on the fly right before sending to ZBilling

    public Id oppId {get; set;}
    public List<QuoteWrapper> readyToSend {get; set;}
    public List<QuoteWrapper> successfullySent {get; set;}
    public List<QuoteWrapper> failedToSend {get; set;}

    public SendToZBillingWrapper() {
        this.readyToSend = new List<QuoteWrapper>();
        this.successfullySent = new List<QuoteWrapper>();
        this.failedToSend = new List<QuoteWrapper>();
    }


    public class QuoteWrapper {

        // zqu.zQuoteUtil.ZBillingQuoteCollection fields
        public Id sfdcAccountId {get; set;}
        public String zAccountId {get; set;}
        // zqu.zQuoteUtil.ZBillingQuoteRequest fields
        public Id sfdcQuoteId {get; set;}
        public String electronicPaymentMethodId {get; set;}
        public Boolean processPayment {get; set;}
        public String zBillingResultMessage {get; set;}
        public Boolean zBillingResultSuccess {get; set;}
        public Id oppOwnerId {get; set;}
        public Id oppId {get; set;}

        //CSP-2563 new set store quote id and quote payment method .  
        public set<Id> alreadyToSendId {get; set;} 
        public String paymentMethod {get; set;}

        public QuoteWrapper() {
        }
    }

}