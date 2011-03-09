trigger BookingEventTrigger on Special_Event_Booking__c (before update) {

	BookingEventTriggerMethods.updateInvoiceStatus(trigger.newMap);
}