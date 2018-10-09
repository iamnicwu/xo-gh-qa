public class PaymentSchBreakdownController {
    private static final STRING QUOTE_QUERY = 'SELECT '
                                                +   'Id, '
                                                +   'True_TCV_JSON_Response__c, '
                                                +   'zqu__BillCycleDay__c, '
                                                +   'zqu__SubscriptionType__c, '
                                                +   'zqu__SubscriptionTermStartDate__c, '
                                                +   'zqu__SubscriptionTermEndDate__c, '
                                                +   'zqu__TermStartDate__c, '
                                                +   'zqu__InitialTerm__c, '
                                                +   'Preferred_Payment_Schedule__c, '
                                                +   'Product_Line__c, '
                                                +   'zqu__PaymentMethod__c '
                                                +   ' FROM '
                                                +   'zqu__Quote__c'
                                                +   ' WHERE '
                                                +   '{WHERECLAUSE}';

    public List<BreakDownWrapper> breakdownWrapperList {get; private set;}
    
    public PaymentSchBreakdownController() {
    }

    // this method is for parsing the payment schedule breakdown which is in the form of a json
    public void parseJSONPaymentBreakdownString () {
        // Get Quote Id from URL parameters
        Id quoteId = System.currentPagereference().getParameters().get('quoteId'); 

        // TODO: Test what happens when no quote id provided
        if(String.isBlank(quoteId)) {
            return;    
        }

        // Query for Quote record details to be used later
        zqu__Quote__c quote = Database.query(QUOTE_QUERY.replace('{WHERECLAUSE}', 'Id = :quoteId'));
        
        String attName = String.valueOf(quoteId) + 'JSON.txt';

        List<Attachment> jsonAttList = new List<Attachment>();
        // TODO: Test what happens when no True TCV JSON
        // CSP-2667 Adding more than 60 services
        // if the True_TCV_JSON_Response__c is blank, we query the response attachment
        if(String.isBlank(quote.True_TCV_JSON_Response__c) ) {
            jsonAttList = [SELECT Id, Body FROM Attachment WHERE ParentId =: quoteId AND Name = : attName LIMIT 1];

            if (jsonAttList.isEmpty()) {
                return;
            }
        }

        breakdownWrapperList = new List<BreakdownWrapper>();

        // if(String.isNotBlank(quote.True_TCV_JSON_Response__c)) {
        // // if the True_TCV_JSON_Response__c is not blank, we use True_TCV_JSON_Response__c to generate preview file
        if (!jsonAttList.isEmpty() || String.isNotBlank(quote.True_TCV_JSON_Response__c)) {
            List<InvoiceItems> jsonInvoiceItems = new List<InvoiceItems>();
            if (String.isNotBlank(quote.True_TCV_JSON_Response__c)) {
                ZuoraSubscPreview jsonSubPreview = (PaymentSchBreakDownController.ZuoraSubscPreview)JSON.deserialize(quote.True_TCV_JSON_Response__c, PaymentSchBreakDownController.ZuoraSubscPreview.class);
                jsonInvoiceItems = jsonSubPreview.invoiceItems;
            }else{
                ZuoraSubscPreview jsonSubPreview = (PaymentSchBreakDownController.ZuoraSubscPreview)JSON.deserialize(jsonAttList[0].Body.toString(), PaymentSchBreakDownController.ZuoraSubscPreview.class);
                jsonInvoiceItems = jsonSubPreview.invoiceItems;
            }
            // List<InvoiceItems> jsonInvoiceItems = jsonSubPreview.invoiceItems;
            // CSP-2472 - Sort based on serviceStartDate
            jsonInvoiceItems.sort();
            System.debug(LoggingLevel.INFO, '***jsonInvoiceItems : ' + jsonInvoiceItems);
            Map<String, zqu__ProductRatePlanCharge__c> zuoraIdToProductRatePlanChargeMap = retrieveRatePlanCharges(jsonInvoiceItems);

            Date subscriptionStartDate = quote.zqu__TermStartDate__c;
            // CSP-2472
            if(!jsonInvoiceItems.isEmpty()) {
                InvoiceItems firstInvoiceItem = jsonInvoiceItems[0];
                if(firstInvoiceItem.serviceStartDate < subscriptionStartDate && firstInvoiceItem.serviceStartDate < subscriptionStartDate.addMonths(-1)) {
                    subscriptionStartDate = subscriptionStartDate.addMonths(-1);
                }
            }

            Date subscriptionEndDate;
            if(quote.zqu__SubscriptionTermEndDate__c != null) {
                subscriptionEndDate = quote.zqu__SubscriptionTermEndDate__c;
            } else {
                subscriptionEndDate = quote.zqu__TermStartDate__c.addMonths(Integer.valueOf(quote.zqu__InitialTerm__c));
            }

            // BillCycleDay is stored in a picklist as a string
            Date bcdAlignmentDate = Date.newInstance(subscriptionStartDate.year(), subscriptionStartDate.month(), Integer.valueOf(quote.zqu__BillCycleDay__c));
            
            while(bcdAlignmentDate <= subscriptionEndDate) {
                List<InvoiceItems> bcdInvoiceItemList = new List<InvoiceItems>();
                Decimal grandTotal = 0;

                for(Integer i = 0; i < jsonInvoiceItems.size(); i++) {
                    InvoiceItems currentInvoiceItem = jsonInvoiceItems[i];
                    System.debug('II -> ' + currentInvoiceItem);
                    if(currentInvoiceItem.serviceStartDate <= bcdAlignmentDate) {
                        if(zuoraIdToProductRatePlanChargeMap.containsKey(currentInvoiceItem.productRatePlanChargeId)) {
                            zqu__ProductRatePlanCharge__c currentProductRatePlanCharge = zuoraIdToProductRatePlanChargeMap.get(currentInvoiceItem.productRatePlanChargeId);
                            currentInvoiceItem.productRatePlanName = currentProductRatePlanCharge.zqu__ProductRatePlan__r.Name;

                            // CSP-2355 - Do not show service periods for Print or Direct Mail
                            if(currentProductRatePlanCharge.zqu__ProductRatePlan__r.Product_Line__c.equals('Print') || currentProductRatePlanCharge.zqu__ProductRatePlan__r.Product_Line__c.equals('Direct Mail')) {
                                currentInvoiceItem.serviceStartDate = null;
                                currentInvoiceItem.serviceEndDate = null;
                            }
                        }
                        grandTotal += currentInvoiceItem.chargeAmount;
                        bcdInvoiceItemList.add(currentInvoiceItem);
                        jsonInvoiceItems.remove(i);
                        i--;
                    }
                }

                if(!bcdInvoiceItemList.isEmpty()) {
                    Date dueDate = bcdAlignmentDate;
                    // Requirement for Check customers to have a Due Date 30 days from their Invoice Date
                    if(quote.zqu__PaymentMethod__c == 'Check') {
                        dueDate = dueDate.addDays(30);
                    }

                    breakdownWrapperList.add(new BreakDownWrapper(dueDate, quote.Preferred_Payment_Schedule__c, bcdInvoiceItemList, grandTotal));
                }

                bcdAlignmentDate = bcdAlignmentDate.addMonths(1);
            }
        }
    }

    /**
     *   Method used to retrieve related Rate Plan Charges to get the rate plan name for display user
     *
     *   @author Justin
     *   @date   2017-06-27
     *   @param  {List<InvoiceItems>}         currentInvoiceItemList           The list of invoice items to get the rate
     *                                                                         plan charge id values
     *   @return {Map<String, zqu__ProductRatePlanCharge__c>}                  The Map which is built that has the Zuora
     *                                                                         Id as the primary key.
     */
    private static Map<String, zqu__ProductRatePlanCharge__c> retrieveRatePlanCharges(List<InvoiceItems> currentInvoiceItemList) {
        Map<String, zqu__ProductRatePlanCharge__c> zuoraIdToProductRatePlanChargeMap = new Map<String, zqu__ProductRatePlanCharge__c>();
        // If the currentInvoiceItemList is empty then there is nothing to try and build...
        if(currentInvoiceItemList.isEmpty()) {
            return zuoraIdToProductRatePlanChargeMap;
        }

        Set<String> productRatePlanChargeIdSet = new Set<String>();

        // Loop through all InvoiceItems and grab the productRatePlanChargeId Ids
        for(Integer i = 0; i < currentInvoiceItemList.size(); i++) {
            InvoiceItems currentInvoiceItem = currentInvoiceItemList[i];
            // If the Product Rate Plan Charge Id is blank OR the set has the value already, continue to next iteration
            if(String.isBlank(currentInvoiceItem.productRatePlanChargeId) || productRatePlanChargeIdSet.contains(currentInvoiceItem.productRatePlanChargeId)) {
                continue;
            }

            productRatePlanChargeIdSet.add(currentInvoiceItem.productRatePlanChargeId);
        }

        // Query the needed data which will be returned as the value in the map
        List<zqu__ProductRatePlanCharge__c> productRatePlanChargeList = [SELECT Id, zqu__ProductRatePlan__r.Name, zqu__ProductRatePlan__r.Product_Line__c, zqu__ZuoraId__c FROM zqu__ProductRatePlanCharge__c WHERE zqu__ZuoraId__c IN :productRatePlanChargeIdSet];

        // Use a FOR loop to build the map as we are not setting the map key with the Salesforce Id but rather the
        // Zuora external Id
        for(Integer i = 0; i < productRatePlanChargeList.size(); i++) {
            zqu__ProductRatePlanCharge__c currentProductRatePlanCharge = productRatePlanChargeList[i];
            zuoraIdToProductRatePlanChargeMap.put(currentProductRatePlanCharge.zqu__ZuoraId__c, currentProductRatePlanCharge);
        }

        return zuoraIdToProductRatePlanChargeMap;
    }

    // Object used to tie front end data together for display
    public class BreakdownWrapper {
        public Date dueDate {get; private set;}
        public Decimal total {get; private set;}
        public String billingTerm {get; private set;}
        public List<InvoiceItems> invoiceItems {get; private set;}

        public BreakdownWrapper(Date setDueDate, String preferredPaymentSchedule, InvoiceItems newInvoiceItem) {
            dueDate = setDueDate;
            billingTerm = preferredPaymentSchedule;
            total = newInvoiceItem.chargeAmount;
            invoiceItems = new List<InvoiceItems>{newInvoiceItem};
        }

        public BreakdownWrapper(Date setDueDate, String preferredPaymentSchedule, List<InvoiceItems> newInvoiceItemsList, Decimal totalAmount) {
            dueDate = setDueDate;
            billingTerm = preferredPaymentSchedule;
            total = totalAmount;
            invoiceItems = newInvoiceItemsList;
        }
    }

    // Inner class which is used for serialization by readValuesAs. The entire json string(payload consisting of paymnet schedule
    // breakdown as per service periods) is parsed into an object which is instance of ZuoraSubscPreview in this case.
    public class ZuoraSubscPreview {
        public Boolean success {get; set;}    
        public List<InvoiceItems> invoiceItems {get; set;}
        
        public ZuoraSubscPreview(List<InvoiceItems> invItems, Boolean flag) {
            invoiceItems = invItems;
            success = flag;
        }
    }

    public class InvoiceItems implements Comparable {
        public Date serviceStartDate {get; set;}
        public Date serviceEndDate {get; set;}
        public Decimal chargeAmount {get; set;}
        public String chargeName {get; set;}
        public String productRatePlanChargeId {get; set;}
        public String productRatePlanName {get; set;} //ProductRatePlanName__c

        // CSP-2472 - Added the comparable implementation to sort invoice items based on serviceStartDate
        public Integer compareTo(Object compareTo) {
            InvoiceItems compareInvoiceItem = (InvoiceItems)compareTo;

            if(serviceStartDate == compareInvoiceItem.serviceStartDate) {
                return 0;
            }

            if(serviceStartDate > compareInvoiceItem.serviceStartDate) {
                return 1;
            }

            return -1;
        }
    }
}