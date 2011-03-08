public class OpportunityRollOver 
{
	//public OpportunityRollOver ()
	//{
	//}
	public void CreateOpportunityRollOver(ID OppId)
	{
		//Opportunity MyOpp=[Select Id from Opportunity where name='InCompOppTest' limit  1];
		//ID Myid =MyOpp.Id ;  
		Savepoint SP=Database.setSavepoint();
		// Clone the Original Opprtunity
		//Opportunity NewOpp=[Select StageName, Renewal_Opportunity__c, OwnerId, Name, Description, Amount From Opportunity where ID='006R0000005iRBNIA2'];		
		Opportunity OrigOpp=[
			SELECT
				StageName,
				Renewal_Opportunity__c,
				OwnerId,
				Name,
				Description,
				Amount
			FROM
				Opportunity
			WHERE
				ID=:OppId];
		Opportunity NewOpp = OrigOpp.clone(false);
		NewOpp.Name = OrigOpp.Name + '-R';
		NewOpp.Rollover_Opportunity__c = true;
		NewOpp.Original_Opportunity__c = OppId;
		OrigOpp.Original_Opportunity_Value__c = OrigOpp.Amount;
		try
		{
			 // Get list of all underlying Opportunity Line Items and Clone Product Line Items		
			List<OpportunityLineItem> OppNewLineItems =new List<OpportunityLineItem>();			
			//Delete from original opp where status is equal to Provisional
			List<Special_Event_Booking__c> OrigOppProvisionalEventBooking = [
				SELECT
					Id
				FROM
					Special_Event_Booking__c
				WHERE
					Id= :OppId
				AND
					Status__c = 'Provisional'];
			//Database.Deleteresult[] oResults=Databas.delete(OrigOppProvisionalEventBooking);									
		 	
		 	for (OpportunityLineItem OppLineItem: [
		 		SELECT
		 			UnitPrice,
		 			T_C_Price__c,
		 			ListPrice,
		 			Quantity,
		 			PricebookEntryId
		 		FROM
		 			OpportunityLineItem
		 		WHERE
		 			OpportunityId= :OppId])
	        {
			    OpportunityLineItem NewLineItem = OppLineItem.clone(false);
			    NewLineItem.OpportunityId = NewOpp.Id;
			    OppNewLineItems.add(NewLineItem);
	        }
	 		insert OppNewLineItems;	 			
	 		// **Clone BSC Event bookings except where status is equal to Provisional
	 		List<Special_Event_Booking__c> OppNewEventBookings = new List<Special_Event_Booking__c>();
		 	for (Special_Event_Booking__c OppEventBooking: [
		 		SELECT
		 			Transferred_To__c,
		 			Transferred_From__c,
		 			Transfer_Cancellation_Date__c,
		 			Status__c,
		 			Special_Event__c,
		 			PK_CB_ELEM_ID__c,
		 			Name,
		 			Fee_Date__c,
		 			FK_CB_COURSE_ID__c,
		 			FK_CB_BOOK_ID__c,
		 			Event_end_Date__c,
		 			Event_Start_Date__c,
		 			Contact__c,
		 			ConnectionSentId,
		 			ConnectionReceivedId,
		 			Company__c, Booking_Fee__c
		 		FROM
		 			Special_Event_Booking__c
		 		WHERE
		 			Status__c='Provisional'
		 		AND
		 			Opportunity_ID__c= : OppId])
	        {
			    Special_Event_Booking__c NewEventBooking=OppEventBooking.clone(false);
			    NewEventBooking.Opportunity__c=NewOpp.Id;
			    OppNewEventBookings.add(NewEventBooking);
	        }
	 		insert OppNewEventBookings;	 		
			//TODO On both opportunities,  Product lines are deleted where there is not a corresponding booking:
			// i.e. where the product is not referred in BSC_Event_Booking.BSC_Event.Product  in the bookings attached to the Opportunity.			
	 		update NewOpp;
	 		update OrigOpp;
		}
		catch (Exception e)
		{
			// roll back everything
			Database.rollback(SP);
			//Apexpages.addMessages(e);
			//return null;
		}					
	}
}