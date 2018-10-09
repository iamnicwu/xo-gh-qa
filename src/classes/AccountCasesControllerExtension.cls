/**
 * Controller extension for looking up an account related to a list of Cases.
 */
public with sharing class AccountCasesControllerExtension {
  public Id recordId {get; set;}


  public AccountCasesControllerExtension(ApexPages.StandardSetController stdController) {
    // Get the Account assoicated with the cases set via the parameters. 
    this.recordId = ApexPages.currentPage().getParameters().get('id');
  }
}