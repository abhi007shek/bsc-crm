trigger AB_SpecialEventBookingPriceReassignment on Special_Event_Booking__c (before delete)
{
	List<Special_Event_Booking__c> bookings = new List<Special_Event_Booking__c>();
	List<Id> bookingIds = new List<Id>();
	for (Special_Event_Booking__c booking : trigger.old)
	{
		if (booking.Booking_Fee__c > 0)
		{
			/*	Primary Event Booking object being deleted
				reassign booking price to other Event Booking */
			bookings.add(booking);
			bookingIds.add(booking.Id);
		}
	}
	if (!bookings.isEmpty())
		AB_SpecialEventBookingReassignmentHelper.ReassignSpecialEventBookingPrices(bookings);
}