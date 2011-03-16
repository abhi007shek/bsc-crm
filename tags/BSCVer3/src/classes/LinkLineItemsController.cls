/**
 * LinkLineItemsConroller
 *
 * Custom controller to link credit note line items with
 * invoice line items since these are not automatically
 * linked in FinancialForce.com
 *
 **/
public with sharing class LinkLineItemsController {

	/* Field: Invoice line item ID */
	public string invoiceLiToLink{get;set;}
	
	/* Field: Credit note line item ID */
	public string creditLiToLink{get;set;}
	
	/* Constructor */
	public LinkLineItemsController(){
	}
	
	/* The selected credit note */
	private c2g__codaCreditNote__c creditNote;
	
	/* The credit note line items */
	private List<c2g__codaCreditNoteLineItem__c> creditLineItems;
	
	/**
	 * Retrieve list of credit notes which have not had
	 * all their line items linked to invoice line items
	 */
	public List<c2g__codaCreditNote__c> getCreditNoteList(){
	
		List<c2g__codaCreditNote__c> creditNoteList =
			[select Id, Name, c2g__Account__r.Name, c2g__Invoice__c, CreatedById, 
				CreatedDate from c2g__codaCreditNote__c where Id in 
			   	(select c2g__CreditNote__c from c2g__codaCreditNoteLineItem__c 
			   	where Sales_Invoice_Line_Item__c = null) ];
		
		return creditNoteList;
	}
	
	/**
	 * Retrieve all credit note line items for a given credit note or
	 * if a credit note line item has already been selected just retrieve 
	 * that record
	 */
	public List<c2g__codaCreditNoteLineItem__c> getCreditNoteLineItems(){
		
		//Check to see if credit note link has been set to blank
		if(creditLiToLink == ''){
			creditLiToLink = null;
		}
			
		//Initial call of this method uses querystring parameter
		Id creditNoteId = System.currentPageReference().getParameters().get('creditNote');
		
		//If the credit note is not loaded retrieve it
		if(this.creditNote == null || creditNoteId != this.creditNote.Id){
			creditNote = [select Id, c2g__Invoice__c from c2g__codaCreditNote__c where Id = :creditNoteId];
			
			creditLineItems =
			   [select Name, c2g__Product__c, c2g__Quantity__c, c2g__UnitPrice__c,
			   c2g__NetValue__c, Sales_Invoice_Line_Item__r.Name,
			   Sales_Invoice_Line_Item__r.Id
			   from c2g__codaCreditNoteLineItem__c 
			   where c2g__CreditNote__c = :creditNote.Id];
		}
		
		List<c2g__codaCreditNoteLineItem__c> returnLineItems = new List<c2g__codaCreditNoteLineItem__c>();
		
		if(creditLiToLink != null && creditLiToLink != ''){
			
			for(c2g__codaCreditNoteLineItem__c lineItem: creditLineItems){
				if(lineItem.Id == creditLiToLink){
					returnLineItems.add(lineItem);
				}
			}
		} else {
			returnLineItems = creditLineItems;
		}
		
		return returnLineItems;
	}
	
	/**
	 * Retrieve all invoice line items which are linked to the invoice
	 * for which credit note was raised
	 */
	public List<c2g__codaInvoiceLineItem__c> getInvoiceLineItems(){
		
		//Get the current credit note id from the querystring
		Id creditNoteId = System.currentPageReference().getParameters().get('creditNote');
		
		//Retrieve the credit note and related invoice
		c2g__codaCreditNote__c creditNote = [select Id, c2g__Invoice__c from c2g__codaCreditNote__c where Id = :creditNoteId];
		c2g__codaInvoice__c invoice = [select Id from c2g__codaInvoice__c where Id =: creditNote.c2g__Invoice__c];
		
		//Retrieve all invoice line items for this invoice
		List<c2g__codaInvoiceLineItem__c> invoiceItems =
		   [select Id, Name, c2g__Product__c, c2g__Quantity__c, c2g__UnitPrice__c,
		   c2g__NetValue__c, 
		   BEB__r.Name, BEB__r.Event_Start_Date__c, BEB__r.Event_end_Date__c,
		   BEB__r.Status__c, BEB__r.Contact__r.Name, BEB__r.Booking_Fee__c,
		   SL__r.Name, SL__r.Quantity__c, SL__r.Active_Site_Product_Count__c,
		   SL__r.E_Delivery_Number_of_Licences__c
		   from c2g__codaInvoiceLineItem__c 
		   where c2g__Invoice__c = :invoice.Id];
		
		return invoiceItems;
	}
	
	/**
	 * Action method. Creates a link between the credit note line
	 * item and the invoice line item
	 */
	public void linkItem() {
		
		System.debug('*** linking item, creditLiToLink: ' + creditLiToLink + 
			' invoiceLiToLink: ' + invoiceLiToLink);
			
		//Check to see if credit note link has been set to blank
		if(invoiceLiToLink == ''){
			System.debug('*** setting invoiceli to null') ;
			invoiceLiToLink = null;
		}
		
		System.debug('*** Finding the record: ' + creditLiToLink);
		 
		//Get the selected line item and link
		for(c2g__codaCreditNoteLineItem__c lineItem: creditLineItems){
			if(lineItem.Id == creditLiToLink){
				lineItem.Sales_Invoice_Line_Item__c = invoiceLiToLink;
				break;
			} 
		}
		
		//Reset the linking fields
		creditLiToLink = null;
		invoiceLiToLink = null;
    }
    
    /**
     * Action method. Return to the select credit note page
     */
	public PageReference back() {
        return new PageReference('/apex/SelectCreditNote');
    }
    
    /**
     * Action method. Finish and commit the records
     */
	public PageReference finish() {
		
		update this.creditLineItems;
		
        return new PageReference('/apex/SelectCreditNote');
    }
    
}