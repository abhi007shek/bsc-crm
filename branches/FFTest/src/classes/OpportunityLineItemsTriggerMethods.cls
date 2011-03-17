public class OpportunityLineItemsTriggerMethods{
 
     public class Test_Exception extends Exception{}
  
     
     public static void updateOpportunity(Set<Id> lineItemListId) 
     {
         Set<Id> oppId = new Set<Id>();
         for(OpportunityLineItem oppLineItem:[Select OpportunityId from OpportunityLineItem where Id IN:lineItemListId])
         {
            oppId.add(oppLineItem.OpportunityId);
         }
         list<Opportunity> updateOpp = new List<Opportunity>([Select Id from Opportunity where Id IN:oppId]);
         update updateOpp;
     
     }
     
     @future public static void updateOpportunityExt(Set<Id> lineItemListId)
     {
         OpportunityLineItemsTriggerMethods.updateOpportunity(lineItemListId);
     }
    
     
     
     public static void countQuantity (Map<Id,OpportunityLineItem> lineItemMap,Map<Id,OpportunityLineItem>oldLineItemMap)
     {
         
         Map<String,Double> quantityInvoiced = new Map<String,Double>();
         Map<String,Double> quantityPartPaid  = new Map<String,Double>();
         Map<String,Double> quantityPaid  = new Map<String,Double>();
         Map<String,Double> quantityCredited  = new Map<String,Double>();
         
        
         for(c2g__codaInvoiceLineItem__c invoiceLineItem: [Select OPL_ID__c,
                                                                  c2g__Quantity__c,
                                                                  c2g__Invoice__r.c2g__PaymentStatus__c,
                                                                  c2g__Invoice__r.Copy_Invoice_Status__c
                                                                  from c2g__codaInvoiceLineItem__c
                                                                  where OPL_ID__c IN:lineItemMap.KeySet()
                                                                  and c2g__Invoice__r.c2g__InvoiceStatus__c!='Discarded'])
         {                                                          
              
              //throw new Test_Exception('Status2'+invoiceLineItem.c2g__Invoice__r.c2g__PaymentStatus__c);
              //Calculate quantity invoiced   
                 if(!quantityInvoiced.containsKey(invoiceLineItem.OPL_ID__c))
                     quantityInvoiced.put(invoiceLineItem.OPL_ID__c,invoiceLineItem.c2g__Quantity__c);
                  
                 else{
                     Double quantity = quantityInvoiced.get(invoiceLineItem.OPL_ID__c);
                     quantity+= invoiceLineItem.c2g__Quantity__c;
                     quantityInvoiced.put(invoiceLineItem.OPL_ID__c,quantity);
                 }     
             
             //throw new Test_Exception(invoiceLineItem.c2g__Invoice__r.Copy_Invoice_Status__c);
             //Calculate quantity paid   
             if(invoiceLineItem.c2g__Invoice__r.Copy_Invoice_Status__c =='Paid')
             {    
                 if(!quantityPaid.containsKey(invoiceLineItem.OPL_ID__c))
                     quantityPaid.put(invoiceLineItem.OPL_ID__c,invoiceLineItem.c2g__Quantity__c);
              
                 else{
                     Double quantity = quantityPaid.get(invoiceLineItem.OPL_ID__c);
                     quantity+= invoiceLineItem.c2g__Quantity__c;
                     quantityPaid.put(invoiceLineItem.OPL_ID__c,quantity);
                 }      
             }else{
                 
                 quantityPaid.put(invoiceLineItem.OPL_ID__c,0);
             }
             
             //Calculate quantity part paid
             if(invoiceLineItem.c2g__Invoice__r.Copy_Invoice_Status__c =='Part Paid')
             {    
                 if(!quantityPartPaid.containsKey(invoiceLineItem.OPL_ID__c))
                     quantityPartPaid.put(invoiceLineItem.OPL_ID__c,invoiceLineItem.c2g__Quantity__c);
                  
                 else{
                     Double quantity = quantityPartPaid.get(invoiceLineItem.OPL_ID__c);
                     quantity+= invoiceLineItem.c2g__Quantity__c;
                     quantityPartPaid.put(invoiceLineItem.OPL_ID__c,quantity);
                 }     
             }else{
                 
                 quantityPartPaid.put(invoiceLineItem.OPL_ID__c,0);    
             }
             
         }
         
         for(c2g__codaCreditNoteLineItem__c creditNoteItem:[Select Sales_Invoice_Line_Item__r.OPL_ID__c,
                                                                  c2g__Quantity__c 
                                                                  from c2g__codaCreditNoteLineItem__c
                                                                  where Sales_Invoice_Line_Item__r.OPL_ID__c IN:lineItemMap.KeySet()])
         {
             
                //Calculate quantity credited   
                if(!quantityCredited.containsKey(creditNoteItem.Sales_Invoice_Line_Item__r.OPL_ID__c))
                     quantityCredited.put(creditNoteItem.Sales_Invoice_Line_Item__r.OPL_ID__c,creditNoteItem.c2g__Quantity__c);
                  
                else{
                     Double quantity = quantityCredited.get(creditNoteItem.Sales_Invoice_Line_Item__r.OPL_ID__c);
                     quantity+= creditNoteItem.c2g__Quantity__c;
                     quantityCredited.put(creditNoteItem.Sales_Invoice_Line_Item__r.OPL_ID__c,quantity);
                }  
         
         }

         //Update Opportunity line item quantity fields  
         for(OpportunityLineItem lineItem:lineItemMap.values())
         {
             //Quantity invoiced
             if(quantityInvoiced.containsKey(lineItem.Id))
                 lineItem.Quantity_Invoiced__c = quantityInvoiced.get(lineItem.Id);
                 if(lineItem.Invoice_Date__c == null)
                 	lineItem.Invoice_Date__c  = Date.today();	
             else{
                 lineItem.Quantity_Invoiced__c = 0;
             }
             
             //Quantity paid
             if(quantityPaid.containsKey(lineItem.Id))
             {    
             	 lineItem.Quantity_Paid__c = quantityPaid.get(lineItem.Id);
                 //Update the date of the payment
                 if(lineItem.Quantity_Paid__c == lineItem.Quantity)
                 	lineItem.Invoice_Paid_Date__c  = Date.today();	
             }    
             else{
                 lineItem.Quantity_Paid__c = 0;
             }
             //Quantity Part Paid
             if(quantityPartPaid.containsKey(lineItem.Id))
                 lineItem.Quantity_Part_Paid__c = quantityPartPaid.get(lineItem.Id);
             else{
                 lineItem.Quantity_Part_Paid__c  = 0;
             }
            //Calculate quantity credited
             if(quantityCredited.containsKey(lineItem.Id))
                 lineItem.Quantity_Credited__c = quantityCredited.get(lineItem.Id);
             else{
                 lineItem.Quantity_Credited__c = 0;
             }
         }
     
     }
     
     public static testMethod void testOpportunityLineItemTriggerMethods()
     {
         
         
                                   
      	
         Set<Id> invoiceId = new Set<Id>();
        /* List<c2g__codaInvoiceLineItem__c> invoiceLineItemList = new List<c2g__codaInvoiceLineItem__c>
                                                               ([Select Id,
                                                               OPL_ID__c,
                                                               c2g__Invoice__c 
                                                               from c2g__codaInvoiceLineItem__c 
                                                               where OPL_ID__c!=null
                                                               and c2g__Invoice__c='a1ZD0000000TTYV' limit 2 ]);*/ 
    	
    	// Case 1359 and  1254 -- Added due to Winter 11 FF release where the default company of the user is required to determine the appropriate data
    	c2g__codaUserCompany__c userCompany = [Select id, c.c2g__User__r.Username, c.c2g__Company__c From  c2g__codaUserCompany__c c Where c.c2g__User__r.Username = :UserInfo.getUserName() and c.c2g__Company__r.name='Test - BSC'];

        List<c2g__codaInvoiceLineItem__c> invoiceLineItemList = new List<c2g__codaInvoiceLineItem__c>
                                                               ([Select Id,
                                                               OPL_ID__c,
                                                               c2g__Invoice__c 
                                                               from c2g__codaInvoiceLineItem__c 
                                                               where OPL_ID__c!=null
                                                               and c2g__Invoice__r.c2g__OwnerCompany__c = :userCompany.c2g__Company__c
                                                               and c2g__Invoice__r.Copy_Invoice_Status__c <> 'Paid' limit 5 ]); 

         Map<Id,OpportunityLineItem> lineItemMap = new Map<Id,OpportunityLineItem>( [Select Id,
                                                                                           Quantity_Invoiced__c,
                                                                                           Quantity_Paid__c,
                                                                                           Quantity_Part_Paid__c,
                                                                                           Quantity_Credited__c 
                                                                                           from OpportunityLineItem 
                                                                                           //where id = :invoiceLineItemList[0].OPL_ID__c
                                                                                           limit 1]);
        
         
         for(c2g__codaInvoiceLineItem__c invoiceLineItem:invoiceLineItemList )
         {
              invoiceLineItem.OPL_ID__c = lineItemMap.values().get(0).Id;
              invoiceId.add(invoiceLineItem.c2g__Invoice__c);        
         
         }
      
        // update invoiceLineItemList ;
         // List<c2g__codaInvoice__c > invoice = [Select id,Copy_Invoice_Status__c from c2g__codaInvoice__c where Id='a1ZD0000000TTYV' limit 1];
         List<c2g__codaInvoice__c > invoice = [Select id,Copy_Invoice_Status__c from c2g__codaInvoice__c where Id=:invoiceLineItemList[0].c2g__Invoice__c limit 1];
         invoice.get(0).Copy_Invoice_Status__c ='Part Paid';
         //update invoice;                                                   
         
         
         
         
         OpportunityLineItemsTriggerMethods.countQuantity(lineItemMap,lineItemMap);
         invoice.get(0).Copy_Invoice_Status__c ='Paid';
         //invoice.get(1).Copy_Invoice_Status__c ='Paid';
         //update invoice;
         
         OpportunityLineItemsTriggerMethods.countQuantity(lineItemMap,lineItemMap); 
         
         //update lineItemMap.values();
        // Test.startTest();
        // 	OpportunityLineItemsTriggerMethods.updateOpportunityExt(lineItemMap.keySet());
        // test.stopTest();
         
     }
 
 
 }