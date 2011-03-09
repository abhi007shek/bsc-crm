/*
    Created by Ben Mansfield 13 July 2010
    Modified by Ben Mansfield 16 July 2010
    
    Description:
    
*/
public with sharing class TransferBookingWizardController {
    
    public Special_Event_Booking__c record { get; set; }
    
    public TransferBookingWizardController()
    {
        record = getEventBooking(ApexPages.CurrentPage().getParameters().get('id'));
    }
    
    private Special_Event_Booking__c getEventBooking(Id id)
    {
        List<Special_Event_Booking__c> bookingQuery = [Select Id, Name, Special_Event__r.Product__c, 
                                                        Contact__c, Company__c,OPL_ID__c, Type__c,
                                                        Booking_Fee__c, Opportunity__c, Event_Start_Date__c 
                                                        From Special_Event_Booking__c Where Id = :id];
        
        if (bookingQuery.size() == 1) return bookingQuery.get(0);
        
        return null;
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
        
        Special_Event_Booking__c eventBooking = new Special_Event_Booking__c();
        eventBooking.Opportunity__c = opp.Id;
        eventBooking.Special_Event__c = event.Id;
        insert eventBooking;
        
       PageReference pagRef = new PageReference('/apex/test');
        pagRef.getParameters().put('id', eventBooking.Id);
        Test.setCurrentPage(pagRef);
        
        //ApexPages.Standardcontroller stdContr = new ApexPages.Standardcontroller(eventBooking);
        TransferBookingWizardController controller = new TransferBookingWizardController();
    }
}