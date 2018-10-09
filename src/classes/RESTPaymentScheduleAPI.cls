@RestResource(urlMapping='/PaymentSchedule/*')
global with sharing class RESTPaymentScheduleAPI {

	/**
	 *   "generatePaymentSchedulePDF" is a hacky workaround for generating a Payment Schedule PDF in a transaction that requires
	 *   callouts to happen after DML operations (part of the AutoGenerateQuotePdf.generatePdf method logic)
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2016-09-22
	 *   @param  {Id}   quoteId
	 *   @param  {Id}   opportunityId
	 *   @param  {String}   quoteName
	 *   @return {String}
	 */
    @HttpPost
    global static String generatePaymentSchedulePDF(Id quoteId, Id opportunityId, String quoteName) {
    	Map<String, Boolean> successMap = new Map<String, Boolean>();
    	try {
			System.debug('payment schedule being qenerated for quote: ' + quoteId + ' and opportunity: ' + opportunityId);

			PageReference pdf = Page.ZuoraPaymentScheduleBreakdown;
			pdf.getParameters().put('quoteId',quoteId);

			// create the new attachment
			Attachment paymentBreakdownPDFAttachment = new Attachment();
			Blob body;
			// returns the output of the page as a PDF
			body = pdf.getContent();

			paymentBreakdownPDFAttachment.Body = body;
			paymentBreakdownPDFAttachment.Name = quoteName + '_PSB.pdf';
			paymentBreakdownPDFAttachment.IsPrivate = false;

			// attach the pdf to the opportunity record 
			paymentBreakdownPDFAttachment.ParentId = opportunityId;

			insert paymentBreakdownPDFAttachment;
			successMap.put('success', true);
		}
		catch (Exception e) {
			System.debug(e.getMessage());
			ExceptionUtility.consumeException(e, true);
			successMap.put('success', false);
		}

		return JSON.serialize(successMap);
    }
}