public with sharing class salesInvoiceEmailComController 
{
	public Id salesInvoiceId{get;set;}
	public String taxType{get;set;}
	public String isoCode{get;set;}
	
	public Double netTotal{get;set;}
	public Double taxTotal{get;set;}
	public Double invoiceTotal{get;set;}  
	
	private static List<c2g__codaInvoiceLineItem__c> lineItems;
	
	public c2g__codaInvoiceLineItem__c[] getLineItems()
	{
		if(lineItems == null && salesInvoiceId != null)
		{
			lineItems =  [Select c.c2g__UsePartPeriods__c, c.c2g__UnitPrice__c, c.c2g__UnitOfWork__c, c.c2g__TaxValueTotal__c, c.c2g__TaxValue3__c, c.c2g__TaxValue2__c, c.c2g__TaxValue1__c, c.c2g__TaxRateTotal__c, c.c2g__TaxRate3__c, c.c2g__TaxRate2__c, c.c2g__TaxRate1__c, c.c2g__TaxCode3__c, c.c2g__TaxCode2__c, c.c2g__TaxCode1__r.Name, c.c2g__TaxCode2__r.Name, c.c2g__TaxCode3__r.Name, c.c2g__TaxCode1__c, c.c2g__StartDate__c, c.c2g__Scheduled__c, c.c2g__Quantity__c, c.c2g__Product__r.ProductCode, c.c2g__Product__r.Name, c.c2g__Product__c, c.c2g__PeriodInterval__c, c.c2g__OwnerCompany__c, c.c2g__NumberofJournals__c, c.c2g__NetValue__c, c.c2g__LineNumber__c, c.c2g__LineDescription__c, c.c2g__Invoice__c, c.c2g__IncomeSchedule__c, c.c2g__IncomeScheduleGroup__c, c.c2g__GeneralLedgerAccount__c, c.c2g__ExternalId__c, c.c2g__Dimension4__c, c.c2g__Dimension3__c, c.c2g__Dimension2__c, c.c2g__Dimension1__c, c.SystemModstamp, c.Name, c.LastModifiedDate, c.LastModifiedById, c.IsDeleted, c.Id, /* c.CurrencyIsoCode, */ c.CreatedDate, c.CreatedById From c2g__codaInvoiceLineItem__c c where c.c2g__Invoice__c = :salesInvoiceId order by c.c2g__LineNumber__c];
		}
		return lineItems; 
	}
	
	public salesInvoiceEmailComController.TaxSummary[] getTaxSummaries()
	{
		List<salesInvoiceEmailComController.TaxSummary> taxSummaries = new List<salesInvoiceEmailComController.TaxSummary>(); 
		
		if(taxType != null)
		{
			if(taxType.equals('VAT'))
			{
				salesInvoiceEmailComController.TaxSummary taxsummary = new salesInvoiceEmailComController.TaxSummary();
				c2g__codaInvoiceLineItem__c lineItem = lineItems[0];
				taxsummary.taxCode = lineItem.c2g__TaxCode1__r.Name;
				taxsummary.taxRate = lineItem.c2g__TaxRate1__c + '%';
				taxsummary.netValue =  netTotal;
				taxsummary.taxValue = taxTotal;
				taxSummaries.add(taxsummary); 
				return taxSummaries;	
			}
			else if(taxType.equals('SUT'))
			{
				Map<String,salesInvoiceEmailComController.TaxSummary> taxSummaryMap = new Map<String,salesInvoiceEmailComController.TaxSummary>(); 
				for(c2g__codaInvoiceLineItem__c lineItem : lineItems)
				{
					if(lineItem.c2g__TaxCode1__c != null)
					{
						if(taxSummaryMap.get(lineItem.c2g__TaxCode1__c) == null)
						{
							salesInvoiceEmailComController.TaxSummary taxsummary = new salesInvoiceEmailComController.TaxSummary();
							taxsummary.taxCode = lineItem.c2g__TaxCode1__r.Name;
							taxsummary.taxValue = lineItem.c2g__TaxValue1__c;
							taxSummaryMap.put(lineItem.c2g__TaxCode1__c,taxsummary );
						}
						else
						{
							salesInvoiceEmailComController.TaxSummary taxsummary = taxSummaryMap.get(lineItem.c2g__TaxCode1__c);
							taxsummary.taxValue = taxsummary.taxValue + lineItem.c2g__TaxValue1__c;
							taxSummaryMap.put(lineItem.c2g__TaxCode1__c,taxsummary );
						}
					}
					
					if(lineItem.c2g__TaxCode2__c != null)
					{
						if(taxSummaryMap.get(lineItem.c2g__TaxCode2__c) == null)
						{
							salesInvoiceEmailComController.TaxSummary taxsummary = new salesInvoiceEmailComController.TaxSummary();
							taxsummary.taxCode = lineItem.c2g__TaxCode2__r.Name;
							taxsummary.taxValue = lineItem.c2g__TaxValue2__c;
							taxSummaryMap.put(lineItem.c2g__TaxCode2__c,taxsummary );
						}
						else
						{
							salesInvoiceEmailComController.TaxSummary taxsummary = taxSummaryMap.get(lineItem.c2g__TaxCode2__c);
							taxsummary.taxValue = taxsummary.taxValue + lineItem.c2g__TaxValue2__c; 
							taxSummaryMap.put(lineItem.c2g__TaxCode2__c,taxsummary );
						}
					}
					
					if(lineItem.c2g__TaxCode3__c != null)
					{
						if(taxSummaryMap.get(lineItem.c2g__TaxCode3__c) == null)
						{
							salesInvoiceEmailComController.TaxSummary taxsummary = new salesInvoiceEmailComController.TaxSummary();
							taxsummary.taxCode = lineItem.c2g__TaxCode3__r.Name;
							taxsummary.taxValue = lineItem.c2g__TaxValue3__c;
							taxSummaryMap.put(lineItem.c2g__TaxCode3__c,taxsummary );
						}
						else
						{
							salesInvoiceEmailComController.TaxSummary taxsummary = taxSummaryMap.get(lineItem.c2g__TaxCode3__c);
							taxSummaryMap.remove(lineItem.c2g__TaxCode3__c);
							taxsummary.taxValue = taxsummary.taxValue + lineItem.c2g__TaxValue3__c; 
							taxSummaryMap.put(lineItem.c2g__TaxCode3__c,taxsummary );
						}
					}
				}
				taxSummaries = taxSummaryMap.values();
			}
		}
		return taxSummaries;
	}
	
	public String getinvoiceCurrencySymbol()
	{	
		if(isoCode != null)
		{
			return CurrencyMetadata.getSymbol(isoCode);
		}
		else
		{
			return '';
		}
	}
		
	public class TaxSummary
	{
		public String taxCode{get;set;}
		public String taxRate{get;set;}
		public Decimal taxValue{get;set;}
		public Decimal netValue{get;set;}
	}
}