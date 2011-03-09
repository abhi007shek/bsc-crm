/*
	Code Coverage - 64% - 07-10-10
	Created by Ben Mansfield 15 July 2010
	Modified by Ben Mansfield 19 July 2010
	
	Description:
		Helper class to work out various event booking related things:
			* Calculating Transfer Costs
			* Calculated Cancellation Costs
			* Retrieving pricebook entry records from a set of product names
*/
public with sharing class BookingHelper
{
	public static Double calculateTransferCost(Special_Event_Booking__c booking, Product2 product)
	{
		if (booking == null || product == null)
			return 0;
		
		Double chargeFee = 0;
		
		Double daysBetween = System.today().daysBetween(booking.Event_Start_Date__c);
		if (daysBetween >= product.Transfer_Charge_Day_1__c)
		{
			chargeFee = (product.Transfer_Charge_Fee_1__c != null ? product.Transfer_Charge_Fee_1__c : 0);
		}
		else if (daysBetween >= product.Transfer_Charge_Day_2__c)
		{
			chargeFee = (product.Transfer_Charge_Fee_2__c != null ? product.Transfer_Charge_Fee_2__c : 0);
		}
		else if (daysBetween >= product.Transfer_Charge_Day_3__c)
		{
			chargeFee = (product.Transfer_Charge_Fee_3__c != null ? product.Transfer_Charge_Fee_3__c : 0);
		}
		else
		{
			chargeFee = (product.Transfer_Charge_Fee_Final__c != null ? product.Transfer_Charge_Fee_Final__c : 0);
		}
		// brm - 19 July 2010 - charge fee is actually a percentage so change it into a decimal before we multiply by booking fee
		Double transferCost = (chargeFee / 100) * (booking.Booking_Fee__c != null ? booking.Booking_Fee__c : 0);
		
		return transferCost;
	}
	
	public static Double calculateCancellationCost(Special_Event_Booking__c booking, Product2 product)
	{
		if (booking == null || product == null)
			return 0;
		
		Double chargeFee = 0;
		
		Double daysBetween = System.today().daysBetween(booking.Event_Start_Date__c);
		if (daysBetween >= product.Cancellation_Charge_Day_1__c)
		{
			chargeFee = (product.Cancellation_Charge_Fee_1__c != null ? product.Cancellation_Charge_Fee_1__c : 0);
		}
		else if (daysBetween >= product.Cancellation_Charge_Day_2__c)
		{
			chargeFee = (product.Cancellation_Charge_Fee_2__c != null ? product.Cancellation_Charge_Fee_2__c : 0);
		}
		else if (daysBetween >= product.Cancellation_Charge_Day_3__c)
		{
			chargeFee = (product.Cancellation_Charge_Fee_3__c != null ? product.Cancellation_Charge_Fee_3__c : 0);
		}
		else
		{
			chargeFee = (product.Cancellation_Charge_Fee_Final__c != null ? product.Cancellation_Charge_Fee_Final__c : 0);
		}
		// brm - 19 July 2010 - charge fee is actually a percentage so change it into a decimal before we multiply by booking fee
		Double transferCost = (chargeFee / 100) * (booking.Booking_Fee__c != null ? booking.Booking_Fee__c : 0);
		
		return transferCost;
	}
	
	public static Map<String, PricebookEntry> getPricebookEntries(String[] productNames){
		
		return getPricebookEntries(null, productNames);
	}

	public static Map<String, PricebookEntry> getPricebookEntries(Id priceBookId, String[] productNames)
	{
		Map<String, PricebookEntry> entries = new Map<String, PricebookEntry>();
		if(priceBookId != null)
			for (PricebookEntry pbe : [
				SELECT
					Id,
					Product2.Name,
					Name
				FROM
					PricebookEntry
				WHERE
					Product2.Name in :productNames
				AND
					PriceBook2Id=:priceBookId])
			{
				entries.put(pbe.Product2.Name, pbe);
			}
		else
			for (PricebookEntry pbe : [
				SELECT
					Id,
					Product2.Name,
					Name
				FROM
					PricebookEntry
				WHERE
					Product2.Name in :productNames])
			{
				entries.put(pbe.Product2.Name, pbe);
			}
		return entries;
	}
	
	@IsTest
	public static void testgetPricebookEntries()
	{
		Product2 prod = new Product2(
			Name = 'Product Test');
		insert prod;
		
		Pricebook2 stdPricebook = [Select Id From Pricebook2 Where IsStandard = true Limit 1];
		
		PricebookEntry pbe = new PricebookEntry();
		pbe.Pricebook2Id = stdPricebook.Id;
		pbe.Product2Id = prod.Id;
		pbe.UnitPrice = 360;
		insert pbe;
		
		Map<String, PricebookEntry> entries = BookingHelper.getPricebookEntries(null, new String[] { 'Product Test' });
		
		entries = BookingHelper.getPricebookEntries(new String[] { 'Product Test' });
		System.assert(entries.containsKey('Product Test'));
		System.assertEquals(pbe.Id, entries.get('Product Test').Id);
	}
	
	@IsTest
	public static void testTransferCost()
	{
		Product2 prod = new Product2(
			Name = 'Product Test',
			Transfer_Charge_Day_1__c = 32,
			Transfer_Charge_Day_2__c = 16,
			Transfer_Charge_Day_3__c = 4,
			Transfer_Charge_Fee_1__c = 10,
			Transfer_Charge_Fee_2__c = 20,
			Transfer_Charge_Fee_3__c = 50,
			Transfer_Charge_Fee_Final__c = 100);
		insert prod;
		
		Pricebook2 stdPricebook = [
			SELECT
				Id
			FROM
				Pricebook2
			WHERE
				IsStandard = true
			LIMIT
				1];
		
		PricebookEntry pbe = new PricebookEntry(
			Pricebook2Id = stdPricebook.Id,
			Product2Id = prod.Id,
			UnitPrice = 360);
		insert pbe;
		
		Special_Event__c event = new Special_Event__c(
		    Product__c = prod.Id,
			StartDate__c = System.today().addDays(12));
		insert event;
		
		Special_Event_Booking__c booking = new Special_Event_Booking__c(
			Special_Event__c = event.Id,
			Booking_Fee__c = 360);
		insert booking;
		
		booking = [
			SELECT
				Id,
				Special_Event__c,
				Booking_Fee__c,
				Event_Start_Date__c
			FROM
				Special_Event_Booking__c 
			WHERE
				Id = :booking.Id Limit 1];
		
		Double transferCost = BookingHelper.calculateTransferCost(booking, prod);
		// Make sure the calculated cost is equal to Charge Fee 3 percentage of Booking Fee
		System.assertEquals((0.5 * 360), transferCost);
		
		// Set up transfer cost to charge day 1 bracket
		event.StartDate__c = System.today() + 34;
		update event;
		
		booking = [
			SELECT
				Id,
				Special_Event__c,
				Booking_Fee__c,
				Event_Start_Date__c
			FROM
				Special_Event_Booking__c 
			WHERE
				Id = :booking.Id
			LIMIT
				1];
		
		transferCost = BookingHelper.calculateTransferCost(booking, prod);
		// Make sure the calculated cost is equal to Charge Fee 1 percentage of Booking Fee
		System.assertEquals((0.1 * 360), transferCost);
		
		// Set up transfer cost to charge day 2 bracket
		event.StartDate__c = System.today() + 17;
		update event;
		
		booking = [
			SELECT
				Id,
				Special_Event__c,
				Booking_Fee__c,
				Event_Start_Date__c
			FROM
				Special_Event_Booking__c 
			WHERE
				Id = :booking.Id
			LIMIT
				1];
		
		transferCost = BookingHelper.calculateTransferCost(booking, prod);
		// Make sure the calculated cost is equal to Charge Fee 2 percentage of Booking Fee
		System.assertEquals((0.2 * 360), transferCost);
		
		// Set up transfer cost to charge final bracket
		event.StartDate__c = System.today() + 1;
		update event;
		
		booking = [
			SELECT
				Id,
				Special_Event__c,
				Booking_Fee__c,
				Event_Start_Date__c
			FROM
				Special_Event_Booking__c 
			WHERE
				Id = :booking.Id
			LIMIT
				1];
		
		transferCost = BookingHelper.calculateTransferCost(booking, prod);
		// Make sure the calculated cost is equal to Charge Fee Final percentage of Booking Fee
		System.assertEquals(360, transferCost);
	}
	
	@IsTest
	public static void testCancelCost()
	{
		Product2 prod = new Product2(
			Name = 'Product Test',
			Cancellation_Charge_Day_1__c = 32,
			Cancellation_Charge_Day_2__c = 16,
			Cancellation_Charge_Day_3__c = 4,
			Cancellation_Charge_Fee_1__c = 10,
			Cancellation_Charge_Fee_2__c = 20,
			Cancellation_Charge_Fee_3__c = 50,
			Cancellation_Charge_Fee_Final__c = 100);
		insert prod;
		
		Pricebook2 stdPricebook = [
			SELECT
				Id
			FROM
				Pricebook2
			WHERE
				IsStandard = true
			LIMIT
				1];
		
		PricebookEntry pbe = new PricebookEntry(
			Pricebook2Id = stdPricebook.Id,
			Product2Id = prod.Id,
			UnitPrice = 360);
		insert pbe;
		
		Special_Event__c event = new Special_Event__c(
		    Product__c = prod.Id,
			StartDate__c = System.today() + 12);
		insert event;
		
		Special_Event_Booking__c booking = new Special_Event_Booking__c(
			Special_Event__c = event.Id,
			Booking_Fee__c = 360);
		insert booking;
		
		booking = [
			SELECT
				Id,
				Special_Event__c,
				Booking_Fee__c,
				Event_Start_Date__c
			FROM
				Special_Event_Booking__c 
			WHERE
				Id = :booking.Id
			LIMIT
				1];
		
		// Set up cancellation cost to charge day 3 bracket
		Double cancelCost = BookingHelper.calculateCancellationCost(booking, prod);
		// Make sure the calculated cost is equal to Charge Fee 3 percentage of Booking Fee
		System.assertEquals((0.5 * 360), cancelCost);
		
		// Set up cancellation cost to charge day 1 bracket
		event.StartDate__c = System.today() + 34;
		update event;
		
		booking = [
			SELECT
				Id,
				Special_Event__c,
				Booking_Fee__c,
				Event_Start_Date__c
			FROM
				Special_Event_Booking__c 
			WHERE
				Id = :booking.Id
			LIMIT
				1];
		
		cancelCost = BookingHelper.calculateCancellationCost(booking, prod);
		// Make sure the calculated cost is equal to Charge Fee 1 percentage of Booking Fee
		System.assertEquals((0.1 * 360), cancelCost);
		
		// Set up cancellation cost to charge day 2 bracket
		event.StartDate__c = System.today() + 17;
		update event;
		
		booking = [
			SELECT
				Id,
				Special_Event__c,
				Booking_Fee__c,
				Event_Start_Date__c
			FROM
				Special_Event_Booking__c 
			WHERE
				Id = :booking.Id
			LIMIT
				1];
		
		cancelCost = BookingHelper.calculateCancellationCost(booking, prod);
		// Make sure the calculated cost is equal to Charge Fee 2 percentage of Booking Fee
		System.assertEquals((0.2 * 360), cancelCost);
		
		// Set up cancellation cost to charge final bracket
		event.StartDate__c = System.today() + 1;
		update event;
		
		booking = [
			SELECT
				Id,
				Special_Event__c,
				Booking_Fee__c,
				Event_Start_Date__c
			FROM
				Special_Event_Booking__c 
			WHERE
				Id = :booking.Id
			LIMIT
				1];
		
		cancelCost = BookingHelper.calculateCancellationCost(booking, prod);
		// Make sure the calculated cost is equal to Charge Fee Final percentage of Booking Fee
		System.assertEquals(360, cancelCost);
		
		cancelCost = BookingHelper.calculateCancellationCost(null,null);
	}
}