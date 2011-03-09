trigger InvoiceTrigger on c2g__codaInvoice__c (before update,after update) {

  if(trigger.isAfter)
      InvoiceTriggerMethods.updateInvoiceLineItems(trigger.newMap.keySet());    
   if(trigger.isBefore)
       InvoiceTriggerMethods.populateCustomerReference(trigger.new);     

}