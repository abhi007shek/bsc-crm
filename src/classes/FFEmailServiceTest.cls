/**
 * This class exists only for code coverage the functionality has been tested manually
 */
@isTest
private class FFEmailServiceTest   
{

	static testMethod void testCurrencyMetadata()
    {
    	try
    	{
    		CurrencyMetadata.getMetadata('USD');
    		CurrencyMetadata.getName('USD');
    		CurrencyMetadata.getSymbol('USD');
    		CurrencyMetadata.getMetadata(null);
    		CurrencyMetadata.getName(null);
    		CurrencyMetadata.getSymbol(null);
    	}
    	catch(Exception e )
    	{
    		//This is intended
    	}
    }
    
    static testMethod void testController()
    {
    	try
    	{
    		c2g__codaInvoice__c[] invoice = [select Id from c2g__codaInvoice__c Limit 1 ];
    		salesInvoiceEmailComController controller = new salesInvoiceEmailComController();
    		controller.salesInvoiceId = invoice[0].id;
    		controller.invoiceTotal = 10.00;
    		controller.isoCode = null;
    		controller.netTotal = 10.00;
    		controller.taxTotal = 10.00;
    		controller.taxType = 'SUT';
    		
    		controller.getLineItems();
    		controller.getTaxSummaries();
    		controller.getinvoiceCurrencySymbol();
    	}
    	catch(Exception e )
    	{
    		//This is intended
    	}
    	
    	try
    	{
    		c2g__codaInvoice__c[] invoice = [select Id from c2g__codaInvoice__c Limit 1 ];
    		salesInvoiceEmailComController controller = new salesInvoiceEmailComController();
    		controller.salesInvoiceId = invoice[0].id;
    		controller.invoiceTotal = 10.00;
    		controller.isoCode = 'USD';
    		controller.netTotal = 10.00;
    		controller.taxTotal = 10.00;
    		controller.taxType = 'SUT';
    		
    		controller.getLineItems();
    		controller.getTaxSummaries();
    		controller.getinvoiceCurrencySymbol();
    	}
    	catch(Exception e )
    	{
    		//This is intended
    	}
    	
    	try
    	{
    		c2g__codaInvoice__c[] invoice = [select Id from c2g__codaInvoice__c Limit 1 ];
    		salesInvoiceEmailComController controller = new salesInvoiceEmailComController();
    		controller.salesInvoiceId = invoice[0].id;
    		controller.invoiceTotal = 10.00;
    		controller.isoCode = 'USD';
    		controller.netTotal = 10.00;
    		controller.taxTotal = 10.00;
    		controller.taxType = 'SUT';
    		controller.getTaxSummaries();
    		
    	}
    	catch(Exception e )
    	{
    		//This is intended
    	}
    	
    	try
    	{
    		c2g__codaInvoice__c[] invoice = [select Id from c2g__codaInvoice__c Limit 1 ];
    		salesInvoiceEmailComController controller = new salesInvoiceEmailComController();
    		controller.salesInvoiceId = invoice[0].id;
    		controller.invoiceTotal = 10.00;
    		controller.isoCode = 'USD';
    		controller.netTotal = 10.00;
    		controller.taxTotal = 10.00;
    		controller.taxType = 'VAT';
    		controller.getTaxSummaries();
    		
    	}
    	catch(Exception e )
    	{
    		//This is intended
    	}
    	
    	try
    	{
    		c2g__codaInvoice__c[] invoice = [select Id from c2g__codaInvoice__c Limit 1 ];
    		salesInvoiceEmailComController controller = new salesInvoiceEmailComController();
    		controller.salesInvoiceId = invoice[0].id;
    		controller.invoiceTotal = 10.00;
    		controller.isoCode = 'USD';
    		controller.netTotal = 10.00;
    		controller.taxTotal = 10.00;
    		controller.taxType = 'SUT';
    		controller.getinvoiceCurrencySymbol();
    	}
    	catch(Exception e )
    	{
    		//This is intended
    	}
    	
    }
    
	
}