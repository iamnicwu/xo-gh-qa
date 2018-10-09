/**
 * Interface containing methods Trigger Handlers must implement to enforce best practice
 * and bulkification of triggers.
 *
 * Always add field validation to the after methods.
 * If you need data to persist across the before and after trigger consider the use of static variables.
 * Don't put SOQL inside loops or any of the before and after methods.
 */
global interface XOTrigger
{
  /**
   * bulkBefore
   *
   * This method is called prior to execution of a BEFORE trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
  void bulkBefore();
 
  /**
   * bulkAfter
   *
   * This method is called prior to execution of an AFTER trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
  void bulkAfter();

  /**
   * beforeInsert
   *
   * This method is called iteratively for each record to be inserted during a BEFORE
   * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
   */
  void beforeInsert(SObject so);

  /**
   * beforeUpdate
   *
   * This method is called iteratively for each record to be updated during a BEFORE
   * trigger.
   */
  void beforeUpdate(SObject oldSo, SObject so);

  /**
   * beforeDelete
   *
   * This method is called iteratively for each record to be deleted during a BEFORE
   * trigger.
   */
  void beforeDelete(SObject so);

  /**
   * afterInsert
   *
   * This method is called iteratively for each record inserted during an AFTER
   * trigger. Always put field validation in the 'After' methods in case another trigger
   * has modified any values. The record is 'read only' by this point.
   */
  void afterInsert(SObject so);

  /**
   * afterUpdate
   *
   * This method is called iteratively for each record updated during an AFTER
   * trigger.
   */
  void afterUpdate(SObject oldSo, SObject so);

  /**
   * afterDelete
   *
   * This method is called iteratively for each record deleted during an AFTER
   * trigger.
   */
  void afterDelete(SObject so);

  /**
   * beforeAndFinally
   *
   * This method is called once all records have been processed by the trigger in the "before" context. Use this
   * method to accomplish any final operations such as creation or updates of other records.
   */
  void beforeAndFinally();

  /**
   * afterAndFinally
   *
   * This method is called once all records have been processed by the trigger in the "after" context. Use this
   * method to accomplish any final operations such as creation or updates of other records.
   */
  void afterAndFinally();
}