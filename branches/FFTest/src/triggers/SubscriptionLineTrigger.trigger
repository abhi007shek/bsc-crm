trigger SubscriptionLineTrigger on Subscription_Line__c (before update) {

	SubscriptionLineTriggerMethods.updateInvoiceStatus(trigger.newMap);
}