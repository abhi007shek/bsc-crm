/**
 * Test Class: TestOpportunityRollup
 *
 * Tests for the OpportunityRollup class
 *
 **/
@isTest
private class TestOpportunityRollup {
	
	/**
 	 * Test the opportunity rollup class create
	 * new account and a number of opportunities
	 * Call the rollup class and verify that all
	 * opportunities have been included in totals
	 **/	
	static testMethod void testOpportunityRollup()
	{
		Account account = new Account(
			name = 'testAcount');
		insert account;
		
		Project__c project = new Project__c();
		project.Account__c = account.Id;
		insert project;
		
		Opportunity opportunity = new Opportunity(
			Name = 'testOpportunity',
			AccountId = account.Id,
			StageName = 'Qualifying',
			CloseDate = Date.today());
			
			opportunity.Project__c = project.Id;
			opportunity.Amount = 10;
		insert opportunity;
		
		Opportunity opportunity2 = new Opportunity(
			Name = 'testOpportunity',
			AccountId = account.Id,
			StageName = 'Won',
			CloseDate = Date.today());
			
			opportunity2.Project__c = project.Id;
		
		opportunity2.Amount = 20;
		insert opportunity2;
		
		Opportunity opportunity3 = new Opportunity(
			Name = 'testOpportunity',
			AccountId = account.Id,
			StageName = 'Booking Received',
			CloseDate = Date.today());
			
			opportunity3.Project__c = project.Id;
		
		opportunity3.Amount = 100;
		insert opportunity3;
		
		System.debug('** inserted opp: ' + opportunity3.Id);
		
		OpportunityRollup.rollUpOpportunityValue(opportunity2);
		
		Project__c updatedProject = [select Opportunities_open_total__c, Opportunities_won_total__c
			from Project__c where Id =: project.Id];
		
		System.assertEquals(Decimal.valueOf(10), updatedProject.Opportunities_open_total__c);
		System.assertEquals(Decimal.valueOf(120), updatedProject.Opportunities_won_total__c);
	}

}