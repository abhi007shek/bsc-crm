@isTest
private class TestLinkLineItemsController {

	static testMethod void testGetCreditNoteList() {

    	LinkLineItemsController linkLineItems = new LinkLineItemsController();
       	List<c2g__codaCreditNote__c> creditNoteList = linkLineItems.getCreditNoteList();
    }
    
    static testMethod void testCreditNoteLineItems() {
    	
    	LinkLineItemsController linkLineItems = new LinkLineItemsController();
       	List<c2g__codaCreditNote__c> creditNoteList = linkLineItems.getCreditNoteList();
       	
       	if(creditNoteList == null || creditNoteList.size() == 0){
  			createTestData();     		
  			creditNoteList = linkLineItems.getCreditNoteList();
       	}
       	
    	c2g__codaCreditNote__c creditNote = creditNoteList.get(0);
    	
    	System.currentPageReference().getParameters().put( 'creditNote', creditNote.Id);
    	List<c2g__codaCreditNoteLineItem__c> creditLineItems = linkLineItems.getCreditNoteLineItems();
    	c2g__codaCreditNoteLineItem__c creditLine = creditLineItems.get(0);
    	linkLineItems.creditLiToLink = creditLine.Id;
    	linkLineItems.getCreditNoteLineItems();
    }
    
    static testMethod void testUnselectCreditNoteLineItem() {
    	
    	LinkLineItemsController linkLineItems = new LinkLineItemsController();
       	List<c2g__codaCreditNote__c> creditNoteList = linkLineItems.getCreditNoteList();
       	
       	if(creditNoteList == null || creditNoteList.size() == 0){
  			createTestData();     		
  			creditNoteList = linkLineItems.getCreditNoteList();
       	}
       	
    	c2g__codaCreditNote__c creditNote = creditNoteList.get(0);
    	
    	System.currentPageReference().getParameters().put( 'creditNote', creditNote.Id);
    	List<c2g__codaCreditNoteLineItem__c> creditLineItems = linkLineItems.getCreditNoteLineItems();
    	c2g__codaCreditNoteLineItem__c creditLine = creditLineItems.get(0);
    	linkLineItems.creditLiToLink = '';
    	linkLineItems.getCreditNoteLineItems();
    }
    
    
    static testMethod void testInvoiceLineItems() {
    	
    	LinkLineItemsController linkLineItems = new LinkLineItemsController();
       	List<c2g__codaCreditNote__c> creditNoteList = linkLineItems.getCreditNoteList();
    	
    	if(creditNoteList == null || creditNoteList.size() == 0){
  			createTestData();     		
  			creditNoteList = linkLineItems.getCreditNoteList();
       	}
       	
    	c2g__codaCreditNote__c creditNote = creditNoteList.get(0);
    	
    	System.currentPageReference().getParameters().put( 'creditNote', creditNote.Id);
    	linkLineItems.getInvoiceLineItems();
    }
    
    static testMethod void testLinkItems() {
    	
    	LinkLineItemsController linkLineItems = new LinkLineItemsController();
       	List<c2g__codaCreditNote__c> creditNoteList = linkLineItems.getCreditNoteList();
    	
    	if(creditNoteList == null || creditNoteList.size() == 0){
  			createTestData();     		
  			creditNoteList = linkLineItems.getCreditNoteList();
       	}
       	
    	c2g__codaCreditNote__c creditNote = creditNoteList.get(0);
    	
    	System.currentPageReference().getParameters().put( 'creditNote', creditNote.Id);
    	List<c2g__codaCreditNoteLineItem__c> creditLineItems = linkLineItems.getCreditNoteLineItems();
    	c2g__codaCreditNoteLineItem__c creditLine = creditLineItems.get(0);
    	linkLineItems.creditLiToLink = creditLine.Id;

		List<c2g__codaInvoiceLineItem__c> invoiceLineItems = linkLineItems.getInvoiceLineItems(); 
    	c2g__codaInvoiceLineItem__c invoiceLine = invoiceLineItems.get(0);
    	linkLineItems.invoiceLiToLink = invoiceLine.Id;
    	
    	linkLineItems.linkItem();
    }
    
    static testMethod void testUnLinkItem() {
    	
    	LinkLineItemsController linkLineItems = new LinkLineItemsController();
       	List<c2g__codaCreditNote__c> creditNoteList = linkLineItems.getCreditNoteList();
    	
    	if(creditNoteList == null || creditNoteList.size() == 0){
  			createTestData();     		
  			creditNoteList = linkLineItems.getCreditNoteList();
       	}
       	
    	c2g__codaCreditNote__c creditNote = creditNoteList.get(0);
    	
    	System.currentPageReference().getParameters().put( 'creditNote', creditNote.Id);
    	List<c2g__codaCreditNoteLineItem__c> creditLineItems = linkLineItems.getCreditNoteLineItems();
    	c2g__codaCreditNoteLineItem__c creditLine = creditLineItems.get(0);
    	linkLineItems.creditLiToLink = creditLine.Id;

		List<c2g__codaInvoiceLineItem__c> invoiceLineItems = linkLineItems.getInvoiceLineItems(); 
    	c2g__codaInvoiceLineItem__c invoiceLine = invoiceLineItems.get(0);
    	linkLineItems.invoiceLiToLink = '';
    	
    	linkLineItems.linkItem();
    }
    
    static testMethod void testBack() {
    	
    	LinkLineItemsController linkLineItems = new LinkLineItemsController();
       	linkLineItems.back();
    }
    
    static testMethod void testFinish() {
    	
    	LinkLineItemsController linkLineItems = new LinkLineItemsController();
       	List<c2g__codaCreditNote__c> creditNoteList = linkLineItems.getCreditNoteList();
    	
    	if(creditNoteList == null || creditNoteList.size() == 0){
  			createTestData();     		
  			creditNoteList = linkLineItems.getCreditNoteList();
       	}
       	
    	c2g__codaCreditNote__c creditNote = creditNoteList.get(0);
    	
    	System.currentPageReference().getParameters().put( 'creditNote', creditNote.Id);
    	List<c2g__codaCreditNoteLineItem__c> creditLineItems = linkLineItems.getCreditNoteLineItems();
    	c2g__codaCreditNoteLineItem__c creditLine = creditLineItems.get(0);
    	linkLineItems.creditLiToLink = creditLine.Id;

		List<c2g__codaInvoiceLineItem__c> invoiceLineItems = linkLineItems.getInvoiceLineItems(); 
    	c2g__codaInvoiceLineItem__c invoiceLine = invoiceLineItems.get(0);
    	linkLineItems.invoiceLiToLink = invoiceLine.Id;
    	
    	linkLineItems.linkItem();
    	
       	linkLineItems.finish();
    }
    
    static void createTestData(){ 
		List<c2g__codaCreditNoteLineItem__c> creditLineItems = 
			[select c2g__CreditNote__c from c2g__codaCreditNoteLineItem__c];
		for(c2g__codaCreditNoteLineItem__c lineItem: creditLineItems){
			lineItem.Sales_Invoice_Line_Item__c = null;
		}	   	
		update creditLineItems;
    }
    
}