/*
	2010-09-16 - Andy Bolton 
	Unit test of functionality of triggers.
	
	AB_OpportunityTriggerAccountReassignment -	100%
	AB_TaskTriggerAccountReassignment -			100%
	AB_EventTriggerAccountReassignment -		100%
	testAB_SpecialEventBookingTrigger -			100%
	testCreateEventsForEventTrainer -			100%
*/


@isTest
private class AB_TestAccountReassignmentTriggers
{
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
	
	static testMethod void testAB_EventTriggerAccountReassignment()
	{
		InsertAccount();
		Event event = new Event(
			WhatId = account.id,
			DurationInMinutes = 20,
			ActivityDateTime = DateTime.now());
		insert event;
	}
	
	static testMethod void testAB_TaskTriggerAccountReassignment()
	{
		InsertAccount();
		Task task = new Task(
			WhatId = account.id);
		insert task;
	}
	
	static testMethod void testAB_OpportunityTriggerAccountReassignment()
	{
		System.debug('** start test account reassignment **');
		
		InsertAccount();
		
		System.debug('** test inserted account: ' + account.Id);
		
		InsertOpportunity();
		
		System.debug('** test inserted opp: ' + opportunity.Id + ' opp acc: ' + opportunity.AccountId);
		
		System.debug('** finish test account reassignment **');
	}
	
	static testMethod void testAB_SpecialEventBookingTrigger()
	{
		InsertAccount();
		InsertOpportunity();
		
		Product2 product = new Product2(
			name = 'Test Product 1');
		insert product;
		
		Special_Event__c specialEvent = new Special_Event__c(
			Opportunity__c = opportunity.Id,
			Product__c = product.Id,
			Name = 'Test Event',
			Type__c = 'In-Company Training',
			Status__c = 'Anything but Confirmed',
			Stage__c = 'Anything but Provisional',
			StartDate__c = Date.today(),
			EndDate__c = Date.today().addDays(5));
		insert specialEvent;
		specialEvent = [SELECT Status__c, Stage__c, Venue__c FROM Special_Event__c WHERE Id = :specialEvent.Id].get(0);
		
//		System.assertEquals(specialEvent.Status__c, 'Confirmed');
//		System.assertEquals(specialEvent.Stage__c, 'Provisional');
//		System.assertNotEquals(specialEvent.Venue__c, null);
	}
	
	static testMethod void testCreateEventsForEventTrainer()
	{
		Integer i;
		InsertAccount();
		InsertOpportunity();
		
		// Create a product for the Event.
		Product2 product = new Product2(
			name = 'Test Product 1');
		insert product;
		
		// Create the Event
		Special_Event__c specialEvent = new Special_Event__c(
			Opportunity__c = opportunity.Id,
			Product__c = product.Id,
			Name = 'Test Event',
			Type__c = 'In-Company Training',
			Status__c = 'Anything but Confirmed',
			Stage__c = 'Anything but Provisional',
			StartDate__c = Date.today(),
			EndDate__c = Date.today().addDays(5));
		insert specialEvent;
		
		// Create the trainer
		Trainer__c trainer = new Trainer__c(
			User__c = Userinfo.getUserId());
		insert trainer;
		
		Special_Event_Trainer__c[] eventTrainers = new Special_Event_Trainer__c[2];
		Special_Event_Unit__c[] eventUnits = new Special_Event_Unit__c[2];
		
		for (i = 0 ; i < 2; i++)
		{
			eventUnits[i] = new Special_Event_Unit__c(
				Special_Event__c = specialEvent.Id,
				Unit_Start_Time__c = DateTime.now(),
				Duration__c = 5.0/*,
				BSC_Event_Trainer__c = eventTrainers[i].Id*/
			);
		}
		insert eventUnits;
		
		for (i = 0 ; i < 2; i++)
		{
			eventTrainers[i] = new Special_Event_Trainer__c(
				BSC_Event__c = specialEvent.Id,
				Trainer__c = trainer.Id,
				Status__c = 'Status 01',
				BSC_Event_Unit__c = eventUnits[i].Id
			);
		}	
		insert eventTrainers;
		eventUnits[0].BSC_Event_Trainer__c = eventTrainers[0].Id;
		eventUnits[1].BSC_Event_Trainer__c = eventTrainers[1].Id;
		update eventUnits;
		
		
		
		update eventTrainers[0];
		// Check the event linked to the event trainer
		List<Event> linkedEvents = [
			SELECT
				Id,
				Event_Trainer_Status__c
			FROM
				Event
			WHERE
				BSC_Event_Trainer__c = :eventTrainers[0].Id];
		System.assertEquals(1, linkedEvents.size());
		System.assertEquals(eventTrainers[0].Status__c, linkedEvents[0].Event_Trainer_Status__c);
		
		update eventTrainers[1];
		linkedEvents = [
			SELECT
				Id,
				Event_Trainer_Status__c
			FROM
				Event
			WHERE
				BSC_Event_Trainer__c = :eventTrainers[1].Id];
		System.assertEquals(1, linkedEvents.size());
		System.assertEquals(eventTrainers[1].Status__c, linkedEvents[0].Event_Trainer_Status__c);
		
		// Modify event trainer record
		eventTrainers[0].Status__c = 'Status 02';
		update eventTrainers[0];
		
		// Check the event linked to the event trainer
		linkedEvents = [
			SELECT
				Id,
				Event_Trainer_Status__c
			FROM
				Event
			WHERE
				BSC_Event_Trainer__c = :eventTrainers[0].Id];
		System.assertEquals(1, linkedEvents.size());
		System.assertEquals(eventTrainers[0].Status__c, linkedEvents[0].Event_Trainer_Status__c);
		
		// Delete event trainer record
		delete eventTrainers[0];
		// Check the event linked to the event trainer is deleted
		linkedEvents = [
			SELECT
				Id,
				Event_Trainer_Status__c
			FROM
				Event
			WHERE
				BSC_Event_Trainer__c = :eventTrainers[0].Id];
		System.assertEquals(0, linkedEvents.size());

	}
	
