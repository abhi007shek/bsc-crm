@isTest
private class testSplitOpportunity 
{

    static testMethod void testSplitOpportunityMethod()
	{
		Pagereference pref=Page.SplitOpportunity ;
		Test.setCurrentPage(pref);
		
		// Create a New Account
		Account NewAccount=new Account();
		NewAccount.Name='TestSplitOpportunity';
		insert NewAccount;
		
		//Create a new Opportunity
		Opportunity NewOpp= new Opportunity(); 
		NewOpp.Name='TestSplitOpportunity';
		NewOpp.StageName='Qualifying';
		NewOpp.CloseDate=System.today();
		NewOpp.AccountId=NewAccount.Id;
		insert NewOpp;
		 
		//Create Product Line items 
		OpportunityLineItem NewOpportunityLineItem=new OpportunityLineItem();
		NewOpportunityLineItem.OpportunityId=NewOpp.id;
		NewOpportunityLineItem.Quantity=100;
		PricebookEntry PricebookEntryId=[Select Id,Product2Id From PricebookEntry limit 1];
		NewOpportunityLineItem.PricebookEntryId=PricebookEntryId.Id;
		Id ProductId=PricebookEntryId.Product2Id; 
		NewOpportunityLineItem.TotalPrice=100;
		insert NewOpportunityLineItem;			

		//Create Event for that Product
		Special_Event__c NewBSCEvent=new Special_Event__c();
		NewBSCEvent.Name='TestSplitOpportunity';
		NewBSCEvent.Opportunity__c=NewOpp.Id;
		NewBSCEvent.Status__c='Provisional';
		NewBSCEvent.Product__c=ProductId;
		Insert NewBSCEvent;
		
		//Create Event booking for that Event
		 Special_Event_Booking__c NewBSCEventBooking=new Special_Event_Booking__c();
		 NewBSCEventBooking.Special_Event__c=NewBSCEvent.Id;
		 NewBSCEventBooking.Status__c='Provisional';
		 NewBSCEventBooking.Opportunity__c=NewOpp.Id;
		 NewBSCEventBooking.Booking_Fee__c=100;
		 Insert NewBSCEventBooking;

		 Special_Event_Booking__c NewBSCEventBooking2=new Special_Event_Booking__c();
		 NewBSCEventBooking2.Special_Event__c=NewBSCEvent.Id;
		 NewBSCEventBooking2.Status__c='Confirmed';
		 NewBSCEventBooking2.Opportunity__c=NewOpp.Id;
		 NewBSCEventBooking2.Booking_Fee__c=100;
		 Insert NewBSCEventBooking2;		 
		  
		// get a Product id
		

		 // Construct the standard controller
		 Apexpages.Standardcontroller con= new Apexpages.Standardcontroller(NewOpp);
		 
		 //Create Custom controller
		 OpportunitySplitController ext=new OpportunitySplitController(con);
		 
		 // Switch to test context
    	 Test.startTest();
    	 
    	 Pagereference ref=ext.doAction();
    	 //PageReference redir = new PageReference('/' + ext. );
    	 
    	 Test.stopTest();
    }
}