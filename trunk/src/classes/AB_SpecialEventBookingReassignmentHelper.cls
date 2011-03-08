public with sharing class AB_SpecialEventBookingReassignmentHelper
{ 
	public static void ReassignSpecialEventBookingPrices(List<Special_Event_Booking__c> primaryBookings)
	{
		List<Id> parentOpportunities = new List<Id>();
		Map<Id,Special_Event_Booking__c> bookingsToUpdate = new Map<Id,Special_Event_Booking__c>();

		for (Special_Event_Booking__c booking : primaryBookings)
		{
			//	Build a list of parent Opportunity IDs, so we can
			//	locate other Event Bookings for the parent Opportunity
			parentOpportunities.add(booking.Opportunity__c);
		}

		if (!parentOpportunities.isEmpty())
		{
			//	Locate all Event Bookings attached to the 'to be deleted' Event Booking using
			//	a reference to the Event Booking's parent Opportunity, filter by Booking_Fee__c so
			//	we don't get Event Bookings marked for deletion within this class.
			//
			List<Special_Event_Booking__c> altBookings = new List<Special_Event_Booking__c>([
				SELECT
					Id,
					Booking_Fee__c,
					Opportunity__c
				FROM
					Special_Event_Booking__c
				WHERE
					Opportunity__c IN : parentOpportunities
				AND
					(Booking_Fee__c = null
				OR
					Booking_Fee__c = 0)]);

			//
			//	List of Event Bookings to be updated
			//
			Special_Event_Booking__c reassignedBooking;

			for (Special_Event_Booking__c booking : primaryBookings)
			{
				// Loop through the Bookings, re-assigning the Booking Fee to associated Bookings
				if ((reassignedBooking = ReassignBookingPrice(booking, altBookings)) != null)
					bookingsToUpdate.put(reassignedBooking.Id,reassignedBooking);
			}
		}
		// Write changes to db.
		if (!bookingsToUpdate.isEmpty())
			update bookingsToUpdate.values();
	}

	// Booking re-assignment helper, reassigns Booking_Fee__c to a different Event Booking if the primary
	// booking is being deleted.
	private static Special_Event_Booking__c ReassignBookingPrice(
		Special_Event_Booking__c primaryBooking,
		List<Special_Event_Booking__c> alternativeBookings)
	{
		for (Special_Event_Booking__c altBooking : alternativeBookings)
		{
			if (primaryBooking.Opportunity__c == altBooking.Opportunity__c && altBooking.Id != primaryBooking.Id)
			{
				altBooking.Booking_Fee__c = primaryBooking.Booking_Fee__c;
				altBooking.Primary_Booking__c = true;
				return altBooking;
			}
		}
		return null;		
	}
}