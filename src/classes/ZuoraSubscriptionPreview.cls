public class ZuoraSubscriptionPreview {
	public Boolean success;
	public Double contractedMrr;
	public Double totalContractedValue;
	public Double totalDeltaMrr;
	public Double totalDeltaTcv;
	public Double amount;
	public Double amountWithoutTax;
	public Double taxAmount;
	public String invoiceTargetDate;
	public List<InvoiceItems> invoiceItems;

	public class InvoiceItems {
		public String serviceStartDate;
		public String serviceEndDate;
		public Double chargeAmount;
		public String chargeDescription;
		public String chargeName;
		public String productName;
		public String productRatePlanChargeId;
		public String quantity;
		public String unitOfMeasure;
	}
}