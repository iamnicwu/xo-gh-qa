/**
 * Picklist Data Transfer Object.
 */
public with sharing class PicklistValueDTO {
  @AuraEnabled
  public String label {
    get;
    set;
  }

  @AuraEnabled
  public String value {
    get;
    set;
  }

  public PicklistValueDTO(String label, String value) {
    this.label = label;
    this.value = value;
  }
}