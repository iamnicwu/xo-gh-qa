/**
 * Lightning DTO for a Feature Request Cancled object.
 */
public with sharing class FeatureRequestCanceledDTO {
  @AuraEnabled
  public Id frcId;
  @AuraEnabled
  public Boolean isAdded { get; set; }
  @AuraEnabled
  public String Status { get; set; }
  @AuraEnabled
  public String SubscriptionChargeName;
  @AuraEnabled
  public Id SubscriptionChargeId;
  @AuraEnabled
  public String ProductName;
  @AuraEnabled
  public String RatePlanName;
  @AuraEnabled
  public Date LaunchDate;
  @AuraEnabled
  public String ZuoraAccountName;
  @AuraEnabled
  public String SubscriptionName;
  @AuraEnabled
  public Date SubscriptionEndDate;
  @AuraEnabled
  public String LocationId;
  @AuraEnabled
  public String ListPrice;
  @AuraEnabled
  public Decimal Price;
  @AuraEnabled
  public String BillingPeriod;
  @AuraEnabled
  public String SubProductChargeNumber;
  @AuraEnabled
  public Id spcId;

  public FeatureRequestCanceledDTO(Zuora__SubscriptionProductCharge__c spc) {
    this.isAdded = false;
    this.Status = '';
    this.SubscriptionChargeId = spc.Id;
    this.SubscriptionChargeName = spc.Name;
    this.ProductName = spc.Zuora__Product__r.Name;
    this.RatePlanName = spc.Zuora__RatePlanName__c;
    this.LaunchDate = spc.LDE_Email_Launch_Date__c;
    this.ZuoraAccountName = spc.Zuora__Account__r.Name;
    this.SubscriptionName = spc.Zuora__Subscription__r.Name;
    this.SubscriptionEndDate = spc.Zuora__Subscription__r.Zuora__SubscriptionEndDate__c;
    this.LocationId = spc.LocationVendorDynamicsAccountID__c;
    this.ListPrice = spc.List_Price__c;
    this.Price = spc.Zuora__Price__c;
    this.BillingPeriod = spc.Zuora__BillingPeriod__c;
    this.SubProductChargeNumber = spc.Zuora__ChargeNumber__c;
    this.spcId = spc.Id;
  }
}