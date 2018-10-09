/* 
<class>
  <name>FeatureRequestedCancelledController</name>
  <purpose>Manage the FRC</purpose>
  <created>
    <by>Scott</by>
  </created>

  Rewrite the all logic for ticket CSP-2659
</class>
*/
public without sharing class FeatureRequestedCancelledController {
  // current Case Id
  public String caseId{get;set;}

  // used for getting case Id for use click the edit link of one record
  public Feature_Requested_Cancelled__c featureRequestedCancelled{get;set;}

  // retrieve existing Feature_Requested_Cancelled__c for current Case, the key Id stands for Subscription_Product_Charge__c 
  // on Feature_Requested_Cancelled__c object
  public Map<String, Feature_Requested_Cancelled__c> existingFeatureRCMap{get;set;}

  // Wrap subsProductCharge and Feature_Requested_Cancelled__c
  public List<SubsPCWrapper> subsPCWrappers{get;set;}

  // the FRC list which we need to deleted
  public List<Feature_Requested_Cancelled__c> noChargeFRCList{get;set;}

  public Boolean haveSubsPC{get; set;}

  public FeatureRequestedCancelledController(ApexPages.StandardController controller) {
    
    featureRequestedCancelled = new Feature_Requested_Cancelled__c();
    existingFeatureRCMap = new Map<String, Feature_Requested_Cancelled__c>();
    featureRequestedCancelled = (Feature_Requested_Cancelled__c)controller.getRecord();
    noChargeFRCList = new List<Feature_Requested_Cancelled__c>();
    subsPCWrappers = new List<SubsPCWrapper>();

    // Get the caseId
    if(String.isBlank(featureRequestedCancelled.Case__c)){
      featureRequestedCancelled.Case__c = ApexPages.currentPage().getParameters().get('caseId');
    }

    caseId = featureRequestedCancelled.Case__c;

    // retrieve the case and the all FRCs under the case.
    Case currentCase = CaseService.getInstance().getCaseWithFeatureRequestCancelled(caseId);

    for(Feature_Requested_Cancelled__c frc : currentCase.Feature_Requested_Cancelled__r){
      // get the all FRCs which has Subscription_Product_Charge__c
      if (String.isNotBlank(frc.Sub_Product_Charge_Number__c)) {
        existingFeatureRCMap.put(frc.Sub_Product_Charge_Number__c, frc);
      }
      // get the all FRCs which has NO Subscription_Product_Charge__c
      if (String.isBlank(frc.Subscription_Product_Charge__c)) {
        noChargeFRCList.add(frc);
      }
    }                      

    // retrieve all Active Zuora__SubscriptionProductCharge__c for Account
    // CSP-2514 Add/Remove Fields from Features Requested Cancelled              
    List<Zuora__SubscriptionProductCharge__c> sPCList = SubscriptionProductChargeService.getInstance().getActiveForAccount(currentCase.AccountId);

    for(Zuora__SubscriptionProductCharge__c sPC : sPCList){
      SubsPCWrapper wrapper = new SubsPCWrapper();
      wrapper.subsPC = sPC;
      // if there is a FRC under the Charge, we should show the FRC status on the page
      if(existingFeatureRCMap.containsKey(sPC.Zuora__ChargeNumber__c)){
        Feature_Requested_Cancelled__c frc = existingFeatureRCMap.get(sPC.Zuora__ChargeNumber__c);
        wrapper.fRC.Status__c = frc.Status__c;
        // wrapper.status = frc.Status__c;

        wrapper.isAdded = true;
      }
      // for the ticket CSP-2659, we should show all the charge on the page
      subsPCWrappers.add(wrapper);
    }  

    if(subsPCWrappers.size()>0){
      haveSubsPC = true;
    }    

    
    System.debug(LoggingLevel.INFO, '*** subsPCWrappers construct: ' + subsPCWrappers);
  }

  /**
   *   [retrieve Status field value on Feature_Requested_Cancelled__c]
   *
   *   @author [Scott Yang]
   *   @date   2017-09-18
   *   @return [description]
   */
  public List<SelectOption> getFRCStatus(){
    return FeatureRequestedCancelService.getInstance().getStatusOptions();
  }


  /**
   *   [Override Standard Save function]
   *   
   *   @author [Scott Yang]
   *   @date   2017-09-18
   *   @return [description]
   *   update by Tony for ticket CSP-2659
   *   upsert all the FRC user checked by the uniqueId
   */
  public PageReference Save() {

    String salesRepName = '';
    List<Feature_Requested_Cancelled__c> upsertFRCList = new List<Feature_Requested_Cancelled__c>();
    // retrieve checked SubsPCWrappers
    for(SubsPCWrapper wrapper : subsPCWrappers){
      // if the FRC is checked, we should added the record to upsert ist
      if(wrapper.isAdded){

        salesRepName = wrapper.subsPC.Zuora__Subscription__r.Sales_Rep__r.FirstName + ' ' + wrapper.subsPC.Zuora__Subscription__r.Sales_Rep__r.LastName;

        Feature_Requested_Cancelled__c currentFRC = new Feature_Requested_Cancelled__c();
        currentFRC.Case__c = caseId;
        currentFRC.Subscription_Product_Charge__c = wrapper.subsPC.Id;
        currentFRC.UniqueId__c = caseId + wrapper.subsPC.Id;
        currentFRC.Status__c = wrapper.fRC.Status__c;
        currentFRC.Period_Text__c = wrapper.subsPC.Zuora__BillingPeriod__c;
        currentFRC.Charge_Price__c = wrapper.subsPC.Zuora__Price__c;
        currentFRC.Rate_Plan_Name_Text__c = wrapper.subsPC.Zuora__RatePlanName__c;
        currentFRC.Sub_Sales_Rep__c = salesRepName;
        currentFRC.Subscription_Sales_Rep__c = wrapper.subsPC.Zuora__Subscription__r.Sales_Rep__c;
        currentFRC.Sub_Product_Charge_Number__c = wrapper.subsPC.Zuora__ChargeNumber__c;
        currentFRC.Sub_Term_End_Date__c = wrapper.subsPC.Zuora__Subscription__r.Zuora__TermEndDate__c;
        currentFRC.Sub_Term_Start_Date__c = wrapper.subsPC.Zuora__Subscription__r.Zuora__TermStartDate__c;
        currentFRC.Subscription_Name__c = wrapper.subsPC.Zuora__Subscription__r.Name;
        currentFRC.Zuora_Version__c = wrapper.subsPC.Zuora__Subscription__r.Zuora__Version__c;
        currentFRC.Subscription_Zuora_Id__c = wrapper.subsPC.Zuora__Subscription__r.Zuora__Zuora_Id__c;
        currentFRC.Charge_Zuora_Id__c = wrapper.subsPC.Zuora__Zuora_Id__c;
        upsertFRCList.add(currentFRC);
      }
      // CSP-2659
      // if the FRC is checked, we should added the record to upsertlist, and remove from the existingFeatureRCMap
      if(existingFeatureRCMap.containsKey(wrapper.subsPC.Zuora__ChargeNumber__c) && wrapper.isAdded) {
        existingFeatureRCMap.remove(wrapper.subsPC.Zuora__ChargeNumber__c);
      }
    }

    // the exist FRCs which unchecked this time, we added the FRCs to delete list noChargeFRCList.
    if(!existingFeatureRCMap.isEmpty()) {
      for (Feature_Requested_Cancelled__c currentFRC :  noChargeFRCList) {
        if (existingFeatureRCMap.containsKey(currentFRC.Sub_Product_Charge_Number__c)) {
          existingFeatureRCMap.remove(currentFRC.Sub_Product_Charge_Number__c);
        }
      }

      if (!existingFeatureRCMap.isEmpty()) {
        noChargeFRCList.addAll(existingFeatureRCMap.values());
      } 
    }

    // upsert multiple Feature_Requested_Cancelled__c
    if(!upsertFRCList.isEmpty()){
      try {
        FeatureRequestedCancelService.getInstance().upsertFRCs(upsertFRCList);
      }catch(Exception ex){
        ExceptionUtility.consumeException(ex, true);
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,Label.FRC_Manage_Page_Upsert_Error));
      }
    }

    // CSP-2659 Features Requested Cancelled Reporting
    // delete the FRCs which are unchecked by user this time or the charge is null
    if(!noChargeFRCList.isEmpty()) {
      try {
        FeatureRequestedCancelService.getInstance().upsertFRCs(noChargeFRCList);
      }catch(Exception ex){
        ExceptionUtility.consumeException(ex, true);
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,Label.FRC_Manage_Page_Delete_Error));
      }
    }

    
    return new PageReference('/' + caseId);
  }
  

  public class SubsPCWrapper{
    // public String status{get; set;}
    public Boolean isAdded{get; set;}
    public Zuora__SubscriptionProductCharge__c subsPC {get; set;}
    public Feature_Requested_Cancelled__c fRC {get; set;}
    public SubsPCWrapper(){
      subsPC = new Zuora__SubscriptionProductCharge__c();
      fRC = new Feature_Requested_Cancelled__c();
    }
  }

}