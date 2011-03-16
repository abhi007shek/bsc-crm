/*
	Created by Ben Mansfield 12 July 2010
	Modified by Ben Mansfield 4 August 2010
	
	Description:
	
	Changes:
		
		4 August 2010
		* Opportunity stages added to list of permitted Opportunity states 
			(previously only when opportunity is closed and won)
		
*/
public with sharing class CourseFinderWizardController {
	
	public Opportunity record { get; private set; }
	
	public Boolean enableBookings { get; private set; }
	
	public CourseFinderWizardController(ApexPages.StandardController controller)
	{
		enableBookings = false;
		
		record = getOpportunity(controller.getId());
		if (record != null && isInPermittedStage(record) && hasPublicCourses(record))
		{
			enableBookings = true;
		}
	}
	
	private Opportunity getOpportunity(Id id)
	{
		// brm - 19 July 2010 - added unit price to query so it can be used to work out booking fees
		List<Opportunity> oppQuery = [Select Id, Name, IsWon, IsClosed, StageName, AccountId, 
											(Select Id, PricebookEntry.Product2.Name, 
											PricebookEntry.Product2.Allows_Provisional_Bookings__c, Quantity, 
											UnitPrice From OpportunityLineItems) 
										From Opportunity Where Id = :id];
										
		if (oppQuery.size() == 1) return oppQuery.get(0);
		
		return null;
	}
	
	private Boolean hasPublicCourses(Opportunity target)
	{
		if (target != null)
		{
			for (OpportunityLineItem oli : target.OpportunityLineItems)
			{
				if (oli.PricebookEntry.Product2.Allows_Provisional_Bookings__c) return true;
			}
		}
		
		return false;
	}
	
	private Boolean isInPermittedStage(Opportunity target)
	{
		// brm - 4 August 2010 - old way of permitting opportunities
		//return target.IsWon && target.IsClosed;
		
		// brm - 4 August 2010 - new way of permitting opportunities - based on opportunity stages
		return target.StageName == 'Quote/Proposal' || target.StageName == 'Negotiation' || 
				target.StageName == 'Booking Received' || target.StageName == 'Won';
	}
	
	public PageReference backToOpp()
	{
		return new PageReference('/' + record.Id);
	}
	
	@IsTest
	private static void test()
	{
		Opportunity opp = new Opportunity();
		opp.Name = 'Test Opp';
		opp.StageName = 'Closed Won';
		opp.CloseDate = System.today();
		insert opp;
		
		Product2 prod = new Product2();
		prod.Name = 'Test Event Product';
		prod.Allows_Provisional_Bookings__c = true;
		prod.Transfer_Charge_Day_1__c = 10;
		prod.Transfer_Charge_Day_2__c = 5;
		prod.Transfer_Charge_Day_3__c = 2;
		
		prod.Transfer_Charge_Fee_1__c = 120;
		prod.Transfer_Charge_Fee_2__c = 60;
		prod.Transfer_Charge_Fee_3__c = 40;
		prod.Transfer_Charge_Fee_Final__c = 10;
		insert prod;
		
		Special_Event__c event = new Special_Event__c();
		event.Product__c = prod.Id;
		event.City__c = 'London';
		event.StartDate__c = System.today().addDays(3);
		insert event;
		
		ApexPages.Standardcontroller stdContr = new ApexPages.Standardcontroller(opp);
		CourseFinderWizardController controller = new CourseFinderWizardController(stdContr);
	}
}