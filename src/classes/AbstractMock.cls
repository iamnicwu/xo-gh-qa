/**
 * Base class for implement the StubProvider Interface.  Used to create stub classes utilized for unit testing.
 */
public abstract with sharing class AbstractMock implements System.StubProvider {

  public static final String UNIMPLEMENTED_METHOD = '{0} must be implemented.';

  /**
   * Base method for overriding method calls.
   *
   * @see StubProvider for parameter information.
   */
  public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType,
      List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {

    return callMockedMethod(stubbedMethodName, listOfArgs);
  }

  /**
   * Default method called if call is made to unstubbed method.
   *
   * @param methodName The mehtod that was called.
   *
   * @return UnsupportedOperationException throws exception.
   */
  protected UnsupportedOperationException newUnsupportedMethodException(String methodName) {
    return new UnsupportedOperationException(String.format(UNIMPLEMENTED_METHOD, new String[] { methodName }));
  }

  protected abstract Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs);
}