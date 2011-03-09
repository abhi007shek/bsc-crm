/**
 * Class: OpportunityRollup
 *
 * Class to roll up the total values of opportunities
 * related to the current project. 
 * NOTE: This is limited to projects with < 1000 opportunities dues
 * to governor limits.
 *
 **/
public with sharing class OpportunityRollup {
	
	/**
 	 * Method: rollUpOpportunityValue
	 *
 	 * Class to roll up the total values of opportunities
 	 * related to the opportunities current project. 
 	 * Updates the project with these total.
 	 *
	 **/
	public static void rollUpOpportunityValue(Opportunity thisOpp){
		
		//If we do not have a project for this opportunity then 
		//no point calculating
		if(thisOpp.Project__c == null){
			return;			
		}
		
		System.debug('** rollUpOpportunityValue, this opp id: ' + thisOpp.Id + 
			' project: ' + thisOpp.Project__c);
		
		Decimal open = Decimal.valueOf(0);
		Decimal won = Decimal.valueOf(0);
		
		//Check how many opportunities are linked to this project
		Integer oppsCount = [select count() from Opportunity 
			where Project__c != null 
			and Project__c = :thisOpp.Project__c 
			limit 1000];
		
		//If its more than 1000 we cannot procede without hitting limits	
		if(oppsCount < 1000){
						
			//Calculate total of closed - won opportunities			
			AggregateResult[] wonResults = 
				[select SUM(Amount) wonSum from Opportunity 
				where Project__c = :thisOpp.Project__c
				and IsWon = true];
			
			System.debug('** won results: ' + wonResults.size());
			
			if(wonResults != null && wonResults.size() > 0){
				won = (Decimal)wonResults.get(0).get('wonSum');
			}
			
			System.debug('** won total: ' + won);
			
			//Calculate total of open opportunities
			AggregateResult[] openResults = 
				[select SUM(Amount) closedSum from Opportunity 
				where Project__c = :thisOpp.Project__c
				and IsClosed = false];
			
			if(openResults != null && openResults.size() > 0){
				open = (Decimal)openResults.get(0).get('closedSum');
			}
			
			System.debug('** open total: ' + open);
			
			//Update the project record
			Project__c project = [select Id from Project__c where Id = :thisOpp.Project__c];
			project.Opportunities_open_total__c = open; 
			project.Opportunities_won_total__c = won;
				 
			update project;
		}
	}
}