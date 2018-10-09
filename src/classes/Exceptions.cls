/**
 * Exceptions used in application.
 */
public with sharing class Exceptions {
  public with sharing class NotFoundException extends Exception {}
  public with sharing class ServiceException extends Exception {}
  public with sharing class MockException extends Exception {}
}