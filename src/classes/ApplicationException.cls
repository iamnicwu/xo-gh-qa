/*
Created: 02/05/2015
Author: Steve O'Neal
Purpose: Salesforce does not allow you to throw an Exception explicitely.
	The Application Exception is just an Exception that can be instantiated.
	This allows a developer to bubble an error message whenever it is needed.
*/
public class ApplicationException extends Exception {
}