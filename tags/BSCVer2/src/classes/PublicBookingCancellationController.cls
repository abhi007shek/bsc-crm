/*
	Code Coverage - 94%	-	07-10-2010
	Created by Ben Mansfield 16 July 2010
	Modified by Ben Mansfield 4 August 2010
	
	Description:
	
	Changes:
		
		4 August 2010:
		* Event booking modified to link to new opportunity (previously linked to old opportunity)
		* Cloned Line Item with negative amount now has a description set to 'Cancellation'
		
		7 October 2010:
		*AB
		
	
*/
public with sharing class PublicBookingCancellationController
{
	private static final String ERROR_NO_ORIG_PRODUCT = 'Cannot find original Product for this booking.';
	
	private Special_Event_Booking__c record;
	private Id priceBookId;
	
	public PublicBookingCancellationController(ApexPages.StandardController controller)
	{
		record = getBooking(controller.getId());
		priceBookId = [
			SELECT
				priceBook2Id
			FROM
				Opportunity
			WHERE
				Id=:record.Opportunity__c].priceBook2Id;
	}
	
	private Special_Event_Booking__c getBooking(Id id)
	{
		List<Special_Event_Booking__c> bookingQuery = [
			SELECT
				Id,
				Status__c,
				Special_Event__r.Product__c,
				Special_Event__r.Product__r.Name,
				Event_Start_Date__c,
				Booking_Fee__c,
				// Opportunity fields
				Opportunity__c,
				Opportunity__r.AccountId,
				Opportunity__r.OwnerId,
				Opportunity__r.Name
			from
				Special_Event_Booking__c
			WHERE
				Id = :id];
		
		if (bookingQuery.size() == 1)
			return bookingQuery.get(0);
		
		return null;
	}
	
	public PageReference doAction()
	{
		if (record != null)
		{
			List<RecordType> recordTypes = [
				SELECT
					Id
				FROM
					RecordType
				WHERE
					SObjectType = 'Opportunity'
				AND
					Name = 'Public Event'];
			
			Opportunity newOpp = new Opportunity(
				AccountId = record.Opportunity__r.AccountId,
				OwnerId = record.Opportunity__r.OwnerId,
				// rjd - 3 August 2010 - using pricebook from opportunity
				Pricebook2Id = PricebookId,
				Name = record.Opportunity__r.Name + ' - Cancellation Fee',
				RecordTypeId = (recordTypes.isEmpty() ? null : recordTypes.get(0).Id),
				Type = 'Public Course',
				CloseDate = System.today(),
				StageName = 'Quote/Negotiation',
				Rollover_Opportunity__c = true,
				Original_Opportunity__c = record.Opportunity__c);
			insert newOpp;
			
			Map<String, PricebookEntry> entries = BookingHelper.getPricebookEntries(newOpp.Pricebook2Id,
				new String[] { 'Cancellation Fees (Public)', 'Reconciliation (Public)', record.Special_Event__r.Product__r.Name });
			
			List<OpportunityLineItem> olisToInsert = new List<OpportunityLineItem>();
			
			OpportunityLineItem oli = null;
			// Calculate cancellation fee
			if (entries.containsKey('Cancellation Fees (Public)'))
			{
				oli = new OpportunityLineItem(
					PricebookEntryId = entries.get('Cancellation Fees (Public)').Id,
					OpportunityId = newOpp.Id,
					Quantity = 1,
					UnitPrice = 0,
					T_C_Price__c = 0);
				
				if (record.Status__c != 'Cancelled' && record.Status__c != 'To be cancelled')
				{
					// Get currently booked product
					List<Product2> products = [
						SELECT
							Id,
							Cancellation_Charge_Day_1__c,
							Cancellation_Charge_Day_2__c, 
							Cancellation_Charge_Day_3__c,
							Cancellation_Charge_Fee_1__c,
							Cancellation_Charge_Fee_2__c,
							Cancellation_Charge_Fee_3__c, 
							Cancellation_Charge_Fee_Final__c
						FROM
							Product2 
						WHERE
							Id = :record.Special_Event__r.Product__c];
					if (products.size() != 1)
					{
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_NO_ORIG_PRODUCT));
						return null;
					}
					
					oli.UnitPrice = oli.T_C_Price__c = record.Booking_Fee__c = BookingHelper.calculateCancellationCost(record, products[0]);
				}
				olisToInsert.add(oli);
				
				// Status set to cancelled
				record.Status__c = 'Cancelled';
				record.Transfer_Cancellation_Date__c = System.today();
				update record;
				
				// Clone original opportunity line item and calculate quantity of 1
				List<OpportunityLineItem> originalLineItems = [
					SELECT
						c2g__CODAUnitOfWork__c,
						UnitPrice,
						TotalPrice,
						T_C_Price__c,
						T_C_Price_Variation__c, 
						SystemModstamp,
						Subscription_Start_Date__c, 
						Subscription_Product__c,
						SortOrder,
						ServiceDate,
						Sales_Manager_Price__c,
						SM_Price_Needed__c,
						Quantity, 
						Pricing_Exception__c,
						PricebookEntryId,
						OpportunityId, 
						ListPrice,
						LastModifiedDate,
						LastModifiedById,
						IsDeleted, 
						Id,
						IC_Price_Difference__c,
						HasSchedule,
						HasRevenueSchedule, 
						HasQuantitySchedule,
						Duration_Years__c,
						Discounted__c, 
						Description,
						CurrencyIsoCode,
						CreatedDate,
						CreatedById, 
						ConnectionSentId,
						ConnectionReceivedId 
					FROM
						OpportunityLineItem
					WHERE 
						OpportunityId = :record.Opportunity__c
					AND
						PricebookEntry.Product2Id = :record.Special_Event__r.Product__c];
												
				if (originalLineItems.size() > 0)
				{
					OpportunityLineItem clonedOli = originalLineItems.get(0).clone(false, true);
					// Set clone to quantity of 1 since we only remove 1 booking
					clonedOli.Quantity = 1;
					clonedOli.TotalPrice = null;
					clonedOli.UnitPrice = -clonedOli.UnitPrice;
					// brm - 4 August 2010 - Added tag as cancellation in description
					clonedOli.Description = 'Cancellation';
					clonedOli.Pricing_Exception__c = true;
					
					olisToInsert.add(clonedOli);
					
					if (entries.containsKey('Reconciliation (Public)'))
					{
						OpportunityLineItem reconOrigOli = new OpportunityLineItem(
							PricebookEntryId = entries.get('Reconciliation (Public)').Id,
							OpportunityId = originalLineItems.get(0).OpportunityId,
							Quantity = 1,
							UnitPrice = originalLineItems.get(0).UnitPrice);						
						olisToInsert.add(reconOrigOli);
						
						OpportunityLineItem reconNewOli = new OpportunityLineItem(
							PricebookEntryId = entries.get('Reconciliation (Public)').Id,
							OpportunityId = newOpp.Id,
							Quantity = 1,
							UnitPrice = -originalLineItems.get(0).UnitPrice,
							Pricing_Exception__c = true);
						
						olisToInsert.add(reconNewOli);
					}
				}
			}
			insert olisToInsert;
			
			// brm - 4 August 2010 - Change event booking to link to new opportunity
			record.Opportunity__c = newOpp.Id;
			update record;
		}
		
		return new PageReference('/' + record.Id);
	}
	
	@IsTest
	private static void test()
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
			UnitPrice = 360,
			IsActive = true);
		insert pbe;
		
		Opportunity opp = new Opportunity(
			Name = 'Public Event Test',
			StageName = 'Qualifying',
			CloseDate = System.today());
		insert opp;
		
		OpportunityLineItem oli = new OpportunityLineItem(
			OpportunityId = opp.Id,
			PricebookEntryId = pbe.Id,
			UnitPrice = 360,
			Quantity = 1);
		insert oli;
		
		Special_Event__c event = new Special_Event__c(
			StartDate__c = System.today() + 5,
			Product__c = prod.Id,
			Opportunity__c = opp.Id);
		insert event;
		
		Special_Event_Booking__c booking = new Special_Event_Booking__c(
			Booking_Fee__c = 200,
			Special_Event__c = event.Id,
			Opportunity__c = opp.Id);
		insert booking;
		
		ApexPages.StandardController stdController = new ApexPages.StandardController(booking);
		PublicBookingCancellationController controller = new PublicBookingCancellationController(stdController);
		controller.doAction();
	}
}