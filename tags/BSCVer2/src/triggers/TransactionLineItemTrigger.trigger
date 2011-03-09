trigger TransactionLineItemTrigger on c2g__codaTransactionLineItem__c (after delete, after insert, after update) {

	if(trigger.isInsert || trigger.isUpdate)
        TransactionLineItemMethods.copyStatusPayment(trigger.newMap.keySet());
    
    if(trigger.isDelete)  
       TransactionLineItemMethods.copyStatusPayment(trigger.oldMap.keySet());


}