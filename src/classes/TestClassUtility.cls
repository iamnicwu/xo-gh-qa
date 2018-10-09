public without sharing class TestClassUtility {

  public static Boolean DISABLE_TRIGGERS = false;

  public static final Set<String> DISABLED_OBJECT_TRIGGERS;

  public static Lead createLead(Boolean insertRecord) {
    Lead testLead = new Lead();
    testLead.FirstName = 'Test';
    testLead.LastName = 'Lead' + randomNumber(9999);
    testLead.Company = 'Testing Company';
    testLead.Website = generateRandomWebsite();
    testLead.Email = generateRandomEmail();
    testLead.PostalCode = '12121';
    testLead.Country = 'United States';
    testLead.LeadSource = 'Website';
    testLead.City = 'test City';
    testLead.State = 'Texas';
    testLead.Phone = '1234567890';
    if(insertRecord) {
      insert testLead;
    }
    return testLead;
  }

  public static Lead createLead(Boolean insertRecord, Market__c testMarket, Category__c testCategory) {
      Lead testLead = createLead(false);
      testLead.Local_Sales_Market__c = testMarket.id;
      testLead.Primary_Category__c = testCategory.id;
      // CSP-1999 testLead.Primary_Brand__c = testBrand.id;
      
      if(insertRecord) {
          insert testLead;
      }

      return testLead;
  }
  /**
   *   Test method used to create an Account record with test data.
   *
   *   @author Justin
   *   @date   2016-05-23
   *   @param  {Boolean}   insertRecord Boolean parameter to determine if this record should be inserted into the
   *                                    system during the method execution.
   *   @return {Account}                The created test data Account record which was created.
   */
  public static Account createAccount(Boolean insertRecord) {
    Account testAccount = new Account();

    testAccount.Name = 'TestAccount' + randomNumber(9999);
    testAccount.BillingCity = 'Austin';
    testAccount.BillingState = 'Texas';
    testAccount.BillingCountry = 'United States';
    testAccount.BillingPostalCode = generateRandomUSPostalCode();
    testAccount.BillingStreet = generateRandomStreet();
    testAccount.shippingCountry = 'United States';
    testAccount.shippingState = 'Texas';
    testAccount.shippingCity = 'Austin';
    testAccount.shippingStreet = generateRandomStreet();
    testAccount.shippingPostalCode = generateRandomUSPostalCode();
        
    testAccount.Phone = randomNumber(9) + '23456789' + randomNumber(9);
    testAccount.Website = generateRandomWebsite();

    // New Addition - Create Dynamics Id
    testAccount.DynamicsAccID__c = '123abc456' + randomNumberBetween(1111, 9999);
    testAccount.AccountSource= 'Field Event';
    if(insertRecord) {
      insert testAccount;
    }

    return testAccount;
  }

  public static Account createAccount(Boolean insertRecord, Category__c associatedCategory, Market__c associatedMarket) {
    Account testAccount = createAccount(false);

    // CSP-1999 testAccount.Primary_Brand__c = associatedBrand.Id;
    testAccount.Primary_Category__c = associatedCategory.Id;
    testAccount.Local_Sales_Market__c = associatedMarket.Id;

    if(insertRecord) {
      insert testAccount;
    }

    return testAccount;
  }

  /**
   *   Test method used to create an Opportunity record with test data.
   *
   *   @author Justin
   *   @date   2016-05-23
   *   @param  {Boolean}   insertRecord Boolean parameter to determine if this record should be inserted into the system
   *                                    during the method execution
   *   @return {Contact}                The created test data Contact record which was created.
   */
  public static Contact createContact(Boolean insertRecord) {
    Contact testContact = new Contact();

    testContact.FirstName = 'Bob' + randomNumber(9);
    testContact.LastName = 'Builder' + randomNumber(9);
    testContact.Email = 'test_email_' + randomNumber(99) + '@faketesting' + randomNumber(99) + '.com';
    testContact.MailingStreet = generateRandomStreet();
    testContact.MailingCity = 'Austin';
    testContact.MailingState = 'Texas';
    testContact.MailingCountry = 'United States';
    testContact.MailingPostalCode = generateRandomUSPostalCode();
    testContact.Phone = randomNumber(9) + '23456789' + randomNumber(9);

    if(insertRecord) {
      insert testContact;
    }

    return testContact;
  }

  public static Contact createContact(Boolean insertRecord, Account associatedAccount) {
    Contact testContact = createContact(false);

    testContact.AccountId = associatedAccount.Id;

    if(insertRecord) {
      insert testContact;
    }

    return testContact;
  }

  /**
   *   Method used to create an Opportunity record. This method does not associate an account or contact with the
   *   Opportunity. Overloaded methods handle this extended functionality.
   *
   *   @author Justin
   *   @date   2016-05-23
   *   @param  {Boolean}      insertRecord Boolean parameter to determine if this record should be inserted into the
   *                                       system during the method execution.
   *   @return {Opportunity}               The created test data Opportunity record which was created.
   */
  public static Opportunity createOpportunity(Boolean insertRecord) {
    Opportunity testOpportunity = new Opportunity();

    testOpportunity.Name = 'Test Opportunity';
    testOpportunity.StageName = 'Prospecting';
    testOpportunity.Type= 'New';
    testOpportunity.Approval_Process_AR_Assignment__c = false;
    testOpportunity.Approval_Process_Manager_Assignment__c = false;
    testOpportunity.Opportunity_Expiration_Date__c = Date.today().addDays(14);
    testOpportunity.CloseDate = Date.today().addDays(14);
    testOpportunity.Approval_Process_Flag_Skip_EchoSign__c = false;

    if(insertRecord) {
      insert testOpportunity;
    }

    return testOpportunity;
  }

  /**
   *   Method used to create an Opportunity record. This is an overloaded method which additionally assigns a specified
   *   Account to specific Account related fields on the Opportunity object.
   *
   *   @author Justin
   *   @date   2016-05-23
   *   @param  {Boolean}      insertRecord Boolean parameter to determine if this record should be inserted into the system
   *                                       during the method execution.
   *   @param  {Account}      paramAccount The specific Account record which should be used when assigning to Account
   *                                       related fields.
   *   @return {Opportunity}               The created test data Opportunity record which was created.
   */
  public static Opportunity createOpportunity(Boolean insertRecord, Account paramAccount) {
    Opportunity testOpportunity = createOpportunity(false);

    testOpportunity.AccountId = paramAccount.Id;

    if(insertRecord) {
      insert testOpportunity;
    }

    return testOpportunity;
  }

  /**
   *   Method used to create an Opportunity record. This is an overloaded method which additionally assigns a specified
   *   Account and Contact to related fields on the Opportunity object.
   *
   *   @author Justin
   *   @date   2016-05-23
   *   @param  {Boolean}      insertRecord Boolean parameter to determine if this record should be inserted into the system
   *                                       during method execution.
   *   @param  {Account}      paramAccount The specific Account record which should be used when assigning to Account
   *                                       related fields.
   *   @param  {Contact}      paramContact The specific Contact record which should be used when assigning to Contact
   *                                       related fields.
   *   @return {Opportunity}               The created test data Opportunity record which was created.
   */
  public static Opportunity createOpportunity(Boolean insertRecord, Account paramAccount, Contact paramContact) {
    Opportunity testOpportunity = createOpportunity(false, paramAccount);

    testOpportunity.Contract_Signer__c = paramContact.Id;

    if(insertRecord) {
      insert testOpportunity;
    }

    return testOpportunity;
  }

  public static Market__c createMarket(Boolean insertRecord) {
    Market__c testMarket = new Market__c();
    testMarket.Name = 'TX - Austin - 191';
    testMarket.Short_Description__c = 'TX-Austin';
    testMarket.Market_Id__c = '191';

    if(insertRecord) {
      insert testMarket;
    }

    return testMarket;
  }

  public static Market__c createMarket(Boolean insertRecord, Region__c associatedRegion) {
    Market__c testMarket = createMarket(false);

    testMarket.Local_Sales_Region__c = associatedRegion.Id;

    if(insertRecord) {
      insert testMarket;
    }

    return testMarket;
  }

  public static Zuora__CustomerAccount__c createCustomerAccount(Boolean insertRecord) {
    Zuora__CustomerAccount__c testCustomerAccount = new Zuora__CustomerAccount__c();
    testCustomerAccount.Name = 'Test Billing Account';
    testCustomerAccount.Zuora__BillToAddress1__c = '123 ABC Dr';
    testCustomerAccount.Zuora__BillToCity__c = 'Austin'; 
    testCustomerAccount.Zuora__BillToCountry__c = 'United States';  
    testCustomerAccount.Zuora__BillToName__c = 'Test'; 
    testCustomerAccount.Zuora__BillToPostalCode__c = '77857'; 
    testCustomerAccount.Zuora__BillToState__c = 'Texas'; 
    testCustomerAccount.Zuora__BillToWorkEmail__c = 'abc@gmail.com';  
    testCustomerAccount.Zuora__Zuora_Id__c = '2c92c0f94ed8d0d7014ee476a6e419ee'; 
    testCustomerAccount.AccountStatus__c = 'Active';
    // testCustomerAccount.Zuora__BillCycleDay__c = '1st';
    // testCustomerAccount.Zuora__Account__c = createAccount(true).Id; // JPS NOTE 12-12-2016: merged down from UAT

    if(insertRecord) {
      insert testCustomerAccount;
    }

    return testCustomerAccount;
  }

  public static Contract createContract(Boolean insertRecord, Opportunity associatedOpp, Account associatedAcc, Contact associatedCont) {
    Contract testContract = new Contract();
    testContract.Opportunity__c = associatedOpp.Id;
    testContract.AccountId = associatedAcc.Id;
    testContract.Contact__c = associatedCont.Id;
    testContract.ContractType__c = 'Concierge Venue';
    testContract.PaymentTerm__c = 'Percentage';
    testContract.Contract__c = 10;
    testContract.Status = 'Sent';
    testContract.CompanySignedBy__c = 'Bob';
    testContract.CompanySignedDateTime__c = DateTime.Now();
    testContract.CustomerSignedBy__c = 'Bill';
    testContract.CustomerSignedDateTime__c = DateTime.Now();

    if(insertRecord) {
      insert testContract;
    }

    return testContract;
  }

  public static Inventory__c createInventory(Boolean insertRecord, zqu__ProductRatePlan__c associatedProductRatePlan) {
    Inventory__c testInventory = new Inventory__c();

    testInventory.Product_Rate_Plan__c = associatedProductRatePlan.Id;
    // Need to get actual id - not fake id
    //testInventory.Subscription__RatePlan_Id__c = 'aaaaadasdasdafaf';

    if(insertRecord) {
      insert testInventory;
    }

    return testInventory;
  }

  // CSP-1999
  // public static Brand__c createBrand(Boolean insertRecord) {
  //   Brand__c testBrand = new Brand__c();

  //   testBrand.Active__c = true;
  //   testBrand.Name = 'Test Knot Brand';

  //   if(insertRecord) {
  //     insert testBrand;
  //   }

  //   return testBrand;
  // }

  public static Region__c createRegion(Boolean insertRecord) {
    Region__c testRegion = new Region__c();

    testRegion.Name = 'Test Region';

    if(insertRecord) {
      insert testRegion;
    }

    return testRegion;
  }

  // CSP-1999
  // public static Region__c createRegion(Boolean insertRecord, Brand__c associatedBrand) {
  //   Region__c testRegion = createRegion(false);

  //   // CSP-1999 testRegion.Primary_Brand__c = associatedBrand.Id;

  //   if(insertRecord) {
  //     // CSP-1999rollback insert testRegion;
  //   }

  //   return testRegion;
  // }

  public static Category__c createCategory(Boolean insertRecord) {
    Category__c testCategory = new Category__c();

    testCategory.Name = 'Test Category';
    testCategory.Short_Description__c = 'Test Category Description';
    testCategory.Active__c = true;
    testCategory.Taxonomy_Id__c = String.valueOf(randomNumberBetween(100000, 999999));

    if(insertRecord) {
      insert testCategory;
    }

    return testCategory;
  }

  // CSP-1999
  // public static Category__c createCategory(Boolean insertRecord, Brand__c associatedBrand) {
  //   Category__c testCategory = createCategory(false);

  //   // CSP-1999 testCategory.Primary_Brand__c = associatedBrand.Id;

  //   if(insertRecord) {
  //     insert testCategory;
  //   }

  //   return testCategory;
  // }

  public static MetroArea__c createMetroArea(Boolean insertRecord) {
    MetroArea__c testMetro = new MetroArea__c();

    testMetro.Name = 'Test Metro Area';

    if(insertRecord) {
      insert testMetro;
    }

    return testMetro;
  }

  public static Zip__c createZip(Boolean insertRecord) {
    Zip__c testZip = new Zip__c();

    testZip.ZipCode__c = generateRandomUSPostalCode();
    testZip.Name = testZip.ZipCode__c;

    if(insertRecord) {
      insert testZip;
    }

    return testZip;
  }

  public static Zip__c createZip(Boolean insertRecord, MetroArea__c associatedMetroArea, Market__c associatedMarket) {
    Zip__c testZip = createZip(false);

    testZip.MetroArea__c = associatedMetroArea.Id;
    testZip.Local_Market__c = associatedMarket.Id;

    if(insertRecord) {
      insert testZip;
    }

    return testZip;
  }

  public static AccountContactRole createAccountContactRole(Boolean insertRecord, Account associatedAccount, Contact associatedContact) {
    AccountContactRole testAccountContactRole = new AccountContactRole();

    testAccountContactRole.AccountId = associatedAccount.Id;
    testAccountContactRole.ContactId = associatedContact.Id;
    testAccountContactRole.Role = 'Primary';

    if(insertRecord) {
      insert testAccountContactRole;
    }

    return testAccountContactRole;
  }
    
    public static Callback__c createCallback(Boolean insertRecord){
      Callback__c callbackObj = new Callback__c();
      callbackObj.Name = 'Test Callback';
      callbackObj.Is_Possible_Renewal__c = 'Yes';
      
      if(insertRecord){
        insert callbackObj;
      }
      
      return callbackObj;
    }
    
  //////////////////////////////////
  // ZUORA OBJECT RECORD CREATION //
  //////////////////////////////////

  public static Zuora__CustomerAccount__c createCustomerAccount(Boolean insertRecord, Account associatedAccount) {
    Zuora__CustomerAccount__c testCustomerAccount = createCustomerAccount(false);
    testCustomerAccount.Zuora__Account__c = associatedAccount.Id;

    if(insertRecord) {
      insert testCustomerAccount;
    }

    return testCustomerAccount;
  }

  public static zqu__Quote__c createQuote(Boolean insertRecord, Opportunity associatedOpp, Account associatedAcc, Contact associatedCont) {
    zqu__Quote__c testQuote = new zqu__Quote__c();
    testQuote.Name = 'Test Quote';
    testQuote.zqu__Status__c = 'New';
    testQuote.zqu__Opportunity__c = associatedOpp.Id;
    testQuote.zqu__Account__c = associatedAcc.id;
    testQuote.zqu__BillToContact__c = associatedCont.Id;
    testQuote.Zqu__ValidUntil__c = Date.Today()-1;
    testQuote.Product_Line__c = 'Internet';
    testQuote.SalesRepLookup__c = userInfo.getUserId();
    testQuote.Reporting_Rep__c = userInfo.getUserId();
    if(insertRecord) {
      insert testQuote;
    }

    return testQuote;
  }

  public static Zuora__PaymentMethod__c createPaymentMethod(Boolean insertRecord) {
    Zuora__PaymentMethod__c testPaymentMethod = new Zuora__PaymentMethod__c();
    testPaymentMethod.Zuora__BankIdentificationNumber__c = '411111';                                   
    testPaymentMethod.Zuora__CreditCardExpirationMonth__c = String.ValueOf(Date.today().Month());
    testPaymentMethod.Zuora__CreditCardExpirationYear__c = '2015';
    testPaymentMethod.Zuora__CreditCardHolderName__c = 'Test 1234';
    testPaymentMethod.Zuora__CreditCardMaskNumber__c = '************1111';
    testPaymentMethod.Zuora__CreditCardPostalCode__c = '78754';
    testPaymentMethod.Zuora__CreditCardState__c = 'Texas';
    testPaymentMethod.Zuora__CreditCardType__c = 'Visa';
    testPaymentMethod.Zuora__DefaultPaymentMethod__c = TRUE;
    testPaymentMethod.Zuora__External_Id__c = '2c92c0f94fd7f22b014ff62286425cdf';
    testPaymentMethod.Zuora__LastTransactionStatus__c = 'Approved';
    testPaymentMethod.Zuora__NumConsecutiveFailures__c = 3;
    testPaymentMethod.Zuora__PaymentMethodStatus__c = 'Active';
    testPaymentMethod.Zuora__Type__c = 'CreditCard';
    testPaymentMethod.Zuora__NumConsecutiveFailures__c = 0;
    testPaymentMethod.CC_Declined_Notification_first_sent_On__c = Date.Today() - 20;

    if(insertRecord) {
      insert testPaymentMethod;
    }

    return testPaymentMethod;
  }

  public static Zuora__PaymentMethod__c createPaymentMethod(Boolean insertRecord, Zuora__CustomerAccount__c associatedCustomerAcc) {
    Zuora__PaymentMethod__c testPaymentMethod = createPaymentMethod(false);
    testPaymentMethod.Zuora__BillingAccount__c = associatedCustomerAcc.Id;

    if(insertRecord) {
      insert testPaymentMethod;
    }

    return testPaymentMethod;
  }

  public static zqu__Quote_Template__c createQuoteTemplate(Boolean insertRecord) {
    zqu__Quote_Template__c testQuoteTemplate = new zqu__Quote_Template__c();
    testQuoteTemplate.zqu__Template_Id__c = 'abcdef';
    testQuoteTemplate.zqu__IsDefault__c = true;
    testQuoteTemplate.zqu__Quote_Type__c = 'New Subscription';

    if(insertRecord) {
      insert testQuoteTemplate;
    }

    return testQuoteTemplate;
  }

  public static Zuora__ZInvoice__c createInvoice(Boolean insertRecord) {
    Zuora__ZInvoice__c testInvoice = new Zuora__ZInvoice__c();
    testInvoice.Name = 'INV00001';
    testInvoice.Promise_To_Pay_Amount__c = 100.00;
    testInvoice.Promise_to_Pay_Date__c = Date.Today()+1;
    testInvoice.Zuora__Balance2__c = 100;
    testInvoice.Zuora__DueDate__c = Date.Today()-45;

    if(insertRecord) {
      insert testInvoice;  
    }
    
    return testInvoice;
  }

  public static Zuora__ZInvoice__c createInvoice(Boolean insertRecord, Account associateAcc, Zuora__CustomerAccount__c associatedCustomerAcc) {
    Zuora__ZInvoice__c testInvoice = createInvoice(false);
    testInvoice.Zuora__Account__c = associateAcc.Id;
    testInvoice.Zuora__BillingAccount__c = associatedCustomerAcc.Id;
    testInvoice.Promise_to_Pay_Date__c = Date.Today()+1;

    if(insertRecord) {
      insert testInvoice;
    }

    return testInvoice;
  }

  public static zqu__ZProduct__c createProduct(Boolean insertRecord) {
    zqu__ZProduct__c testProduct = new zqu__ZProduct__c();
    testProduct.Name = 'Test Product'; 
    testProduct.zqu__Category__c = 'Add On Services'; 
    testProduct.zqu__SKU__c = 'SKU-00000044'; 
    testProduct.zqu__ZuoraId__c = '2c92c0f84e4d2c02014e655c22cc548c'; 
    testProduct.LOB__c = 'The Knot'; 
    testProduct.ProductType__c = 'Internet'; 
    testProduct.Ad_Shape__c = 'None'; 
    testProduct.Job_Type__c = 'The Knot'; 
    testProduct.zqu__Deleted__c = false;
    testProduct.RequiresCallbackTask__c = 'YES';

    if(insertRecord) {
      insert testProduct;
    }
    
    return testProduct;
  }

  public static Product2 createLocalProduct2(Boolean insertRecord) {
    Product2 testProduct = new Product2();
    testProduct.Name = 'Test Product'; 
    testProduct.zqu__Category__c = 'Add On Services'; 
    testProduct.zqu__SKU__c = 'SKU-00000044'; 
    testProduct.zqu__ZuoraId__c = '2c92c0f84e4d2c02014e655c22cc548c'; 
    testProduct.LOB__c = 'The Knot'; 
    testProduct.ProductType__c = 'Internet'; 
    testProduct.Ad_Shape__c = 'None'; 
    testProduct.Job_Type__c = 'BOWPFV'; 
    testProduct.zqu__Deleted__c = false;
    testProduct.RequiresCallbackTask__c = 'YES';

    if(insertRecord) {
      insert testProduct;
    }
    
    return testProduct;
  }

  public static zqu__ProductRatePlan__c createProductRatePlan(Boolean insertRecord) {
    zqu__ProductRatePlan__c testProductRatePlan = new zqu__ProductRatePlan__c();
    testProductRatePlan.Name = 'Test Product Rate Plan';
    testProductRatePlan.Capacity__c = '10';
    testProductRatePlan.Market__c = 'Test Market';
    testProductRatePlan.Category__c = 'Test Category';
    testProductRatePlan.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';

    if(insertRecord) {
      insert testProductRatePlan;
    }
    
    return testProductRatePlan;
  }

  public static zqu__ProductRatePlan__c createProductRatePlan(Boolean insertRecord, zqu__ZProduct__c associatedProduct) {
    zqu__ProductRatePlan__c testProductRatePlan = createProductRatePlan(false);
    testProductRatePlan.zqu__Product__c = associatedProduct.Id;

    if(insertRecord) {
      insert testProductRatePlan;
    }

    return testProductRatePlan;
  }

  public static zqu__ProductRatePlan__c createProductRatePlan(Boolean insertRecord, Product2 associatedProduct) {
    zqu__ProductRatePlan__c testProductRatePlan = createProductRatePlan(false);
    testProductRatePlan.zqu__Product__c  = associatedProduct.Id;

    if(insertRecord) {
      insert testProductRatePlan;
    }

    return testProductRatePlan;
  }

  public static zqu__ProductRatePlanCharge__c createProductRatePlanCharge(Boolean insertRecord) {
    zqu__ProductRatePlanCharge__c testProductRatePlanCharge = new zqu__ProductRatePlanCharge__c();
    testProductRatePlanCharge.Name = 'Test Prodcut Rate Plan Charge'; 
    testProductRatePlanCharge.zqu__DefaultQuantity__c = 0; 
    testProductRatePlanCharge.zqu__ListPrice__c = 200;
    testProductRatePlanCharge.zqu__Model__c = 'Flat Fee Pricing';
    testProductRatePlanCharge.zqu__RecurringPeriod__c = 'Month'; 
    testProductRatePlanCharge.zqu__ZuoraId__c = '2c92c0f94e4d3a41014e655c389b63f7';
    testProductRatePlanCharge.zqu__Type__c = 'Recurring';

    if(insertRecord) {
      insert testProductRatePlanCharge;  
    }
    
    return testProductRatePlanCharge;
  }

  public static zqu__ProductRatePlanCharge__c createProductRatePlanCharge(Boolean insertRecord, zqu__ProductRatePlan__c associatedProductRatePlan) {
    zqu__ProductRatePlanCharge__c testProductRatePlanCharge = createProductRatePlanCharge(false);
    testProductRatePlanCharge.zqu__ProductRatePlan__c = associatedProductRatePlan.Id;

    if(insertRecord) {
      insert testProductRatePlanCharge;
    }

    return testProductRatePlanCharge;
  }

  public static zqu__QuoteAmendment__c createQuoteAmendment(Boolean insertRecord, zqu__Quote__c associatedQuote) {
    zqu__QuoteAmendment__c testQuoteAmmendment = new zqu__QuoteAmendment__c();
    testQuoteAmmendment.Name = 'Test Amendment'; 
    testQuoteAmmendment.zqu__Quote__c = associatedQuote.id; 
    testQuoteAmmendment.zqu__DeltaMRR__c = 0; 
    testQuoteAmmendment.zqu__DeltaTCV__c = 200; 
    testQuoteAmmendment.zqu__Description__c = 'Testing the amendment';  
    testQuoteAmmendment.zqu__Status__c = 'Draft'; 
    testQuoteAmmendment.zqu__TotalAmount__c = 200; 
    testQuoteAmmendment.zqu__Type__c = 'NewProduct';
    
    if(insertRecord) {
      insert testQuoteAmmendment;
    }
    
    return testQuoteAmmendment;
  }

  public static zqu__QuoteRatePlan__c createQuoteRatePlan(Boolean insertRecord) {
    zqu__QuoteRatePlan__c testQuoteRatePlan = new zqu__QuoteRatePlan__c();

    testQuoteRatePlan.Name = 'Test Rate Plan';
    testQuoteRatePlan.zqu__AmendmentType__c = 'New Product'; 
    testQuoteRatePlan.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f'; 
    testQuoteRatePlan.zqu__QuoteProductName__c = 'Featured Vendor';

    if(insertRecord) {
      insert testQuoteRatePlan;
    }

    return testQuoteRatePlan;
  }

  public static zqu__QuoteRatePlan__c createQuoteRatePlan(Boolean insertRecord, zqu__Quote__c associatedQuote, zqu__ProductRatePlan__c associatedProductRatePlan) {
    zqu__QuoteRatePlan__c testQuoteRatePlan = createQuoteRatePlan(false);
    testQuoteRatePlan.zqu__Quote__c = associatedQuote.Id;
    testQuoteRatePlan.zqu__ProductRatePlan__c = associatedProductRatePlan.Id;

    if(insertRecord) {
      insert testQuoteRatePlan;
    }

    return testQuoteRatePlan;
  }

  public static zqu__QuoteRatePlan__c createQuoteRatePlan(Boolean insertRecord, zqu__Quote__c associatedQuote, zqu__ProductRatePlan__c associatedProductRatePlan, zqu__QuoteAmendment__c associatedAmendment) {
    zqu__QuoteRatePlan__c testQuoteRatePlan = createQuoteRatePlan(false, associatedQuote, associatedProductRatePlan);
    testQuoteRatePlan.zqu__QuoteAmendment__c = associatedAmendment.Id;

    if(insertRecord) {
      insert testQuoteRatePlan;
    }

    return testQuoteRatePlan;
  }

  public static zqu__QuoteRatePlanCharge__c createQuoteRatePlanCharge(Boolean insertRecord, zqu__QuoteRatePlan__c associatedQuoteRatePlan, zqu__ProductRatePlanCharge__c associatedProductRatePlanCharge) {
    zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = new zqu__QuoteRatePlanCharge__c();
    testQuoteRatePlanCharge.Name = 'Test Quote Rate Plan Charge';
    testQuoteRatePlanCharge.zqu__QuoteRatePlan__c = associatedQuoteRatePlan.id; 
    testQuoteRatePlanCharge.zqu__ProductRatePlanCharge__c = associatedProductRatePlanCharge.id;

    if(insertRecord) {
      insert testQuoteRatePlanCharge;
    }

    return testQuoteRatePlanCharge;
  }

  public static zqu__QuoteChargeDetail__c createQuoteChargeDetail(Boolean insertRecord, zqu__Quote__c associatedQuote) {
    zqu__QuoteChargeDetail__c testQuoteChargeDetail = new zqu__QuoteChargeDetail__c();
    testQuoteChargeDetail.Name = 'Test Quote Charge Detail';
    testQuoteChargeDetail.zqu__Quote__c = associatedQuote.Id;
    if(insertRecord) {
      insert testQuoteChargeDetail;
    }

    return testQuoteChargeDetail;
  }

  public static Zuora__Subscription__c createSubscription(Boolean insertRecord, Account associatedAccount) {
    Zuora__Subscription__c testSubscription = new Zuora__Subscription__c();
    testSubscription.Name = 'Test Subscription';
    testSubscription.Zuora__SubscriptionStartDate__c = Date.Today();
    testSubscription.Zuora__SubscriptionEndDate__c = Date.Today() + 365;
    testSubscription.Zuora__Status__c = 'Active';
    testSubscription.Zuora__Account__c = associatedAccount.Id;
    testSubscription.Zuora__TermEndDate__c = Date.Today() + 365;

    if(insertRecord) {
      insert testSubscription;
    }

    return testSubscription;
  }

  public static Zuora__Product__c createZuoraProduct(Boolean insertRecord) {
    Zuora__Product__c testZuoraProduct = new Zuora__Product__c();

    testZuoraProduct.Zuora__Description__c = 'Test Product';
    testZuoraProduct.Zuora__EffectiveEndDate__c = Date.Today();
    testZuoraProduct.Zuora__External_Id__c = '123ed';
    testZuoraProduct.ProductType__c = 'Internet';
    testZuoraProduct.Zuora__SKU__c = 'SKU-00000044';
    
    if(insertRecord) {
      insert testZuoraProduct;  
    }

    return testZuoraProduct;
  }

    public static Task createTask(Boolean insertRecord){
      Task testTask = new Task();
        testTask.Subject = 'Test';
        testTask.Type = 'Voicemail';
        testTask.ActivityDate = Date.Today();
        testTask.OwnerId = UserInfo.getUserId();
        testTask.Status = 'Not Started';
        testTask.Priority = 'Normal';
        
        if(insertRecord) {
            insert testTask;  
        }

        return testTask;
    }

  public static Waitlist__c createWaitlist(Boolean insertRecord, zqu__ProductRatePlan__c testZquProductRatePlan){
    Waitlist__c waitListObj = new Waitlist__c();
    waitListObj.Product_Rate_Plan__c = testZquProductRatePlan.id;
      if(insertRecord) {
          insert waitListObj;  
      }
      return waitListObj;
  }

    public static Local_Sales_Rep_Assignment__c createLocalSalesRepAssignment(  Boolean insertRecord, 
                                                                                Category__c testCategory, 
                                                                                Market__c testMarket,
                                                                                Zip__c zip
                                                                            ) {
        Local_Sales_Rep_Assignment__c testZLocalSalesRepAssignment = new Local_Sales_Rep_Assignment__c();
        testZLocalSalesRepAssignment.Name = 'test name';
        testZLocalSalesRepAssignment.Category__c = testCategory != null? testCategory.id : null;
        testZLocalSalesRepAssignment.Market__c = testMarket != null ? testMarket.id : null;
        testZLocalSalesRepAssignment.Zip_Code__c = zip != null? zip.id : null;
        testZLocalSalesRepAssignment.Sales_Rep__c = UserInfo.getUserId();
        
        if(insertRecord) {
            insert testZLocalSalesRepAssignment;  
        }

        return testZLocalSalesRepAssignment;
    }
    
    public static Attachment createAttachment(Boolean insertRecord, Contract testContract ){
        
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('bodyStr');
        att.Name = 'Note_' + System.now().format('yyyy_MM_dd_hh_mm_ss') + '.txt';
        att.parentId = testContract != null? testContract.Id : null;
        
        if(insertRecord) {
            insert att;  
        }

        return att;
    }

    public static Attachment createAttachment(Boolean insertRecord, String attName, String contentType){
        
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('bodyStr');
        att.Name = attName;
        att.contentType = contentType;
                
        if(insertRecord) {
            insert att;  
        }

        return att;
    }
    
    public static Endorsement__c createEndorsement(Boolean insertRecord, Account testAccount){
      Endorsement__c endorsementObj = new Endorsement__c();
      endorsementObj.Name = 'TestEndorsement';
      endorsementObj.Account__c = testAccount.id;
      endorsementObj.Type__c = 'Internet Endorsement';
      
      if(insertRecord) {
            insert endorsementObj;  
        }

        return endorsementObj;
      
    }
    
    public static Deactivate_Trigger__c createAttachmentDeactivateTriggerSetting(Boolean insertRecord){
        
        Deactivate_Trigger__c dtatt = new Deactivate_Trigger__c();
        dtatt.Name = 'Attachment';
        dtatt.After_Delete__c = True;
        dtatt.After_Insert__c = True;
        dtatt.After_Update__c = True;
        dtatt.Before_Delete__c = True;
        dtatt.Before_Insert__c = True;
        dtatt.Before_Update__c = True;
        
        if(insertRecord) {
            insert dtatt;  
        }

        return dtatt;
    }
    
    public static Promise_to_Pay_reminder_config__c createPromiseToPayReminderConfig(Boolean insertRecord){
        
        Promise_to_Pay_reminder_config__c PTP = new Promise_to_Pay_reminder_config__c();
        PTP.Create_P2P_reminder__c = true;
        PTP.name = 'P2P';
            
        if(insertRecord) {
            insert PTP;  
        }

        return PTP;
    }
    /*
    public static DefaulCBSSValues__c createCBSSSetting(Boolean insertRecord){
        
        DefaulCBSSValues__c customSettingDefCBSSValues = new DefaulCBSSValues__c();
        customSettingDefCBSSValues.Name = 'Default';
      customSettingDefCBSSValues.Email__c = 'theknotaccounting@xogrp.com';
      customSettingDefCBSSValues.Phone__c = '800-843-4983';
      List<DefaulCBSSValues__c> defaultValues = DefaulCBSSValues__c.getall().values();
        if(insertRecord) {
            insert customSettingDefCBSSValues;  
        }

        return customSettingDefCBSSValues;
    }*/
    
    public static TriggerHandlerAccess__c createTriggerHandlerAccessSetting(Boolean insertRecord,
                              String objectName,
                              String className){
        
        TriggerHandlerAccess__c newTHA = new TriggerHandlerAccess__c();
        newTHA.Name = className;
        newTHA.Active__c = true;
        newTHA.Handler_Name__c = className;
        newTHA.Object__c = objectName;
        
        if(insertRecord) {
            insert newTHA; 
        }

        return newTHA;
    }
    
    public static CountryZipREGEX__c createContryZipREGEX(  Boolean insertRecord,
                                                            String countryName,
                                                            String countryCode
                                                        ){
        
        CountryZipREGEX__c czr = new CountryZipREGEX__c();
        czr.Active__c = true;
        czr.Name = countryName;
        czr.CountryCode__c = countryCode;
        czr.RegExPattern__c = '^\\d{5}(-\\d{4})?$';
        
        if(insertRecord) {
            insert czr;  
        }

        return czr;
    }
    
    public static User createUser(Boolean insertRecord, Profile profileRecord){
      User userRecord = new User();
        userRecord.FirstName = 'Bob';
        userRecord.LastName = 'Tester';
        userRecord.Alias = 'btest';
        userRecord.Email = 'bobtester@asdasfaf.com';
        userRecord.UserName = 'bobtester@asdasfaf.com';
        userRecord.TimeZoneSidKey = 'America/Panama';
        userRecord.LocaleSidKey = 'en_US';
        userRecord.EmailEncodingKey = 'UTF-8';
        userRecord.ProfileId = profileRecord.Id;
        userRecord.LanguageLocaleKey = 'en_US';
        userRecord.SalesRepID__c = '12345';
        
        if(insertRecord) {
            insert userRecord;  
        }

        return userRecord;
    }
  public static Zuora__SubscriptionProductCharge__c createSubscriptionProductCharge(Boolean insertRecord, 
                                            Account associatedAccount,
                                            Zuora__Subscription__c associatedSubscription 
                                            ) {
    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();

    testSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();
    testSubscriptionProductCharge.Name = 'Test Subscription Product Charge';
    testSubscriptionProductCharge.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
    testSubscriptionProductCharge.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
    testSubscriptionProductCharge.Quote_Rate_Plan_ID__c = 'qweqweqwe';
    testSubscriptionProductCharge.Zuora__RatePlanId__c = 'asdasdasdasdas';
    testSubscriptionProductCharge.Zuora__Subscription__c = associatedSubscription.id;
    testSubscriptionProductCharge.Zuora__ProductName__c = 'Test Product';
    testSubscriptionProductCharge.Zuora__RatePlanName__c = 'Test Product Rate Plan';
    testSubscriptionProductCharge.LocationVendorDynamicsAccountID__c = associatedAccount.DynamicsAccId__c;

    if(insertRecord) {
      insert testSubscriptionProductCharge;  
    }
    
    return testSubscriptionProductCharge;
  }

  public static Zuora__SubscriptionProductCharge__c createSubscriptionProductCharge(Boolean insertRecord, 
                                            Zuora__Subscription__c associatedSubscription 
                                            ) {
    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();

    testSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();
    testSubscriptionProductCharge.Name = 'Test Subscription Product Charge';
    testSubscriptionProductCharge.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
    testSubscriptionProductCharge.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
    testSubscriptionProductCharge.Quote_Rate_Plan_ID__c = 'qweqweqwe';
    testSubscriptionProductCharge.Zuora__RatePlanId__c = 'asdasdasdasdas';
    testSubscriptionProductCharge.Zuora__Subscription__c = associatedSubscription.id;
    testSubscriptionProductCharge.Zuora__ProductName__c = 'Test Product';
    testSubscriptionProductCharge.Zuora__RatePlanName__c = 'Test Product Rate Plan';

    if(insertRecord) {
      insert testSubscriptionProductCharge;  
    }
    
    return testSubscriptionProductCharge;
  }

  public static Zuora__SubscriptionProductCharge__c createSubscriptionProductCharge(Boolean insertRecord, 
                                            Account associatedAccount,
                                            Zuora__Subscription__c associatedSubscription, 
                                            Zuora__Product__c associatedZuoraProduct
                                            ) {
    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();

    testSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();
    testSubscriptionProductCharge.Name = 'Test Subscription Product Charge';
    testSubscriptionProductCharge.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
    testSubscriptionProductCharge.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
    testSubscriptionProductCharge.Quote_Rate_Plan_ID__c = 'qweqweqwe';
    testSubscriptionProductCharge.Zuora__RatePlanId__c = 'asdasdasdasdas';
    testSubscriptionProductCharge.Zuora__Subscription__c = associatedSubscription.id;
    testSubscriptionProductCharge.Zuora__ProductName__c = 'Test Product';
    testSubscriptionProductCharge.Zuora__RatePlanName__c = 'Test Product Rate Plan';
    testSubscriptionProductCharge.Zuora__Product__c = associatedZuoraProduct.id;
    testSubscriptionProductCharge.LocationVendorDynamicsAccountID__c = associatedAccount.DynamicsAccId__c;

    if(insertRecord) {
      insert testSubscriptionProductCharge;  
    }
    
    return testSubscriptionProductCharge;
  }

  public static Zuora__SubscriptionProductCharge__c createSubscriptionProductCharge(Boolean insertRecord, 
                                            Zuora__Subscription__c associatedSubscription, 
                                            Zuora__Product__c associatedZuoraProduct
                                            ) {
    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();

    testSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();
    testSubscriptionProductCharge.Name = 'Test Subscription Product Charge';
    testSubscriptionProductCharge.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
    testSubscriptionProductCharge.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
    testSubscriptionProductCharge.Quote_Rate_Plan_ID__c = 'qweqweqwe';
    testSubscriptionProductCharge.Zuora__RatePlanId__c = 'asdasdasdasdas';
    testSubscriptionProductCharge.Zuora__Subscription__c = associatedSubscription.id;
    testSubscriptionProductCharge.Zuora__ProductName__c = 'Test Product';
    testSubscriptionProductCharge.Zuora__RatePlanName__c = 'Test Product Rate Plan';
    testSubscriptionProductCharge.Zuora__Product__c = associatedZuoraProduct.id;

    if(insertRecord) {
      insert testSubscriptionProductCharge;  
    }
    
    return testSubscriptionProductCharge;
  }

  /////////////////////////////
  // CUSTOM SETTING CREATION //
  /////////////////////////////

  public static Credit_Card_Expiry_Config__c createCCExpireConfig(Boolean insertRecord) {
    Credit_Card_Expiry_Config__c testCreditCrdConfig = new Credit_Card_Expiry_Config__c();
    testCreditCrdConfig.Create_ARR_Task__c = true;
    testCreditCrdConfig.Days_Before_Expiry__c = 1;
    testCreditCrdConfig.Send_Email_To_Customer__c = true;
    testCreditCrdConfig.Name = 'First Attempt';

    if(insertRecord) {
      insert testCreditCrdConfig;
    }
    
    return testCreditCrdConfig;
  }

  public static Invoice_Past_Due_Config__c createInvoicePastDueConfig(Boolean insertRecord) {
    Invoice_Past_Due_Config__c testInvConfig = new Invoice_Past_Due_Config__c();
    testInvConfig.Name = 'First Reminder';
    testInvConfig.Create_ARR_Task__c = true;
    testInvConfig.Number_Of_Days_Past_Due__c = 45;
    testInvConfig.Send_Email_To_Customer__c = true;

    if(insertRecord) {
      insert testInvConfig;  
    }
    
    return testInvConfig;
  }

  public static List<Consecutive_Credit_Card_Failure_Config__c> generateConsecCreditFailConfigs(Boolean insertRecord) {
    List<Consecutive_Credit_Card_Failure_Config__c> consecConfigList = new List<Consecutive_Credit_Card_Failure_Config__c>();

    Consecutive_Credit_Card_Failure_Config__c testConsecCreditFail = new Consecutive_Credit_Card_Failure_Config__c();
    testConsecCreditFail.Name = 'Test Card Failure';
    testConsecCreditFail.Number_Of_Consecutive_Failure__c = 1;

    consecConfigList.add(testConsecCreditFail);

    Consecutive_Credit_Card_Failure_Config__c testConstConsecCreditFail = new Consecutive_Credit_Card_Failure_Config__c();
    testConstConsecCreditFail.Name = 'Constant1';
    testConstConsecCreditFail.Number_of_Consecutive_Failure__c = 3;

    consecConfigList.add(testConstConsecCreditFail);

    if(insertRecord) {
      insert consecConfigList;
    }

    return consecConfigList;
  }

  public static Credit_Card_Declined_Config__c generateCardDeclinedConfig(Boolean insertRecord) {
    Credit_Card_Declined_Config__c testCardDeclined = new Credit_Card_Declined_Config__c();
    testCardDeclined.Name = 'Second Attempt';
    testCardDeclined.Create_ARR_Task__c = true;
    testCardDeclined.Notify_customer_after_Days__c = 0;
    testCardDeclined.Send_Email_To_Customer__c = true;

    if(insertRecord) {
      insert testCardDeclined;
    }

    return testCardDeclined;
  }

  public static Generate_Quote_Pdf_Config__c generateQuotePdfConfig(Boolean insertRecord) {
    Generate_Quote_Pdf_Config__c testQuotePdfConfig = new Generate_Quote_Pdf_Config__c();
    testQuotePdfConfig.Name = 'Production';
    testQuotePdfConfig.URL__c = 'https://apisandbox-zforsf.zuora.com/apps/servlet/GenerateQuote?attachToOpportunity=true&format=pdf&locale=en_US';

    if(insertRecord) {
      insert testQuotePdfConfig;
    }

    return testQuotePdfConfig;
  }

  public static Inventory_Hold_Expiry_Date_Offsets__c generateInventoryExpireDateOffsets(Boolean insertRecord) {
    Inventory_Hold_Expiry_Date_Offsets__c testInventoryHoldExpireDateOffset = new Inventory_Hold_Expiry_Date_Offsets__c();
    testInventoryHoldExpireDateOffset.Account_Day_Offset__c = 3;
    testInventoryHoldExpireDateOffset.Quote_Rate_Plan_Day_Offset__c = 3;
    testInventoryHoldExpireDateOffset.Subscription_Product_Charge_Day_Offset__c = -7;
    
    if(insertRecord) {
      insert testInventoryHoldExpireDateOffset;  
    }
    
    return testInventoryHoldExpireDateOffset;
  }

  ////////////////////////////////
  // BULK DATA BUILDING METHODS //
  ////////////////////////////////

  public static Map<String, SObject> buildLocalData(Boolean buildSubscriptionData) {
    TestClassUtility.DISABLE_TRIGGERS = TRUE;
    List<RecordType> localRecordTypeList = [SELECT Id, Name, SObjectType FROM RecordType WHERE Name LIKE '%local%' AND IsActive = true];
    Map<String, Id> localRecordTypeMap = new Map<String, Id>();
    for(Integer i = 0; i < localRecordTypeList.size(); i++) {
      RecordType currentRecordType = localRecordTypeList[i];
      localRecordTypeMap.put(currentRecordType.SObjectType, currentRecordType.Id);
    }

    Map<String, SObject> objectMap = new Map<String, SObject>();
    DefaulCBSSValues__c defCBSScustomSetting = new DefaulCBSSValues__c();
       defCBSScustomSetting.Name = 'InvoiceTemplate';
       defCBSScustomSetting.Phone__c = '(800)843-4983';
       defCBSScustomSetting.Email__c = 'theknotaccounting@xogrp.com';
       insert defCBSScustomSetting;
    
    // CSP-1999 
    // Create Brand
    // Brand__c testBrand = createBrand(false);
    // if(localRecordTypeMap.containsKey('Brand__c')) {
    //   testBrand.RecordTypeId = localRecordTypeMap.get('Brand__c');
    // }
    // insert testBrand;
    // objectMap.put('Brand__c', testBrand);

    // Create Region
    // Region__c testRegion = createRegion(true, testBrand);
    Region__c testRegion = createRegion(true);
    objectMap.put('Region__c', testRegion);

    // Needed for AccountLocalTriggerHandler Line 17 - Need to fix that line.
    Market__c wtfMarket = createMarket(false, testRegion);
    wtfMarket.Market_ID__c = '222';
    insert wtfMarket;

    // Create Market
    Market__c testMarket = createMarket(true, testRegion);
    objectMap.put('Market__c', testMarket);

    // Create Category
    // CSP-1999 Category__c testCategory = createCategory(false, testBrand);
    Category__c testCategory = createCategory(false);
    if(localRecordTypeMap.containsKey('Category__c')) {
      testCategory.RecordTypeId = localRecordTypeMap.get('Category__c');
    }
    insert testCategory;
    objectMap.put('Category__c', testCategory);

    // Create MetroArea - Not sure where this is used?
    MetroArea__c testMetroArea = createMetroArea(true);
    objectMap.put('MetroArea__c', testMetroArea);

    // Create Zip
    Zip__c testZip = createZip(true, testMetroArea, testMarket);
    objectMap.put('Zip__c', testZip);

    // Create Account
    // CSP-1999
    // Account testAccount = createAccount(false, testBrand, testCategory, testMarket);
    Account testAccount = createAccount(false, testCategory, testMarket);
    if(localRecordTypeMap.containsKey('Account')) {
      testAccount.RecordTypeId = localRecordTypeMap.get('Account');
    }
    testAccount.CreditHold__c = 'No';
    insert testAccount;
    objectMap.put('Account', testAccount);

    // Create Contact
    Contact testContact = createContact(false, testAccount);
    testContact.MailingPostalCode = testZip.ZipCode__c;
    insert testContact;
    objectMap.put('Contact', testContact);

    // Create AccountContactRole
    AccountContactRole testAccountContactRole = createAccountContactRole(true, testAccount, testContact);
    objectMap.put('AccountContactRole', testAccountContactRole);

    // Create Consecutive CC Failure Configs
    generateConsecCreditFailConfigs(true);

    // Create Card Declined Config
    generateCardDeclinedConfig(true);

    // Create Quote PDF Config
    generateQuotePdfConfig(true);

    // Create Inventory Expire Offsets
    generateInventoryExpireDateOffsets(true);    

    // Create Billing Account(Zuora Customer Account)
    Zuora__CustomerAccount__c testBillingAccount = createCustomerAccount(true, testAccount);
    objectMap.put('Zuora__CustomerAccount__c', testBillingAccount);

    // Create Opportunity
    Opportunity testOpportunity = createOpportunity(false, testAccount, testContact);
    testOpportunity.AccStrategist__c = UserInfo.getUserId();
    if(localRecordTypeMap.containsKey('Opportunity')) {
      testOpportunity.RecordTypeId = localRecordTypeMap.get('Opportunity');
    }
    insert testOpportunity;
    objectMap.put('Opportunity', testOpportunity);

    // Create Attachments
    

    if(buildSubscriptionData) {
      objectMap.putAll(buildSubscriptionData(testAccount, testContact, testOpportunity, testBillingAccount));
    }
    TestClassUtility.DISABLE_TRIGGERS = FALSE;
    return objectMap;
  }

  public static Map<String, SObject> buildSubscriptionData(Account associatedAccount, Contact associatedContact, Opportunity associatedOpportunity, Zuora__CustomerAccount__c associatedBillingAccount) {
    Map<String, SObject> objectMap = new Map<String, SObject>();
    TestClassUtility.DISABLE_TRIGGERS = TRUE;
    // Create Quote Template
    createQuoteTemplate(true);

    // Create Quote
    zqu__Quote__c testQuote = createQuote(true, associatedOpportunity, associatedAccount, associatedContact);
    objectMap.put('zqu__Quote__c', testQuote);

    // Create Payment Method
    //Zuora__PaymentMethod__c testPaymentMethod = createPaymentMethod(true, associatedBillingAccount);
    //objectMap.put('Zuora__PaymentMethod__c', testPaymentMethod);

    // Create Invoice
    Zuora__ZInvoice__c testInvoice = createInvoice(true, associatedAccount, associatedBillingAccount);
    objectMap.put('Zuora__ZInvoice__c', testInvoice);

    // Create ZProduct
    // zqu__ZProduct__c testProduct = createProduct(true);
    // objectMap.put('zqu__ZProduct__c', testProduct);

    Product2 testLocalProduct = createLocalProduct2(true);
    objectMap.put('Product2', testLocalProduct);

    // Create Product Rate Plan
    zqu__ProductRatePlan__c testProductRatePlan = createProductRatePlan(true, testLocalProduct);
    objectMap.put('zqu__ProductRatePlan__c', testProductRatePlan);

    // Create Product Rate Plan Charge
    zqu__ProductRatePlanCharge__c testProductRatePlanCharge = createProductRatePlanCharge(true, testProductRatePlan);
    objectMap.put('zqu__ProductRatePlanCharge__c', testProductRatePlanCharge);

    // Create Quote Rate Plan Amendment
    zqu__QuoteAmendment__c testQuoteAmmendment = createQuoteAmendment(true, testQuote);
    objectMap.put('zqu__QuoteAmendment__c', testQuoteAmmendment);

    // Create Quote Rate Plan
    zqu__QuoteRatePlan__c testQuoteRatePlan = createQuoteRatePlan(true, testQuote, testProductRatePlan, testQuoteAmmendment);
    objectMap.put('zqu__QuoteRatePlan__c', testQuoteRatePlan);

    // Create Quote Rate Plan Charge
    zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = createQuoteRatePlanCharge(true, testQuoteRatePlan, testProductRatePlanCharge);
    objectMap.put('zqu__QuoteRatePlanCharge__c', testQuoteRatePlanCharge);

    // Create Subscription
    Zuora__Subscription__c testSubscription = createSubscription(true, associatedAccount);
    objectMap.put('Zuora__Subscription__c', testSubscription);

    // Create Zuora Product
    // Zuora__Product__c testZuoraProduct = createZuoraProduct(true);
    // objectMap.put('Zuora__Product__c', testZuoraProduct);

    // Create Inventory
    Inventory__c testInventory = createInventory(true, testProductRatePlan);
    objectMap.put('Inventory__c', testInventory);

    // Create Subscription Product Charge
    // Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = createSubscriptionProductCharge(true, associatedAccount, testSubscription, testZuoraProduct);
    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = createSubscriptionProductCharge(true, associatedAccount, testSubscription);
    objectMap.put('Zuora__SubscriptionProductCharge__c', testSubscriptionProductCharge);
    TestClassUtility.DISABLE_TRIGGERS = FALSE;
    return objectMap;
  }

  ///////////////////////////
  // FUNCTIONALITY METHODS //
  ///////////////////////////

  /**
   *   Method used to generated a random street number. Currently just using "Testing Street" as the street name.
   *
   *   @author Justin
   *   @date   2016-05-23
   *   @return {String}     The generated street string.
   */
  public static String generateRandomStreet() {
    return randomNumber(9999) + ' Testing Street';
  }

  /**
   *   Method used to generate a random 6 digit US Postal Code.
   *
   *   @author Justin
   *   @date   2016-05-23
   *   @return {String}     The generated 6 digit US Postal Code
   */
  public static String generateRandomUSPostalCode() {
    return String.valueOf(randomNumberBetween(100000, 999999));
  }

  // TODO
  public static String generateRandomCANPostalCode() {
    return null;
  }

  public static String generateRandomEmail() {
    return 'test' + randomNumber(99) + '@email' + randomNumber(999) + '.com';
  }

  public static String generateRandomWebsite() {
    return 'http://www.random' + randomNumber(9999) + 'site.com';
  }

  /**
   *   Method used to generate a random number using a provided max size parameter.
   *
   *   @author Justin
   *   @date   2016-05-23
   *   @param  {Integer}   maxSize The max size that the returned number can be.
   *   @return {Integer}           The random number which was generated.
   */
  public static Integer randomNumber(Integer maxSize) {
      if(maxSize == null) {
          return 0;
      }
      
      return (Math.round(Math.random() * maxSize));
  }

  /**
   *   Method used to generate a random number using a provided max and min size parameter. The number geneated will
   *   be a random number between MIN and MAX
   *
   *   @author Justin
   *   @date   2016-08-05
   *   @param  {Integer}   min The minimum number used to determine the lower bounds of the random number.
   *   @param  {Integer}   max The maximum number used to determine the upper bounds of the random number.
   *   @return {Integer}       The random number which was generated between min and max.
   */
  public static Integer randomNumberBetween(Integer min, Integer max) {
    if(min == null || max == null || min > max) {
      return 0;
    }

    return Integer.valueOf(Math.floor(Math.random() * ((max - min) + 1) + min));
  }

  public static Deactivate_Trigger__c createNotesDeactivateTriggerSetting(Boolean insertRecord){          
    Deactivate_Trigger__c dtatt = new Deactivate_Trigger__c();
    dtatt.Name = 'Note';
    dtatt.After_Delete__c = True;
    dtatt.After_Insert__c = True;
    dtatt.After_Update__c = True;
    dtatt.Before_Delete__c = True;
    dtatt.Before_Insert__c = True;
    dtatt.Before_Update__c = True;
    
    if(insertRecord) {
        insert dtatt;       
    }

    return dtatt;
  }   

  public static Note createNote(Boolean insertRecord){
    // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
    // CSP-1999 
    // Brand__c brand = TestClassUtility.createBrand(false);
    // brand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
    // insert brand;
    // Category__c category = createCategory(true,brand);
    Category__c category = createCategory(true);
    Market__c market = createMarket(true);
    market.Market_ID__c ='222';
    update market;
    // CSP-1999
    // Account acc = createAccount(true,brand,category,market);
    Account acc = createAccount(true,category,market);
    Note testNote = new Note();
    testNote.Title = 'Test';
    testNote.ParentId = acc.id;
    testNote.Body = 'Test Note';

    if(insertRecord) {
      insert testNote;
    }

    return testNote;
  } 
    
  public static Partner_Fulfillment_Response__c createPartnerFulfillmentResponse(Boolean insertRecord){
    Partner_Fulfillment_Response__c testPFR = new Partner_Fulfillment_Response__c();
    testPFR.Object_Type__c = 'Account';
    testPFR.Response_JSON__c = '{"accountId":"2192345c-d0db-4bec-8bc1-a56e0173e0de","companyId":"08cf5c27-d577-4e1f-85a5-6c673032208d","errors":"testerrors"}';
    testPFR.Type__c = 'Account Update';

      if(insertRecord) {
        insert testPFR;
      }
    return testPFR;
  }

  // CSP-1999
  public static Fulfillment_Response__c createFulfillmentResponse(Boolean insertRecord, Category__c testCategory, Market__c testMarket,Partner_Fulfillment_Response__c testPartnerResponse){   
    // CSP-1999
    // Account testAccount = createAccount(true,testBrand,testCategory,testMarket);
    Account testAccount = createAccount(true,testCategory,testMarket);
    Fulfillment_Response__c testFR = new Fulfillment_Response__c();
    testFR.Partner_Fulfillment_Response__c = testPartnerResponse != null ? testPartnerResponse.id : null;
    testFR.Account__c = testAccount != null? testAccount.id : null;

    if(insertRecord) {
      insert testFR;
    }

    return testFR;      
  }
    
  public static Fulfillment_Response__c createFulfillmentResponse(Boolean insertRecord,Account testAccount,Partner_Fulfillment_Response__c testPartnerResponse){  
    Fulfillment_Response__c testFR = new Fulfillment_Response__c();
    testFR.Partner_Fulfillment_Response__c = testPartnerResponse != null ? testPartnerResponse.id : null;
    testFR.Account__c = testAccount != null? testAccount.id : null;

    if(insertRecord) {
      insert testFR;
    }

    return testFR;      
  }   
    
  public static Deactivate_Trigger__c updateAttachmentDeactivateTriggerSetting(Boolean updateRecord, Deactivate_Trigger__c dtatt, Boolean updateTo){
      
    if(dtatt != null){        
      dtatt.After_Delete__c = updateTo;
      dtatt.After_Insert__c = updateTo;
      dtatt.After_Update__c = updateTo;
      dtatt.Before_Delete__c = updateTo;
      dtatt.Before_Insert__c = updateTo;
      dtatt.Before_Update__c = updateTo;
    }

    if(updateRecord) {
      update dtatt;  
    }

    return dtatt;
  }   

    public static Generate_Quote_Pdf_Config__c createGenerateQuotePdfConfig(Boolean insertRecord){
      Generate_Quote_Pdf_Config__c GQPF = new Generate_Quote_Pdf_Config__c();
      GQPF.name = 'Production';
      GQPF.URL__c = 'www.baidu.com';
      
      if(insertRecord) {
        insert GQPF;
      }

      return GQPF;
    } 
    
    public static echosign_dev1__SIGN_Agreement__c createechosigndev1SIGNAgreement(Boolean insertRecord, Opportunity associatedOpportunity){
      echosign_dev1__SIGN_Agreement__c testEDSA = new echosign_dev1__SIGN_Agreement__c();
      testEDSA.echosign_dev1__Opportunity__c = associatedOpportunity.id;
      testEDSA.echosign_dev1__Status__c = 'Signed';

      if(insertRecord) {
        insert testEDSA;
      }

      return testEDSA;
    }
    
    public static LocalOppApprovalProcessARApprover__c createLocalOppApprovalProcessARApprover(Boolean insertRecord){
      LocalOppApprovalProcessARApprover__c LOAPARA = LocalOppApprovalProcessARApprover__c.getOrgDefaults();
      LOAPARA.Email__c = userInfo.getUserEmail();
      LOAPARA.Last_Name__c = 'testtest';
      LOAPARA.First_Name__c = 'testtest';

      if(insertRecord) {
        insert LOAPARA;
      }

      return LOAPARA;
    }
    
    public static LocalOppApprovalProcessCancelApprover__c createLocalOppApprovalProcessCancelApprover(Boolean insertRecord){
      LocalOppApprovalProcessCancelApprover__c LOAPCA = LocalOppApprovalProcessCancelApprover__c.getOrgDefaults();
      LOAPCA.Email__c = userInfo.getUserEmail();
      LOAPCA.Last_Name__c = 'testtest';
      LOAPCA.First_Name__c = 'testtest';
       
      if(insertRecord) {
        insert LOAPCA;
      }

      return LOAPCA;
    }
    
    public static Task_Creation_Settings__c createTaskCreationSettings(Boolean insertRecord){
      Task_Creation_Settings__c taskCreateSetting = new Task_Creation_Settings__c();
      taskCreateSetting.name = 'Approval_Requested';
      taskCreateSetting.Create_Task__c = true;

      if(insertRecord) {
        insert taskCreateSetting;
      }

      return taskCreateSetting;
    }

    
    public static Task_Creation_Settings__c createTaskCreationSettings(Boolean insertRecord, String settingName, Boolean settingTrueorFalse){
      Task_Creation_Settings__c taskCreateSetting = new Task_Creation_Settings__c();
      taskCreateSetting.name = settingName;
      taskCreateSetting.Create_Task__c = settingTrueorFalse;

      if(insertRecord) {
        insert taskCreateSetting;
      }

      return taskCreateSetting;
    }


    public static Task_Creation_Settings__c createTaskCreationSettingsWithQuoteDeleted(Boolean insertRecord){
      Task_Creation_Settings__c taskCreateSetting = new Task_Creation_Settings__c();
      taskCreateSetting.name = 'Quote_Deleted';
      taskCreateSetting.Create_Task__c = true;

      if(insertRecord) {
        insert taskCreateSetting;
      }

      return taskCreateSetting;
    }
    
    public static Account_Strategist_Assignment__c createAccountStrategistAssignment(Boolean insertRecord, user associatedUser){
      Account_Strategist_Assignment__c ASA = new Account_Strategist_Assignment__c();
      ASA.Account_Strategist__c = associatedUser.id;
      ASA.Sales_Rep__c = userInfo.getuserId();

      if(insertRecord) {
          insert ASA;
      }

      return ASA;
    }
    
    
  public static Map<String, SObject> buildNationalData() {
    // Create Quote PDF Config
    generateQuotePdfConfig(true);
    
    
    List<RecordType> nationalRecordTypeList = [SELECT Id, Name, SObjectType FROM RecordType WHERE Name LIKE '%National%' AND IsActive = true];
    Map<String, Id> nationalRecordTypeMap = new Map<String, Id>();
    for(Integer i = 0; i < nationalRecordTypeList.size(); i++) {
      RecordType currentRecordType = nationalRecordTypeList[i];
      nationalRecordTypeMap.put(currentRecordType.SObjectType, currentRecordType.Id);
    }
        
    
      
    Map<String, SObject> objectMap = new Map<String, SObject>();
    
    // CSP-1999
    // Create Brand
    // Brand__c testBrand = createBrand(false);
    // if(NationalRecordTypeMap.containsKey('Brand__c')) {
    //   testBrand.RecordTypeId = NationalRecordTypeMap.get('Brand__c');
    // }
    // insert testBrand;
    // objectMap.put('Brand__c', testBrand);
    
    
    // Needed for AccountLocalTriggerHandler Line 17 - Need to fix that line.
    Market__c wtfMarket = createMarket(false);
    wtfMarket.Market_ID__c = '222';
    insert wtfMarket;
    
    // Create Market
    Market__c testMarket = createMarket(true);
    objectMap.put('Market__c', testMarket);
    
    // Create Category
    Category__c testCategory = createCategory(false);
    if(NationalRecordTypeMap.containsKey('Category__c')) {
      testCategory.RecordTypeId = NationalRecordTypeMap.get('Category__c');
    }
    insert testCategory;
    objectMap.put('Category__c', testCategory);
    
    // Create MetroArea - Not sure where this is used?
    MetroArea__c testMetroArea = createMetroArea(true);
    objectMap.put('MetroArea__c', testMetroArea);
    
    // Create Zip
    Zip__c testZip = createZip(true, testMetroArea, testMarket);
    objectMap.put('Zip__c', testZip);
    
    // Create Account
    Account testAccount = createAccount(false);
    if(NationalRecordTypeMap.containsKey('Account')) {
      testAccount.RecordTypeId = NationalRecordTypeMap.get('Account');
    }
    testAccount.AccountSource = 'Field Event';
    testAccount.AccSource__c = 'Field Event';
    insert testAccount;
    objectMap.put('Account', testAccount);
    
    // Create Contact
    Contact testContact = createContact(false, testAccount);
    testContact.MailingPostalCode = testZip.ZipCode__c;
    insert testContact;
    objectMap.put('Contact', testContact);
    
    // Create AccountContactRole
    AccountContactRole testAccountContactRole = createAccountContactRole(true, testAccount, testContact);
    objectMap.put('AccountContactRole', testAccountContactRole);  
    
    // Create Opportunity
    Opportunity testOpportunity = createOpportunity(false, testAccount, testContact);
    testOpportunity.AccStrategist__c = UserInfo.getUserId();
    if(NationalRecordTypeMap.containsKey('Opportunity')) {
      testOpportunity.RecordTypeId = NationalRecordTypeMap.get('Opportunity');
    }
    testOpportunity.Description = 'Test data for test class';
    insert testOpportunity;
    objectMap.put('Opportunity', testOpportunity);
    
    
    return objectMap;
  } 
    
    
  public static List<Stage_Requires_Complete_TS_RFP__c> createStageRequiresCompleteTSRFP(Boolean insertRecord){
    List<Stage_Requires_Complete_TS_RFP__c> SRCTSRFP = (List<Stage_Requires_Complete_TS_RFP__c>)JSON.deserialize([Select body from StaticResource where Name = 'StageRequireCompleteTSRFP'].body.toString(), List<Stage_Requires_Complete_TS_RFP__c>.class);

    if(insertRecord) {
      insert SRCTSRFP;
    }

    return SRCTSRFP;
  }
    
    
  public static Product2 createProduct2(Boolean insertRecord){
    Product2 prod = new Product2();
    prod.Name = 'Uncategorized Revenue';
    prod.ProductCode = 'Pro-X';
    prod.isActive = true;

    if(insertRecord) {
      insert prod;
    }

    return prod;
  }
  
  public static PricebookEntry createPricebookEntry(Boolean insertRecord, id pricebookId, Product2 prod){
    PricebookEntry pbEntry = new PricebookEntry();
    pbEntry.Pricebook2Id = pricebookId;
    pbEntry.Product2Id = prod.Id;
    pbEntry.UnitPrice = 100.00;
    pbEntry.IsActive = true;

    if(insertRecord) {
      insert pbEntry;
    }

    return pbEntry;
  }
  
  public static ThoughtStarter_RFP__c createThoughtStarterRFP(Boolean insertRecord, Opportunity testOpportunity, Id RecordTypeId, user u){
    ThoughtStarter_RFP__c TRFP = new ThoughtStarter_RFP__c();
    TRFP.Opportunity__c = testOpportunity.id;
    TRFP.name = 'testTRFP';
    TRFP.RecordTypeId = RecordTypeId;
    TRFP.Clicks__c = true;
    TRFP.CTR__c  = 10;
    TRFP.End_Actions__c = false;
    TRFP.Leads__c = false;
    TRFP.Brand_Exposure__c = false;
    TRFP.Sales_Dev_Needed__c = true;
    TRFP.Sales_Developer__c = u.id;

    if(insertRecord) {
        insert TRFP;
    }

    return TRFP;
  }
  
  public static OppUpdateLastModifiedNumberOfDays__c createOppUpdateLastModifiedNOD(Boolean insertRecord) {
    OppUpdateLastModifiedNumberOfDays__c testOULMNOD = new OppUpdateLastModifiedNumberOfDays__c();
    testOULMNOD.Name = 'StandardDaysCount';
    testOULMNOD.Number_of_Days__c = 90;
    
    if(insertRecord) {
      insert testOULMNOD;
    }

    return testOULMNOD;
  }

    public static void createCBSSCustomSettings() {
      DefaulCBSSValues__c defCBSScustomSetting = new DefaulCBSSValues__c();
      defCBSScustomSetting.Name = 'InvoiceTemplate';
      defCBSScustomSetting.Phone__c = '(800)843-4983';
      defCBSScustomSetting.Email__c = 'theknotaccounting@xogrp.com';
      insert defCBSScustomSetting;
    }

  /**
   *   [buildZQUTestObjects: This method consists of the data usually needed by test classes]
   *
   *   @author [Scott Yang]
   *   @date   2016-Dec-12
   *   @return {Map<String, SObject>}: Map containing object Name as key and the object itself as the value
   */
  public static Map<String, SObject> buildZQUTestObjects(Boolean buildSubscriptionData) {
    List<RecordType> localRecordTypeList = [SELECT Id, Name, SObjectType FROM RecordType WHERE Name LIKE '%local%' AND IsActive = true];
    Map<String, Id> localRecordTypeMap = new Map<String, Id>();
    for(Integer i = 0; i < localRecordTypeList.size(); i++) {
      RecordType currentRecordType = localRecordTypeList[i];
      localRecordTypeMap.put(currentRecordType.SObjectType, currentRecordType.Id);
    }

    Map<String, SObject> objectMap = new Map<String, SObject>();

    // Create Quote PDF Config
    generateQuotePdfConfig(true);

    // Create Inventory Offsets
    generateInventoryExpireDateOffsets(true);

    // CSP-1999
    // Create Brand
    // Brand__c testBrand = createBrand(false);
    // if(localRecordTypeMap.containsKey('Brand__c')) {
    //   testBrand.RecordTypeId = localRecordTypeMap.get('Brand__c');
    // }
    // insert testBrand;

    // objectMap.put('Brand__c', testBrand);
    // CSP-1999
    // Create Region
    // Region__c testRegion = createRegion(true, testBrand);
    Region__c testRegion = createRegion(true);
    objectMap.put('Region__c', testRegion);

    // create market 
    Market__c wtfMarket = createMarket(false, testRegion);
    wtfMarket.Market_ID__c = '222';
    insert wtfMarket;
    objectMap.put('Market__c', wtfMarket);

    // create Account
    Account testAccount = createAccount(true);
    objectMap.put('Account', testAccount);

    // create Contact 
    Contact testContact = createContact(true, testAccount);
    objectMap.put('Contact', testContact);

    // create Customer Account
    Zuora__CustomerAccount__c testCustomerAccount = createCustomerAccount(true,testAccount);
    objectMap.put('Zuora__CustomerAccount__c', testCustomerAccount);

    // create Opportunity 
    Opportunity testOpportunity = createOpportunity(false, testAccount, testContact);
    testOpportunity.Lost_Reason__c = 'Some Reason';
    testOpportunity.Lost_Reason_Details__c = 'Something';

    insert testOpportunity;

    objectMap.put('Opportunity', testOpportunity);
    if(buildSubscriptionData) {
      objectMap.putAll(buildSubscriptionData(testAccount, testContact, testOpportunity, testCustomerAccount));
    }
    return objectMap;
  }


  /**
   *   [buildZQUTestObjects: This method consists of the data usually needed by test classes]
   *
   *   @author [Ruchit S]
   *   @date   2016-11-02
   *   @return {Map<String, SObject>}: Map containing object Name as key and the object itself as the value
   */
  public static Map<String, SObject> buildZQUTestObjects() {
    List<RecordType> localRecordTypeList = [SELECT Id, Name, SObjectType FROM RecordType WHERE Name LIKE '%local%' AND IsActive = true];
    Map<String, Id> localRecordTypeMap = new Map<String, Id>();
    for(Integer i = 0; i < localRecordTypeList.size(); i++) {
      RecordType currentRecordType = localRecordTypeList[i];
      localRecordTypeMap.put(currentRecordType.SObjectType, currentRecordType.Id);
    }

    Map<String, SObject> objectMap = new Map<String, SObject>();

    // Create inventory offsets
    generateInventoryExpireDateOffsets(true);

    // Generate Quote PDF Config custom setting record
    generateQuotePdfConfig(true);

    // CSP-1999
    // Create Brand
    // Brand__c testBrand = createBrand(false);
    // if(localRecordTypeMap.containsKey('Brand__c')) {
    //   testBrand.RecordTypeId = localRecordTypeMap.get('Brand__c');
    // }
    // insert testBrand;
    // objectMap.put('Brand__c', testBrand);
    // CSP-1999
    // Create Region
    // Region__c testRegion = createRegion(true, testBrand);
    Region__c testRegion = createRegion(true);
    objectMap.put('Region__c', testRegion);

    // create Market
    Market__c wtfMarket = createMarket(false, testRegion);
    wtfMarket.Market_ID__c = '222';
    insert wtfMarket;

    // create Account
    Account testAccount = createAccount(true);
    objectMap.put('Account', testAccount);

    // create Contact
    Contact testContact = createContact(true, testAccount);
    objectMap.put('Contact', testContact);

    // create Opportunity
    Opportunity testOpportunity = createOpportunity(false, testAccount, testContact);
    testOpportunity.Lost_Reason__c = 'Some Reason';
    testOpportunity.Lost_Reason_Details__c = 'Something';
    insert testOpportunity;
    objectMap.put('Opportunity', testOpportunity);

    // create Customer Account
    Zuora__CustomerAccount__c testCustomerAccount = createCustomerAccount(true, testAccount);
    objectMap.put('Zuora__CustomerAccount__c', testCustomerAccount);

    // create Quote
    zqu__Quote__c testQuote = createQuote(true, testOpportunity, testAccount, testContact);
    objectMap.put('zqu__Quote__c', testQuote);

    // create QuoteAmendment
    zqu__QuoteAmendment__c testQuoteAmmendment = createQuoteAmendment(true, testQuote);
    objectMap.put('zqu__QuoteAmendment__c', testQuoteAmmendment);

    // create Product
    zqu__ZProduct__c testProduct = createProduct(true);
    objectMap.put('zqu__ZProduct__c', testProduct);

    // create local product. Zuora upgrade has moved products from ZProduct to Product2
    Product2 testLocalProduct = createLocalProduct2(true);
    objectMap.put('Product2', testLocalProduct);

    // create Zuora Product
    Zuora__Product__c testZuoraProduct = createZuoraProduct(true);
    objectMap.put('Zuora__Product__c', testZuoraProduct);

    // create Product Rate Plan
    zqu__ProductRatePlan__c testProductRatePlan = createProductRatePlan(true, testProduct);
    objectMap.put('zqu__ProductRatePlan__c', testProductRatePlan);

    // create Quote Rate Plan
    zqu__QuoteRatePlan__c testQuoteRatePlan = createQuoteRatePlan(true, testQuote, testProductRatePlan, testQuoteAmmendment);
    objectMap.put('zqu__QuoteRatePlan__c', testQuoteRatePlan);

    // create Invoice
    Zuora__ZInvoice__c testZInvoice =  createInvoice(true, testAccount, testCustomerAccount); 
    objectMap.put('Zuora__ZInvoice__c', testQuoteRatePlan);

    // create Inventory
    Inventory__c testInventory = createInventory(true, testProductRatePlan);
    objectMap.put('Inventory__c', testInventory);

    // create Waitlist
    Waitlist__c testWaitlist = createWaitlist(true, testProductRatePlan);
    objectMap.put('Waitlist__c', testWaitlist);

    // Create Subscription with a linked quote
    Zuora__Subscription__c testSubscription = createSubscription(false, testAccount);
    testSubscription.CreatingSalesforceQuoteID__c = testQuote.Id;
    testSubscription.Zuora__Zuora_Id__c = 'abc123';
    insert testSubscription;
    objectMap.put('Zuora__Subscription__c', testSubscription);

    // create Subscription Product Charge
    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = createSubscriptionProductCharge(true, testAccount, testSubscription);
    objectMap.put('Zuora__SubscriptionProductCharge__c', testSubscriptionProductCharge);

    return objectMap;
  }

  public static Map<String, SObject> buildLocalSubscriptionData() {

    Map<String, SObject> objectMap = new Map<String, SObject>();
    Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
    Category__c category = TestClassUtility.createCategory(true);
    Market__c market = TestClassUtility.createMarket(false);
    market.Market_ID__c ='222';
    insert market;
    Zip__c zipCode = TestClassUtility.createZip(true);
    Account testAccount = TestClassUtility.createAccount(false,category,market);
    testAccount.Type = 'Advertiser';
    testAccount.DynamicsAccID__c = 'testDynamicsLeadID';
    testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
    testAccount.BU__c = 'Local';
    insert testAccount;
    Contact testContact = TestClassUtility.createContact(true, testAccount);
    AccountContactRole acr = TestClassUtility.createAccountContactRole(true,testAccount,testContact);  
    Opportunity testOpp = TestClassUtility.createOpportunity(true,testAccount);
    Zuora__Subscription__c testSub = TestClassUtility.createSubscription(true,testAccount);
    zqu__Quote__c testQuote = TestClassUtility.createQuote(true, testOpp, testAccount, testContact);
    objectMap.put('Category__c', category);
    objectMap.put('Market__c', market);
    objectMap.put('Zip__c', zipCode);
    objectMap.put('Account', testAccount);
    objectMap.put('Contact', testContact);
    objectMap.put('AccountContactRole', acr);
    objectMap.put('Opportunity', testOpp);
    objectMap.put('Zuora__Subscription__c', testSub);
    objectMap.put('zqu__Quote__c', testQuote);
    return objectMap;

  }
  
  public static Id getRecordTypeIdByName(String sobjType, Schema.DescribeSObjectResult d, String name)
  { 
    RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType=: sobjType LIMIT 1];
    Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
    Schema.RecordTypeInfo rtByName =  rtMapByName.get(name);
    return rtByName.getRecordTypeId();
  }

}