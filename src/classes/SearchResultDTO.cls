/**
 * Search Result data transfer object
 */
public with sharing class SearchResultDTO {
  @AuraEnabled public String id { get; set; }
  @AuraEnabled public String resultName { get; set; }

  public SearchResultDTO(String id, String name) {
    this.id = id;
    this.resultName = name;
  }
}