	static testMethod void testActionPlanTaskTrigger()
	{
		Task task = new Task();
		insert task;
		update task;
	}
	
	static testMethod void testTriggerTerritoryAssignment()
	{
		InsertAccount();
		account.Exclude_From_Assignment__c = false;		
		
		Territory__c territory = new Territory__c();
		insert territory;
		
		Area__c area = new Area__c(
			Territory__c = territory.Id,
			Country__c = 'Ireland');
		insert area;
		
		account.Area__c = area.Id;
		update account;		
		
		territory.Territory_Manager__c = UserInfo.getUserId();
		update territory;
	}
	
	static testmethod void testTriggerAreaAssignment()
	{
		InsertAccount();
		account.Exclude_From_Assignment__c = false;		
		
		Territory__c territory = new Territory__c();
		insert territory;
		
		Area__c area = new Area__c(
			Country__c = 'Ireland');
		insert area;
		
		area.Territory__c = territory.Id;
		
		
		account.Area__c = area.Id;
		update account;
		
		update area;			
	}
	
	static testmethod void testAB_TestAccountReassignmentTrigger()
	{
		InsertAccount();
		InsertOpportunity();
		
		Special_Event_Booking__c[] bookings = new Special_Event_Booking__c[3];
	    Product2 productExist = [Select p.ProductCode, p.Name, p.Length__c, p.Id 
		                         From Product2 p
                                 Where length__c = 1
                                 limit 1 ][0];
                                 
		for (Integer i = 0; i < 3; i++)
		{
			Special_Event__c specialEvent = new Special_Event__c(
				Opportunity__c = opportunity.Id,
				Name = 'Test Event',
				Product__c = productExist.Id,
				Type__c = 'In-Company Training',
				Status__c = 'Anything but Confirmed',
				Stage__c = 'Anything but Provisional',
				StartDate__c = Date.today(),
				EndDate__c = Date.today().addDays(5));
			insert specialEvent;
		
			bookings[i] = new Special_Event_Booking__c(
				Opportunity__c = opportunity.Id,
				Booking_Fee__c = (i == 0 ? 10000 : 0),
				Special_Event__c = specialEvent.Id);
		}
		insert bookings;
		delete bookings[0];
		
		Double dFee = bookings[0].Booking_Fee__c;
		
		// Retrieve Event Booking object and ensure booking price has been reassigned.		
		List<Special_Event_Booking__c> updatedEvents = new List<Special_Event_Booking__c>([
			SELECT
				Booking_Fee__c
			FROM
				Special_Event_Booking__c
			WHERE
			   (Id = :bookings[1].Id
			OR
				Id = :bookings[2].Id)
			AND
				Booking_Fee__c > 0]);
		System.assertEquals(updatedEvents.size(), 1);
		System.assertEquals(updatedEvents[0].Booking_Fee__c , dFee);
	}
}