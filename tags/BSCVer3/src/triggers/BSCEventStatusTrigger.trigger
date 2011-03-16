trigger BSCEventStatusTrigger on Special_Event__c (after update) {
// Trigger to update the BSCEventBooking status to Confirmed
// when the status of the event is set to confirmed.
// for In-Company Events only 
// Case 00001323
	BSCEventTriggerMethods.updateBookingStatus(trigger.new);
   /* List<RecordType> recType = [Select r.Id From RecordType r where r.name in ('Audit','In-Company Event')];
    if (recType.size() < 4)
    {
    	Trigger.new[0].addError('Missing Record Types Audit or In-Company Event '+ recType.size());
    }
    else
    {
	    for (Special_Event__c bscEvent: trigger.new)
        {    	
	    	if ((bscEvent.RecordTypeId==recType[0].Id||bscEvent.RecordTypeId==recType[1].Id||bscEvent.RecordTypeId==recType[2].Id||bscEvent.RecordTypeId==recType[3].Id)&&(bscEvent.stage__c=='Confirmed'||bscEvent.stage__c=='Provisional'))
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
    	}
    }*/
}