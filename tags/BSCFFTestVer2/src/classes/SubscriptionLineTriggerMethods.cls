public class SubscriptionLineTriggerMethods
{

    public static void updateInvoiceStatus(Map<Id,Subscription_Line__c> subsLineMap)
    {
    
        for(c2g__codaInvoiceLineItem__c invoiceLineItem:[Select c2g__Invoice__r.Copy_Invoice_Status__c,
                                                                c2g__Invoice__r.c2g__InvoiceStatus__c,
                                                                SL__c
                                                                from c2g__codaInvoiceLineItem__c
                                                                where SL__c IN:subsLineMap.keySet()
                                                                ])
       {
                                                                                                               
            if(subsLineMap.containsKey(invoiceLineItem.SL__c))
            {
                Subscription_Line__c subsLine = subsLineMap.get(invoiceLineItem.SL__c);
                if(invoiceLineItem.c2g__Invoice__r.c2g__InvoiceStatus__c == 'Discarded')
                {    
                    subsLine.Invoice_Status__c = 'Not-Invoiced'; 
                }
                else{
                
                    subsLine.Invoice_Status__c = invoiceLineItem.c2g__Invoice__r.Copy_Invoice_Status__c;
                    if(subsLine.Invoice_Status__c == 'Paid')
                    {
                         subsLine.Invoice_Paid_Date__c = Date.today();
                    }
                }
                
                 
            }    
        }
        
    }
    public testmethod static void testSubscriptionLineTriggerMethods()
    {
              Subscription_Line__c subsLine = [Select Id from Subscription_Line__c limit 1];
              c2g__codaInvoiceLineItem__c invoiceLineItem = [Select Id,SL__c,c2g__Invoice__c from c2g__codaInvoiceLineItem__c where c2g__Invoice__c='a1ZD0000000TTYV' limit 1];
              c2g__codaInvoice__c invoice = [Select c.Id, c.Copy_Invoice_Status__c From c2g__codaInvoice__c c where Id=:invoiceLineItem.c2g__Invoice__c limit 1];
              invoice.Copy_Invoice_Status__c = 'Paid';
              update invoice;
              Map<Id,Subscription_Line__c> subsLineMap= new Map<Id,Subscription_Line__c>();
              subsLineMap.put(subsLine.Id,subsLine);
              invoiceLineItem.SL__c = subsLine.Id;
              update invoiceLineItem;
              SubscriptionLineTriggerMethods.updateInvoiceStatus(subsLineMap);
        
    }



























}