trigger InvoiceLineItemsTrigger on c2g__codaInvoiceLineItem__c (after delete, after insert, after update, 
before insert) {


 	if(trigger.isBefore)
        InvoiceLineItemsTriggerMethods.populateFields(trigger.new);
     
    if(trigger.isAfter)
    {
        if(trigger.isInsert || trigger.isUpdate)
            InvoiceLineItemsTriggerMethods.updateOppLineItemSubsLineBookingEvent(trigger.new);
        if(trigger.isDelete)
        {
           InvoiceLineItemsTriggerMethods.updateOppLineItemSubsLineBookingEvent(trigger.old);  
        }
    }
    
}