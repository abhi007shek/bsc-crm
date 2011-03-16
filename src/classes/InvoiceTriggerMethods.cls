public class InvoiceTriggerMethods
 { 
     public class Test_Exception extends Exception{}
     //Populate Invoice Status field on booking event object, Opportunity Line Item object and Susbscription Line object
     
     
    @future public static void updateInvoiceLineItems(Set<Id> invoiceIdSet)
     {
         
         Map<Id,c2g__codaInvoiceLineItem__c> invoiceLineItemMap = new Map<Id,c2g__codaInvoiceLineItem__c>([Select Id 
                                                                                                               from c2g__codaInvoiceLineItem__c
                                                                                                               where c2g__Invoice__c IN:invoiceIdSet  
                                                                                                         ]);
         update invoiceLineItemMap.values() ;                                                                                                
     }
     
     public static void populateCustomerReference(List<c2g__codaInvoice__c> invoiceList)
     {
     
         for(c2g__codaInvoice__c invoice:invoiceList)
         {
             //throw new Test_Exception('Done'+invoice.Name);
             invoice.c2g__CustomerReference__c = invoice.Name;
         }
     
     } 
          
     public testmethod static void testInvoiceTriggerMethods()
     {
    	// Case 1359 and  1254 -- Added due to Winter 11 FF release where the default company of the user is required to determine the appropriate data
    	c2g__codaUserCompany__c userCompany = [Select id, c.c2g__User__r.Username, c.c2g__Company__c From  c2g__codaUserCompany__c c Where c.c2g__User__r.Username = :UserInfo.getUserName() and c.c2g__Company__r.name='Test - BSC'];
     	
		Test.startTest();
		Id invoiceLineItemId = [Select c.c2g__Invoice__c from c2g__codaInvoiceLineItem__c c Where c.c2g__Invoice__r.c2g__OwnerCompany__c = :userCompany.c2g__Company__c limit 1].c2g__Invoice__c;
                                                                                                           
		Map<Id,c2g__codaInvoice__c> invoiceMap = new Map<Id,c2g__codaInvoice__c>([Select c.Name, c.Id From c2g__codaInvoice__c c Where c.Id = :invoiceLineItemId limit 1]);
         
		InvoiceTriggerMethods.updateInvoiceLineItems(invoiceMap.keySet());
		InvoiceTriggerMethods.populateCustomerReference(invoiceMap.values());
		//update invoiceMap.values();  
		Test.stopTest();       
 
     }
 
 
 
 }