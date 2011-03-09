/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestBscEvent {

	private static Account account;
	private static Opportunity opportunity;
	
	static void InsertAccount()
	{
		account = new Account(
			name = 'testAcount');
		insert account;
		
		System.debug('** inserted account: ' + account.Id);
	}
	
	static void InsertOpportunity()
	{
		opportunity = new Opportunity(
			Name = 'testOpportunity',
			AccountId = account.Id,
			StageName = 'Qualifying',
			CloseDate = Date.today());
		insert opportunity;
		
		System.debug('** inserted opp: ' + opportunity.Id);
	}

    static testMethod void testNewProduct() {
        InsertAccount();
        InsertOpportunity();
        
		// Create a product for the Event.
		Product2 product = new Product2(
			name = 'GHI');
		insert product;        
        
        Special_Event_Booking__c[] bookings = new Special_Event_Booking__c[3];
		
		for (Integer i = 0; i < 3; i++)
		{
			Special_Event__c specialEvent = new Special_Event__c(
				Opportunity__c = opportunity.Id,
				Name = 'Test Event',
				product__c = product.id,
				Type__c = 'In-Company Training',
				Status__c = 'Anything but Confirmed',
				Stage__c = 'Anything but Provisional',
				StartDate__c = Date.today(),
				EndDate__c = Date.today().addDays(5));

			insert specialEvent;

			c2g__codaDimension4__c dim4 = new c2g__codaDimension4__c();
			try
			{
			   dim4 = [Select d.id, d.name From c2g__codaDimension4__c d Where d.name = :specialEvent.Name][0];
			}
			catch(Exception e)
			{
				system.debug('Cannnot locate the dimension record');
			}
			System.assertEquals(specialEvent.Dimension_4__r.Name, dim4.id);
		}
    }
    
    static testMethod void testExistingProduct() {
        InsertAccount();
        InsertOpportunity();
 		RecordType recType = [Select r.Id From RecordType r where r.sObjectType = 'Special_Event__c' and r.name = 'In-Company Event' and isactive=true][0];
		// Test with an existing product
		// Creating a Special Event Booking
		// Update the status of the event to Confirmed to see if the 
		// Special Event Booking are updated accordingly
		Product2 productExist = [Select p.ProductCode, p.Name, p.Length__c, p.Id 
		                    From Product2 p
                            where length__c = 1
                            limit 1 ][0];
		
        CurrencyType curr = [Select id, isocode From CurrencyType][0];
		Special_Event__c specialEvent = new Special_Event__c(
			Opportunity__c = opportunity.Id,
			Name = 'Test Event',
			product__c = productExist.id,
			//Type__c = 'In-Company Training',
			RecordTypeId = recType.Id,
			Status__c = 'Allocating',
			Stage__c = 'Provisional',
			StartDate__c = Date.today(),
			EndDate__c = Date.today().addDays(5),
			CurrencyIsoCode = curr.isocode);
	
		insert specialEvent;

		c2g__codaDimension4__c dim4 = new c2g__codaDimension4__c();
		try
		{
			 dim4 = [Select d.id, d.name From c2g__codaDimension4__c d Where d.name = :specialEvent.Name][0];
		}
		catch(Exception e)
		{
			system.debug('Cannnot locate the dimension record');
		}
		System.assertEquals(specialEvent.Dimension_4__r.Name, dim4.id);
		Account acc = [Select id From Account Where active__c = true][0];
		
		Special_Event_Booking__c specialEventBooking = new Special_Event_Booking__c(
		company__c=acc.Id, opportunity__c=opportunity.Id, status__c='Provisional',
		currencyisocode=curr.isocode,special_event__c=specialEvent.Id);
		test.startTest();
		insert specialEventBooking;
		test.stopTest();
		
		// Now update the Event status to confirmed to fire the after update trigger
		// Test when Status changes to Confirmed
		specialEvent.Status__c = 'Confirmed';
		specialEvent.Stage__c = 'Confirmed';
		update specialEvent;
		
		// The after update trigger should have fired
		List<Special_Event_Booking__c> seb = [Select id, status__c
		from Special_Event_Booking__c where id = :specialEventBooking.id];
		for (Special_Event_Booking__c se:seb)
		{
			System.assertEquals('Confirmed', se.status__c);
		}
				
		// Test when Status changes to Allocating
		specialEvent.Status__c = 'Allocating';
		specialEvent.Stage__c = 'Provisional';
		update specialEvent;
		// The after update trigger should have fired
		List<Special_Event_Booking__c> seb1 = [Select id, status__c
		from Special_Event_Booking__c where id = :specialEventBooking.id];
		for (Special_Event_Booking__c s: seb1)
		{
			System.assertEquals('Provisional', s.status__c);	
		}
		
    }
    
    static testMethod void testAuditOutcome() {
        InsertAccount();
        InsertOpportunity();
 		RecordType recType = [Select r.Id From RecordType r where r.sObjectType = 'Special_Event__c' and r.name = 'Audit' and isactive=true][0];
		// Test with an existing product
		// Creating a Special Event Booking
		// Update the status of the event to Confirmed to see if the 
		// Special Event Booking are updated accordingly
		Product2 productExist = [Select p.ProductCode, p.Name, p.Length__c, p.Id 
		                    From Product2 p
                            where length__c = 1
                            limit 1 ][0];
		
        CurrencyType curr = [Select id, isocode From CurrencyType][0];
		Special_Event__c specialEvent = new Special_Event__c(
			Opportunity__c = opportunity.Id,
			Name = 'Test Event 1',
			product__c = productExist.id,
			Type__c = 'Audit',
			RecordTypeId = recType.Id,
			Status__c = 'Allocating',
			Stage__c = 'Provisional',
			StartDate__c = Date.today(),
			EndDate__c = Date.today().addDays(5),
			CurrencyIsoCode = curr.isocode);
	
		insert specialEvent;

		c2g__codaDimension4__c dim4 = new c2g__codaDimension4__c();
		try
		{
			 dim4 = [Select d.id, d.name From c2g__codaDimension4__c d Where d.name = :specialEvent.Name][0];
		}
		catch(Exception e)
		{
			system.debug('Cannnot locate the dimension record');
		}
		// Test to see if the trigger has fired properly
		System.assertEquals(specialEvent.Dimension_4__r.Name, dim4.id);
		Account acc = [Select id From Account Where active__c = true][0];
		
		Special_Event_Booking__c specialEventBooking = new Special_Event_Booking__c(
		company__c=acc.Id, opportunity__c=opportunity.Id, status__c='Provisional',
		currencyisocode=curr.isocode,special_event__c=specialEvent.Id);
		test.startTest();
		insert specialEventBooking;
		test.stopTest();
		
		// Now update the Event status to confirmed to fire the after update trigger
		// Test when Status changes to Confirmed
		specialEvent.Status__c = 'Confirmed';
		specialEvent.Stage__c = 'Confirmed';
		update specialEvent;
		
		// The after update trigger should have fired
		List<Special_Event_Booking__c> seb = [Select id, status__c
		from Special_Event_Booking__c where id = :specialEventBooking.id];
		for (Special_Event_Booking__c se:seb)
		{
			// Checking whether the trigger has fired properly
			System.assertEquals('Confirmed', se.status__c);
		}
				
		// Test when Status changes to Allocating
		specialEvent.Status__c = 'Allocating';
		specialEvent.Stage__c = 'Provisional';
		update specialEvent;
		// The after update trigger should have fired
		List<Special_Event_Booking__c> seb1 = [Select id, status__c
		from Special_Event_Booking__c where id = :specialEventBooking.id];
		for (Special_Event_Booking__c s: seb1)
		{
			// Checking whether the trigger has fired properly
			System.assertEquals('Provisional', s.status__c);	
		}
		
    }    
}