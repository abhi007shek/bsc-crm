public with sharing class InvoiceLineItemsTriggerMethods {

    public class Test_Exception extends Exception{}
    
    public static  boolean isBookingEvent(String bookingId)
    {
        Schema.DescribeSObjectResult result = Special_Event_Booking__c.SObjectType.getDescribe();
        return(bookingId.trim().startsWith(result.getKeyPrefix()));
    }
    
    public static boolean isOpportunityLineItem(String oppLineItemId)
    {
        Schema.DescribeSObjectResult result = OpportunityLineItem.SObjectType.getDescribe();
        return(oppLineItemId.trim().startsWith(result.getKeyPrefix()));
    }
    
    public static  boolean isSubscriptionLine(String subsLineId)
    {
        Schema.DescribeSObjectResult result = Subscription_Line__c.SObjectType.getDescribe();
        return(subsLineId.trim().startsWith(result.getKeyPrefix()));
    }
    
    
    public static void updateOppLineItemSubsLineBookingEvent(List<c2g__codaInvoiceLineItem__c> invoiceLineItemList)
    {
        
        Set<Id> bookingId = new Set<Id>();
        Set<Id> subsLineId = new Set<Id>();
        Set<Id> oppLineItemId = new Set<Id>();
          
        //Invoice line items
         for(c2g__codaInvoiceLineItem__c invoiceLineItem:invoiceLineItemList)
          {
              if(invoiceLineItem.OPL_ID__c !=null)
                  oppLineItemId.add(invoiceLineItem.OPL_ID__c);
             
              if(invoiceLineItem.BEB__c !=null)
                  bookingId.add(invoiceLineItem.BEB__c);
                  
              if(invoiceLineItem.SL__c !=null)
                  subsLineId.add(invoiceLineItem.SL__c);
                 
          }
          
          if(!oppLineItemId.isEmpty())
          {    
            
            List<OpportunityLineItem> updateOppLineItem = new List<OpportunityLineItem>([Select Id from OpportunityLineItem where Id IN:oppLineItemId]);
            update updateOppLineItem; 
            
          }
          
          if(!bookingId.isEmpty())
          {    
            
            List<Special_Event_Booking__c> updateBooking = new List<Special_Event_Booking__c>([Select Id from Special_Event_Booking__c where Id IN:bookingId]);
            update updateBooking; 
            
          }
          
          if(!subsLineId.isEmpty())
          {    
            
            List<Subscription_Line__c> updateSubsLine = new List<Subscription_Line__c>([Select Id from Subscription_Line__c where Id IN:subsLineId]);
            update updateSubsLine; 
            
          }   
    }

    
    
    
    public static void populateFields(List<c2g__codaInvoiceLineItem__c> invoiceLineItemList)
    {
        Boolean checked = false;
        
        for(c2g__codaInvoiceLineItem__c invoiceLineItem:invoiceLineItemList)
        {
             if(invoiceLineItem.c2g__LineDescription__c !=null && invoiceLineItem.c2g__LineDescription__c != '')
             {   
                //throw new Test_Exception(String.valueOf(invoiceLineItem.c2g__LineDescription__c.split(';')[3]));
                //checked = false;
                
                //Populate (text) lookup field to opportunity line item
                if(InvoiceLineItemsTriggerMethods.isOpportunityLineItem(invoiceLineItem.c2g__LineDescription__c.split(';')[0]))
                {
                    invoiceLineItem.OPL_ID__c = invoiceLineItem.c2g__LineDescription__c.split(';')[0];
                }
                
                //Populate lookup fied to booking event
                if(invoiceLineItem.c2g__LineDescription__c.split(';').size()== 2 || invoiceLineItem.c2g__LineDescription__c.split(';').size()>2 )
                {
                    
                    if(InvoiceLineItemsTriggerMethods.isBookingEvent(invoiceLineItem.c2g__LineDescription__c.split(';')[1]))
                    {   
                        invoiceLineItem.BEB__c = invoiceLineItem.c2g__LineDescription__c.split(';')[1];
                        //invoiceLineItem.c2g__LineDescription__c = '';
                        //checked =true;
                    }
                } 
                //Populate lookup fied to susbscription line 
                if(invoiceLineItem.c2g__LineDescription__c.split(';').size() == 2 || invoiceLineItem.c2g__LineDescription__c.split(';').size()>2)
                {
                    if(InvoiceLineItemsTriggerMethods.isSubscriptionLine(invoiceLineItem.c2g__LineDescription__c.split(';')[1]))
                    {   
                        invoiceLineItem.SL__c = invoiceLineItem.c2g__LineDescription__c.split(';')[1];
                        //invoiceLineItem.c2g__LineDescription__c = '';
                        checked =true;
                    }
                }
                
                if(invoiceLineItem.c2g__LineDescription__c.split(';').size()== 4)
                {
                    invoiceLineItem.c2g__LineDescription__c = invoiceLineItem.c2g__LineDescription__c.split(';')[2]+';'+invoiceLineItem.c2g__LineDescription__c.split(';')[3];
                }
                else{
                    invoiceLineItem.c2g__LineDescription__c = '';
                }
                
               
             }        
        }
    }
    public testmethod static void testInvoiceLineItemTriggerMethods()
    {
         
        Subscription_Line__c subsline = [Select Id from Subscription_Line__c limit 1];
        Special_Event_Booking__c bookingEvt = [Select Id from Special_Event_Booking__c limit 1];
        OpportunityLineItem oppLineItem  =[Select Id from OpportunityLineItem limit 1];
        
        List<c2g__codaInvoiceLineItem__c> invoiceLineItemList= [Select Id,OPL_ID__c,c2g__Invoice__c,SL__c,BEB__c,c2g__LineDescription__c from c2g__codaInvoiceLineItem__c limit 1];
        
        invoiceLineItemList.get(0).c2g__LineDescription__c = oppLineItem.Id+';'+subsline.Id;
        InvoiceLineItemsTriggerMethods.populateFields(invoiceLineItemList);
        
        invoiceLineItemList.get(0).c2g__LineDescription__c = oppLineItem.Id+';'+bookingEvt.Id;
        InvoiceLineItemsTriggerMethods.populateFields(invoiceLineItemList);
                
        update invoiceLineItemList;
         
    }


}