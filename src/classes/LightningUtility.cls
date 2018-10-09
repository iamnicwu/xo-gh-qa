/*
 * Lightning Utilities
 */
public with sharing class LightningUtility {
  public static AuraHandledException createException(String message) {
    AuraHandledException auraException = new AuraHandledException(message);
    auraException.setMessage(message);
    return auraException;
  }
}