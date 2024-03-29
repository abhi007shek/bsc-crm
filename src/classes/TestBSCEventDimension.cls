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
private class TestBSCEventDimension {

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
		
		// Test with an existing product
		Product2 productExist = [Select p.ProductCode, p.Name, p.Length__c, p.Id 
		                    From Product2 p
                            where length__c = 1
                            limit 1 ][0];
		
		for (Integer i = 0; i < 3; i++)
		{
			Special_Event__c specialEvent = new Special_Event__c(
				Opportunity__c = opportunity.Id,
				Name = 'Test Event',
				product__c = productExist.id,
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
}