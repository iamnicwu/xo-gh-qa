public with sharing class AccountSummaryController {
    //////////////////////
    // STATIC VARIABLES //
    //////////////////////
    
    // Account Query
    private static final String ACCOUNT_QUERY = 'SELECT '
        +	'Id, '
        +	'Name, '
        +	'Local_Paid_Status__c, '
        +	'Credit_Hold__c, '
        +	'Past_Due_Balance__c, '
        +   'Account_Status__c, '
        +	'Customer_on_Payment_Arrangement__c '
        +	' FROM '
        +	'Account'
        +	' WHERE '
        +	' {WHERECLAUSE} ';
    
    // Billing Account Query
    private static final String BILLING_ACCOUNT_QUERY = 'SELECT '
        +	'Id, '
        +	'Name, '
        + 'Zuora__BillCycleDay__c, '
        +	'Zuora__Status__c, '
        +	'Zuora__Account__r.Local_Paid_Status__c, '
        +   'Zuora__Account__r.Account_Status__c, '
        +	'Zuora__DefaultPaymentMethod__c, '
        +	'Zuora__MRR__c, '
        + '(SELECT '
        +	'Id, '
        +	'Name, '
        +	'Zuora__InvoiceDate__c, '
        +	'Zuora__TotalAmount__c, '
        +   'Zuora__PaymentAmount__c, '
        +   'Zuora__Balance2__c, '
        +	'Zuora__DueDate__c, '
        +   'Promise_to_Pay_Date__c '
        +	' FROM '
        +	' Zuora__ZInvoices__r '
        +	' ORDER BY '
        +	'CreatedDate DESC'
        +	')'
        +	' FROM '
        +	'Zuora__CustomerAccount__c'
        +	' WHERE '
        +	' {WHERECLAUSE} ';
    
    // Subscription Product Charge Query
    private static final String SUBSCRIPTION_PRODUCT_CHARGE_QUERY = 'SELECT '
        +	'Id, '
        +	'Name, '
        + 'Zuora__Subscription__c, '
        +	'Zuora__RatePlanName__c, '
        +	'Zuora__EffectiveStartDate__c, '
        +	'Zuora__EffectiveEndDate__c, '
        +	'Gross_Total__c, '
        +	'Discount_Total__c, '
        +	'Zuora__Price__c, '
        +	'Quote_Rate_Plan_ID__c, '
        +	'Product_Type__c, '
        +	'LocationVendorDynamicsAccountID__c, '
        // Market and Category fields used to display on the 
        // front end when no Quote exists.
        +	'Market_ID__c, '
        +	'Category_Taxonomy_ID__c, '
        +	'Zuora__Subscription__r.Name, '
        +	'Zuora__Subscription__r.Zuora__ContractEffectiveDate__c, '
        +	'Zuora__Subscription__r.Zuora__TermStartDate__c, '
        +	'Zuora__Subscription__r.Zuora__TermEndDate__c, '
        +   'LDE_Email_Launch_Date__c,'
        +	'Zuora__Subscription__r.True_Subscription_Status__c '
        +	' FROM '
        +	'Zuora__SubscriptionProductCharge__c'
        +	' WHERE '
        +	' {WHERECLAUSE} '
        +	' AND '
        +	'Name not in (\'Charge #01\',\'Charge #02\',\'Charge #03\',\'Charge #04\',\'Charge #05\',\'Charge #06\',\'Charge #07\',\'Charge #08\',\'Charge #09\',\'Charge #10\',\'Charge #11\',\'Charge #12\',\'80% Balance Due\')'
        + ' ORDER BY '
        + 'Zuora__Subscription__r.True_Subscription_Status__c';
    
    // Quote Rate Plan Query																										
    private static final String QUOTE_RATE_PLAN_QUERY = 'SELECT '
        +	'Id, '
        +	'Name, '
        +	'zqu__ProductRatePlan__r.Category__c, '
        +	'zqu__ProductRatePlan__r.Market__c, '
        + 'zqu__Quote__r.zqu__Opportunity__c '
        +	' FROM '
        +	'zqu__QuoteRatePlan__c'
        +	' WHERE '
        +	' {WHERECLAUSE} ';
    
    // Market Query
    private static final String MARKET_QUERY = 	'SELECT '
        +	'Id, '
        +	'Name, '
        +	'Zuora_Description__c, '
        +	'Market_ID__c '
        +	' FROM '
        +	'Market__c'
        +	 ' WHERE '
        +	'{WHERECLAUSE}';
    
    // Category Query
    private static final String CATEGORY_QUERY = 	'SELECT '
        +	'Id, '
        +	'Name, '
        +	'Zuora_Description__c, '
        +	'Taxonomy_ID__c '
        +	' FROM '
        + 'Category__c'
        + ' WHERE '
        +	'{WHERECLAUSE}';																																							
    
    // Subscription ACTIVE filter
    private static final String SUB_ACTIVE_FILTER = ' Zuora__Subscription__r.True_Subscription_Status__c = \'Active\'';
    
    // Subscription COMPLETED filter
    private static final String SUB_COMPLETED_FILTER = ' Zuora__Subscription__r.True_Subscription_Status__c = \'Expired\'';
    
    // Subscription CANCELLED filter
    private static final String SUB_CANCELLED_FILTER = ' Zuora__Subscription__r.True_Subscription_Status__c = \'Cancelled\'';
    
    // Subscription LAST 90 filter
    private static final String SUB_COMPLETED_LAST_90_FILTER = ' Zuora__Subscription__r.Zuora__TermStartDate__c >= {90DAYS}';
    
    // Subscription filter map
    private static final Map<String, String> SUB_FILTER_MAP 
        = new Map<String, String>{'all' => '',
            'active' => SUB_ACTIVE_FILTER,
            'cancelled' => SUB_CANCELLED_FILTER,
            'canceledlast90' => SUB_CANCELLED_FILTER + ' AND ' + SUB_COMPLETED_LAST_90_FILTER,
            'completed' => SUB_COMPLETED_FILTER,
            'completedlast90' => SUB_COMPLETED_FILTER + ' AND ' + SUB_COMPLETED_LAST_90_FILTER};
                
                /**
*   Main function/method used to grab summary data for display on the front end. This retrieves data on a specific
*   Account based upon an Id specificed as a parameter. Billing Accounts and Subscriptions are also pulled as related
*   information about this Account. Subscriptions have a status filter which is used to filter the type of subscriptions
*   which are being displayed on the front end.
*
*   @author Justin
*   @date   2016-05-04
*   @param  {String}         accountId    The Account Id which is used to query all Account Information
*   @param  {String}         statusFilter The status filter which is used to filter subscription data being retrieved.
*   @return {Map<String, Object>}         A map object which is returned with a key to compelx object. The keys for
*                                         this map are: Account, Billing, Subscriptions, Markets, and Categories.
*/
                @AuraEnabled
                public static Map<String, Object> getSummaryData(String accountId, String statusFilter) {
                    if(String.isBlank(accountId)) {
                        return null;
                    }
                    
                    Map<String, Object> response = new Map<String, Object>();
                    
                    response.put('Account', getAccount(accountId));
                    response.putAll(getSubscriptionProducts(accountId, statusFilter));
                    response.put('Billing', getBillingAccounts(accountId));
                    
                    return response;
                }
    
    /**
*   Function/method used to retrieve the main Account object using a provided Account Id. This method utilizes a dynamic
*   query which is a static final variable of this class.
*
*   @author Justin
*   @date   2016-05-04
*   @param  {String}      accountId The Account Id which is used to query Account information
*   @return {AccountData}           The object which holds all Account information. This object is not the default
*                                   Account object but instead a complex object(wrapper class).
*/
    private static AccountData getAccount(String accountId) {
        String accountQuery = ACCOUNT_QUERY;
        accountQuery = accountQuery.replace('{WHERECLAUSE}', 'Id = \'' + accountId + '\'');
        
        Account currentAccount = Database.query(accountQuery);
        
        AccountData currentAccountData = new AccountData(currentAccount);
        currentAccountData.creditStatus = determineCreditStatus(currentAccount);
        
        return currentAccountData;
    }
    
    /**
*   Function/method used to determine the credit status given a specific Account. The Account object uses checkboxes
*   to flag credit statuses which requires additional logic to display a string representation of this information.
*
*   @author Justin
*   @date   2016-05-04
*   @param  {Account}   currentAccount The Account object which has the needed fields to determine the credit status.
*   @return {String}                   The string representation of the determined credit status.
*/
    private static String determineCreditStatus(Account currentAccount) {
        if(currentAccount.Credit_Hold__c) {
            return 'Credit Hold';
        } else if (currentAccount.Customer_on_Payment_Arrangement__c) {
            return 'Payment Arrangement';
        } else {
            return 'Good';
        }
    }
    
    /**
*   Function/method used to get all ACTIVE billing accounts related to a specific parent account. An Account Id is 
*   provided which is then used to query all child records needed.
*
*   @author Justin
*   @date   2016-05-04
*   @param  {String}                          accountId The Account Id which is used to get all Billing Accounts
*   @return {List<Zuora__CustomerAccount__c>}           The Billing Accounts(Zuora__CustomerAccount__c) records which
*                                                       are a child of the provided account.
*/
    private static List<Zuora__CustomerAccount__c> getBillingAccounts(String accountId) {
        String billingQuery = BILLING_ACCOUNT_QUERY;
        billingQuery = billingQuery.replace('{WHERECLAUSE}', 'Zuora__Account__c = \'' + accountId + '\' AND Zuora__Status__c = \'Active\'');
        
        List<Zuora__CustomerAccount__c> billingAccountList = Database.query(billingQuery);
        
        return billingAccountList;
    }
    
    /**
*   Function/method used to get the status filter from the status filter map within this class.
*
*   @author Justin
*   @date   2016-05-04
*   @param  {String}   statusFilter The selected status filter which was selected on the front end UI
*   @return {String}                The dynamic query string addition which was built within this function/method
*                                   that was determine by the supplied status filter.
*/
    private static String getStatusFilter(String statusFilter) {
        if(String.isBlank(statusFilter) || statusFilter == 'All' || !SUB_FILTER_MAP.containsKey(statusFilter)) {
            return '';
        }
        
        String queryFilter = ' AND ' + SUB_FILTER_MAP.get(statusFilter);
        
        // If the selected status filter is using a 90 day filter appropriately add the Date dynamic query filter
        if(queryFilter.indexOf('{90DAYS}') > -1) {
            String filterDate = DateTime.newInstance(Date.today().addDays(-90), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
            queryFilter = queryFilter.replace('{90DAYS}', filterDate);
        }
        
        return queryFilter;
    }
    
    private static Map<String, Object> getSubscriptionProducts(String accountId, String statusFilter) {
        List<SubscriptionData> subDataList = new List<SubscriptionData>();
        List<Zuora__SubscriptionProductCharge__c> subProdList;
        Set<String> marketNames = new Set<String>();
        Set<String> categoryNames = new Set<String>();
        Map<String, Market__c> marketMap;
        Map<String, Category__c> categoryMap;
        Map<String, zqu__QuoteRatePlan__c> quoteRatePlanMap = new Map<String, zqu__QuoteRatePlan__c>();
        Map<String, echosign_dev1__SIGN_Agreement__c> oppToAgreementMap = new Map<String, echosign_dev1__SIGN_Agreement__c>();
        
        
        String subProdQuery = SUBSCRIPTION_PRODUCT_CHARGE_QUERY;
        subProdQuery = subProdQuery.replace('{WHERECLAUSE}', 
                                            'Zuora__Subscription__r.Zuora__Account__c = \'' + accountId + '\''
                                            +	getStatusFilter(statusFilter));
        
        subProdList = Database.query(subProdQuery);
        
        Set<String> quoteRatePlanIdSet = new Set<String>();
        Set<String> marketIdSet = new Set<String>();
        Set<String> categoryIdSet = new Set<String>();
        for(Integer i = 0; i < subProdList.size(); i++) {
            Zuora__SubscriptionProductCharge__c currentProdCharge = subProdList[i];
            if(String.isNotBlank(currentProdCharge.Quote_Rate_Plan_ID__c)) {
                quoteRatePlanIdSet.add(currentProdCharge.Quote_Rate_Plan_ID__c);
            } 
            
            if(String.isNotBlank(currentProdCharge.Market_ID__c)) {
                marketIdSet.add(currentProdCharge.Market_ID__c);
            }
            
            if(String.isNotBlank(currentProdCharge.Category_Taxonomy_ID__c)) {
                categoryIdSet.add(currentProdCharge.Category_Taxonomy_ID__c);
            }
        }
        
        if(quoteRatePlanIdSet.size() > 0) {
            String qrpQuery = QUOTE_RATE_PLAN_QUERY;
            qrpQuery = qrpQuery.replace('{WHERECLAUSE}', 'Id IN :quoteRatePlanIdSet');
            quoteRatePlanMap = new Map<String, zqu__QuoteRatePlan__c>();
            List<zqu__QuoteRatePlan__c> qrpList = Database.query(qrpQuery);
            Set<String> opportunityIdSet = new Set<String>();
            for(Integer i = 0; i < qrpList.size(); i++) {
                zqu__QuoteRatePlan__c currentQRP = qrpList[i];
                quoteRatePlanMap.put(currentQRP.Id, currentQRP);
                if(String.isNotBlank(currentQRP.zqu__Quote__c) && String.isNotBlank(currentQRP.zqu__Quote__r.zqu__Opportunity__c)) {
                    opportunityIdSet.add(currentQRP.zqu__Quote__r.zqu__Opportunity__c);
                }
            }
            
            // Loop through signed agreements using the retrieved opportunity Id
            if(opportunityIdSet.size() > 0) {
                List<echosign_dev1__SIGN_Agreement__c> agreementList = 	[SELECT 
                                                                         Id, 
                                                                         echosign_dev1__Opportunity__c, 
                                                                         echosign_dev1__Status__c, 
                                                                         echosign_dev1__Document__c 
                                                                         FROM 
                                                                         echosign_dev1__SIGN_Agreement__c 
                                                                         WHERE 
                                                                         echosign_dev1__Opportunity__c IN :opportunityIdSet 
                                                                         AND 
                                                                         echosign_dev1__Status__c = 'Signed'];
                
                for(Integer i = 0; i < agreementList.size(); i++) {
                    echosign_dev1__SIGN_Agreement__c currentAgreement = agreementList[i];
                    oppToAgreementMap.put(currentAgreement.echosign_dev1__Opportunity__c, currentAgreement);
                }
            }
        }
        
        // Generate market and category maps for Subscription Product & Charges without a quote related
        marketMap = retrieveMarketMap(marketIdSet);
        categoryMap = retrieveCategoryMap(categoryIdSet);
        
        
        
        // Loop through all subscription product charges and associate data using a wrapper class and bulkified maps
        for(Integer i = 0; i < subProdList.size(); i++) {
            Zuora__SubscriptionProductCharge__c currentProdCharge = subProdList[i];
            zqu__QuoteRatePlan__c currentQRP;
            echosign_dev1__SIGN_Agreement__c currentAgreement;
            if(String.isNotBlank(currentProdCharge.Quote_Rate_Plan_ID__c) && quoteRatePlanMap.containsKey(currentProdCharge.Quote_Rate_Plan_ID__c)) {
                currentQRP = quoteRatePlanMap.get(currentProdCharge.Quote_Rate_Plan_ID__c);
                if(oppToAgreementMap.containsKey(currentQRP.zqu__Quote__r.zqu__Opportunity__c)) {
                    currentAgreement = oppToAgreementMap.get(currentQRP.zqu__Quote__r.zqu__Opportunity__c);
                }
            } else {
                currentQRP = new zqu__QuoteRatePlan__c();
                currentAgreement = new echosign_dev1__SIGN_Agreement__c();
            }
            
            // If the provided quote does not have the correct lookup relation then create a relation to display market and
            // category. This is possible when a Rate Plan was not populated on a related quote or a quote did not exist in
            // the system for the current Subscription Product and Charge
            if(currentQRP.zqu__ProductRatePlan__r == null) {
                currentQRP.zqu__ProductRatePlan__r = new zqu__ProductRatePlan__c();
                if(marketMap.containsKey(currentProdCharge.Market_ID__c)) {
                    Market__c currentMarket = marketMap.get(currentProdCharge.Market_Id__c);
                    currentQRP.zqu__ProductRatePlan__r.Market__c = currentMarket.Zuora_Description__c;
                }
                
                if(categoryMap.containsKey(currentProdCharge.Category_Taxonomy_ID__c)) {
                    Category__c currentCategory = categoryMap.get(currentProdCharge.Category_Taxonomy_ID__c);
                    currentQRP.zqu__ProductRatePlan__r.Category__c = currentCategory.Zuora_Description__c;
                }
            }
            
            if(String.isNotBlank(currentQRP.zqu__ProductRatePlan__r.Market__c)) {
                marketNames.add(currentQRP.zqu__ProductRatePlan__r.Market__c);
            }
            
            if(String.isNotBlank(currentQRP.zqu__ProductRatePlan__r.Category__c)) {
                categoryNames.add(currentQRP.zqu__ProductRatePlan__r.Category__c);
            }
            
            subDataList.add(new SubscriptionData(currentProdCharge, currentQRP, currentAgreement));
        }
        
        // Store as a list to sort
        List<String> marketNamesSorted = new List<String>(marketNames);
        marketNamesSorted.sort();
        // Store as a list to sort
        List<String> categoryNamesSorted = new List<String>(categoryNames);
        categoryNamesSorted.sort();
        
        return new Map<String, Object>{'Subscriptions' => subDataList,
            'Markets' => marketNamesSorted,
            'Categories' => categoryNamesSorted};
                }
    
    /**
*   Function/method used to retrieve Market records given a set of external market IDs. This is used specifically
*   because a Market Lookup does not exist so a secondary query is needed to tie the data together.
*
*   @author Justin
*   @date   2016-05-04
*   @param  {Set<String>}         marketExtIdSet A set of external market Id's which were retrieved from a related
*                                                (non-relational) object.
*   @return {Map<String, Market__c>}             A map of Market External Id => Market Records.
*/
    private static Map<String, Market__c> retrieveMarketMap(Set<String> marketExtIdSet) {
        Map<String, Market__c> marketMap = new Map<String, Market__c>();
        if(marketExtIdSet == null || marketExtIdSet.size() < 1) {
            return marketMap;
        }
        
        String marketQuery = MARKET_QUERY;
        marketQuery = marketQuery.replace('{WHERECLAUSE}', ' Market_ID__c IN :marketExtIdSet ');
        
        List<Market__c> marketList = Database.query(marketQuery);
        for(Integer i = 0; i < marketList.size(); i++) {
            Market__c currentMarket = marketList[i];
            if(String.isBlank(currentMarket.Market_ID__c)) {
                continue;
            }
            
            marketMap.put(currentMarket.Market_ID__c, currentMarket);
        }
        
        return marketMap;
    }
    
    /**
*   Function/method used to retrieve Category records given a set of external category IDs. This is used specifically
*   because a Category lookup does not exist so a secondary query is needed to tie the data together.
*
*   @author Justin
*   @date   2016-05-04
*   @param  {Set<String>}         categoryTaxIdSet A set of external category ID's which were retrieved from a related
*                                                  (non-relational) object.
*   @return {Map<String, Category__c>}             A map of Category Market Id => Category Records.
*/
    private static Map<String, Category__c> retrieveCategoryMap(Set<String> categoryTaxIdSet) {
        Map<String, Category__c> categoryMap = new Map<String, Category__c>();
        if(categoryTaxIdSet == null || categoryTaxIdSet.size() < 1) {
            return categoryMap;
        }
        
        String categoryQuery = CATEGORY_QUERY;
        categoryQuery = categoryQuery.replace('{WHERECLAUSE}', ' Taxonomy_ID__c IN :categoryTaxIdSet ');
        
        List<Category__c> categoryList = Database.query(categoryQuery);
        for(Integer i = 0; i < categoryList.size(); i++) {
            Category__c currentCategory = categoryList[i];
            if(String.isBlank(currentCategory.Taxonomy_ID__c)) {
                continue;
            }
            
            categoryMap.put(currentCategory.Taxonomy_ID__c, currentCategory);
        }
        
        return categoryMap;
    }
    
    /**
*   AccountData complex object(wrapper class) used to hold Account data information. This object is specifically used
*   to store the String representation of the credit status. This could grow if requirements grow/expand to include more
*   data about an Account.
*/
    public class AccountData {
        @AuraEnabled
        public Account accountInfo;
        @AuraEnabled
        public String creditStatus;
        
        public AccountData() {
            accountInfo = new Account();
            creditStatus = null;
        }
        
        public AccountData(Account currentAccount) {
            accountInfo = currentAccount;
        }
    }
    
    /**
*   SubscriptionData complex object(wrapper class) used to hold Subscription data information. This object is used to
*   relate data together about a Subscription.
*/
    public class SubscriptionData {
        @AuraEnabled
        public Zuora__SubscriptionProductCharge__c subProdCharge;
        @AuraEnabled
        public zqu__QuoteRatePlan__c quoteRatePlan;
        @AuraEnabled
        public echosign_dev1__SIGN_Agreement__c agreement;
        
        public SubscriptionData(Zuora__SubscriptionProductCharge__c currentSubProdCharge, zqu__QuoteRatePlan__c currentQRP, echosign_dev1__SIGN_Agreement__c currentAgreement) {
            subProdCharge = currentSubProdCharge;
            quoteRatePlan = currentQRP;
            agreement = currentAgreement;
        }
    }
}