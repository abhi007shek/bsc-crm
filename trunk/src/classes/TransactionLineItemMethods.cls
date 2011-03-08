public with sharing class TransactionLineItemMethods {

    public class Test_Exception extends Exception{}
     public static void copyStatusPayment(Set<Id> transLineId)
     { 
     
         Map<Id,Double> DocumentTotal = new Map<Id,Double>();
         Map<Id,Double> DocumentOutstandingTotal = new Map<Id,Double>();
         List<c2g__codaTransactionLineItem__c> transLineItemsList = new List<c2g__codaTransactionLineItem__c>([Select Id,
                                                                                                                       c2g__Transaction__c,
                                                                                                                       c2g__AccountRollup__c,
                                                                                                                       c2g__DocumentValue__c,
                                                                                                                       c2g__DocumentOutstandingValue__c,
                                                                                                                       c2g__LineType__c
                                                                                                                       from c2g__codaTransactionLineItem__c
                                                                                                                       where Id In:transLineId]);
         Set<Id> transactionId = new Set<Id>();
         List<c2g__codaInvoice__c> updateInvoice = new List<c2g__codaInvoice__c>();
         //Transaction Id
         for(c2g__codaTransactionLineItem__c transLineItem:transLineItemsList)
         {
             if(transLineItem.c2g__AccountRollup__c == 'True' && transLineItem.c2g__LineType__c =='Account')
             {
                 //Roll up summary DocumentOutstandingTotal
                 if(!DocumentOutstandingTotal.containsKey(transLineItem.c2g__Transaction__c))
                 {    
                     if(transLineItem.c2g__DocumentOutstandingValue__c == null)
                         DocumentOutstandingTotal.put(transLineItem.c2g__Transaction__c,0);
                     else{
                         DocumentOutstandingTotal.put(transLineItem.c2g__Transaction__c,transLineItem.c2g__DocumentOutstandingValue__c);
                     }     
                 }
                 else{
                     Double value = DocumentOutstandingTotal.get(transLineItem.c2g__Transaction__c);
                     value += transLineItem.c2g__DocumentOutstandingValue__c;
                     DocumentOutstandingTotal.put(transLineItem.c2g__Transaction__c,value);
                 }
                 
                 
                 //Roll up summary DocumentValue
                 if(!DocumentTotal.containsKey(transLineItem.c2g__Transaction__c))
                 {    
                     if(transLineItem.c2g__DocumentValue__c == null)
                         DocumentTotal.put(transLineItem.c2g__Transaction__c,0);
                     else{
                         DocumentTotal.put(transLineItem.c2g__Transaction__c,transLineItem.c2g__DocumentValue__c);
                     }     
                 }
                 else{
                     Double value = DocumentTotal.get(transLineItem.c2g__Transaction__c);
                     value += transLineItem.c2g__DocumentValue__c;
                     DocumentTotal.put(transLineItem.c2g__Transaction__c,value);
                 }
               
               transactionId.add(transLineItem.c2g__Transaction__c);  
             }
             
             
              
         }
         
         
         //Invoice Records
         for(c2g__codaInvoice__c invoice:[Select Id,
                                                 c.c2g__PaymentStatus__c, 
                                                 c.Copy_Invoice_Status__c,
                                                 c.c2g__Transaction__c
                                                 From c2g__codaInvoice__c c
                                                 where c.c2g__Transaction__c IN:transactionId])
         {
             if(DocumentTotal.containsKey(invoice.c2g__Transaction__c)&& DocumentOutstandingTotal.containsKey(invoice.c2g__Transaction__c))
             {
                 if(DocumentOutstandingTotal.get(invoice.c2g__Transaction__c)== 0)
                     invoice.Copy_Invoice_Status__c ='Paid';
                 else{
                     if(DocumentOutstandingTotal.get(invoice.c2g__Transaction__c)== DocumentTotal.get(invoice.c2g__Transaction__c))    
                         invoice.Copy_Invoice_Status__c ='Unpaid';
                     else{
                         invoice.Copy_Invoice_Status__c = 'Part Paid';
                     }
                 }
                 updateInvoice.add(invoice);
             }
         
         }
         
         if(!updateInvoice.isEmpty())        
         {    
             update updateInvoice;
             //throw new Test_Exception (updateInvoice.get(0).Copy_Invoice_Status__c);
         }
     }
    
    public testmethod static void testTransactionLineItemMethods()
    {

        Id transactionId = [Select c.c2g__Transaction__c, c.c2g__Account__c, c.Id From c2g__codaInvoice__c c where c.c2g__Account__c!=null and c.c2g__Transaction__c!=null and c.Id='a1ZD0000000TTYV' limit 1].c2g__Transaction__c;
        Map<Id,c2g__codaTransactionLineItem__c> transId = new Map<Id,c2g__codaTransactionLineItem__c>([Select Id from c2g__codaTransactionLineItem__c  where c2g__Transaction__c=:transactionId limit 4]);
        TransactionLineItemMethods.copyStatusPayment(transId.keySet());
        
        update transId.values();

    }






}