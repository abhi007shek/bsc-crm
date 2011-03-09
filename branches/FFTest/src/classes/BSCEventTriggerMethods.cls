public with sharing class BSCEventTriggerMethods
// This class contains methods relating to Special_Event__c(BSCEvents) object
// triggers
{
	Public static void updateBookingStatus(List<Special_Event__c> bEvent)
	// Method to update the BSCEventBooking status to Confirmed
	// when the status of the event is set to confirmed.
	// for In-Company and Audit Events only 
	// Case 00001323
	{
		List<RecordType> recType = [Select r.Id From RecordType r where r.sObjectType = 'Special_Event__c' and r.name in ('Audit','In-Company Event') and isactive=true];
	    if (recType.size() < 2)
    	{
    		bEvent[0].addError('Missing Record Types Audit or In-Company Event '+ recType.size());
    	}
    	else
    	{

	    	for (Special_Event__c bscEvent: bEvent)
        	{
    	
	    		if ((bscEvent.RecordTypeId==recType[0].Id||bscEvent.RecordTypeId==recType[1].Id)&&(bscEvent.stage__c=='Confirmed'||bscEvent.stage__c=='Provisional'))
	    		{
	   	  			List<Special_Event_Booking__c> bscEventBooking = new List<Special_Event_Booking__c>([
	   	  			Select se.Id, se.Status__c
	   	  			From   Special_Event_Booking__c se
	   	  			Where  se.Special_event__c = :bscEvent.Id
	   	  			And    se.Status__c in ('Confirmed','Provisional')
	   	  			]);
	   	  			for (Special_Event_Booking__c a: bscEventBooking)
	   	  			{
	   	  				a.status__c = bscEvent.stage__c;
	   	  			}
	   	  			update bscEventBooking;
	    		}
	    		// Create Audit outcome when bsc events of type audit are created
				// Case 00001473	
				if (!ProcessorControl.inFutureContext)
				{
					createAuditOutcome(bscEvent);					
				}
	    		
    		}
    	}
	}


    //@future
	Public static void createAuditOutcome(Special_Event__c bEvent)
	// Method to create Audit outcome when bsc events of type audit are created
	// Case 00001473	
	{
		
		Audit_Outcome__c auditRec;

		if (bEvent.Type__c=='Audit'&&bEvent.stage__c=='Confirmed')
		{
			system.debug('bEvent.name: '+ bEvent.name );
			Opportunity opp = new Opportunity();
			try
			{
				opp = [Select o.accountid from Opportunity o Where o.Id = :bEvent.opportunity__c];
			}
			catch(Exception e)
			{
				bEvent.addError('Cannot find the Opportunity associated with the record.');
			}
			list<Special_Event_Trainer__c> eventTrainer = new list<Special_Event_Trainer__c>([Select s.Id, s.Trainer__r.User__c From Special_Event_Trainer__c s Where s.Bsc_Event__c = :bEvent.Id]);
			Audit_Outcome__c auditor = new Audit_Outcome__c();
           	if (eventTrainer.size()>1||eventTrainer.size()==0)
			{
           		auditor.Auditor__c = null;
           	}
           	else
           	{
           		auditor.Auditor__c = eventTrainer[0].trainer__r.User__c;
           	}
			auditRec = new Audit_Outcome__c(account__c=opp.AccountId, status__c='Not Started',bsc_event__c=bEvent.Id,currencyIsoCode=bEvent.CurrencyIsoCode,Auditor__c=auditor.Auditor__c);
			ProcessorControl.inFutureContext = true;
			insert auditRec;
		}
			
	}
	
	Public static void createDimension4(List<Special_Event__c> bEvent)
	{
		for (Special_Event__c se : bEvent)
		{
   			Special_Event__c b = new Special_Event__c();
   			b=se.clone();
   			product2 prod = [Select productcode  From product2 where id = :b.product__c][0];
   			b.name = prod.productcode + '/'+ b.Event_Auto_Number__c;
   			c2g__codaDimension4__c dim = new c2g__codaDimension4__c();
   			dim.c2g__ReportingCode__c=b.name;
   			dim.Name=b.name;
   			dim.CurrencyIsoCode=se.currencyIsoCode;
   			try
   			{
     			insert dim;
     			b.Dimension_4__c = dim.id;
     			try
     			{
        			update b;
     			}
     			catch(Exception e)
     			{
     				se.adderror(e);
     			}
   			}
   			catch(Exception f)
   			{
   				se.adderror(f);
   			}
		}
	}
}