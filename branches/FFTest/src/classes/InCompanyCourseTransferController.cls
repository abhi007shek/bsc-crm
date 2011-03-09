/*
    Code Coverage - 87%
    Created by Ben Mansfield 14 July 2010
    Modified by Ben Mansfield 6 August 2010
    
    Description:
    
    Changes:
        
        5 August 2010
        * Simplified company transfer by only cloning event bookings and assuming the user 
            has created a new event to transfer to.
            
        6 August 2010:
        * Changed way products are added to transfer fee opp - now takes pricebook into account
    
*/
public with sharing class InCompanyCourseTransferController
{
    private static final String ERROR_NO_ORIGINAL_EVENT = 'Cannot find original event.';
    private static final String ERROR_NO_TRANSFERRED_TO_EVENT = 'Cannot find transferred to event. ' +
        'Please make sure this field has been populated on the original event.';
    private static final String ERROR_MULTIPLE_TRANSFER_EVENT = 'Only one event can be selected when transferring a booking.';
    private static final String ERROR_NO_PRODUCT_FOR_EVENT = 'Cannot find \'Transfer Fees (In-Company)\' product. ' +
        'Please make sure this product is in the system and has been assigned to the correct pricebooks.';
    
    private Special_Event__c event;
    public Boolean transferSuccess { get; set; }

    public InCompanyCourseTransferController(ApexPages.StandardController controller)
    {
        transferSuccess = false;
        event = (Special_Event__c) controller.getRecord();
    }
    
    public PageReference doAction()
    {
        if (event != null)
        {
            return doCompanyTransfer(event);
        }
        
        return null;
    }
    
    private PageReference doCompanyTransfer(Special_Event__c target)
    {
        System.savePoint sp = Database.setSavepoint();
        
        List<Special_Event__c> originalEvent = new List<Special_Event__c>([
            SELECT
                Id,
                Opportunity__c,
                Transferred_To__c,
                Status__c
            FROM
                Special_Event__c
            WHERE
                Id = :target.Id Limit 1]);
                
/*                                              Select s.Venue__c, s.Venue_Region__c, s.Venue_Flat_Rate__c, 
                                                s.Venue_Delegate_Day_Rate__c, s.Type__c, s.Transferred_To__c, 
                                                s.Transferred_From__c, s.Transfer_Cancellation_Fees__c, 
                                                s.Trainer_Sustenance__c, s.Trainer_Fees__c, 
                                                s.Trainer_Accommodation_Days__c, 
                                                s.Trainer_Accommodation_Day_Rate__c, 
                                                s.Total_Venue_Costs_Reporting__c, s.Total_Variable_Costs__c, 
                                                s.Total_Fixed_Costs__c, s.Template_Event__c, 
                                                s.Target_Contribution_Product__c, s.Target_Contribution_Event__c, 
                                                s.Status__c, s.StartDate__c, s.Stage__c, 
                                                s.Sales_Provisional_Extension_Granted__c, 
                                                s.Sales_Provisional_Expiry_Date__c, s.Sales_Notes__c, 
                                                s.Sales_Commission_rate__c, s.Required_Revenue__c, 
                                                s.RecordTypeId, s.Provisional_Bookings__c, s.Product__c, 
                                                s.PK_CB_COURSE_ID__c, s.OwnerId, s.Opportunity__c, 
                                                s.Opportunity_Revenue__c, s.No_of_Delegates_Booked__c, 
                                                s.Name, s.Minimum_Places__c, s.Migrated__c, 
                                                s.Maximum_Places__c, s.Latest_Start_Date__c, 
                                                s.IsActive__c, 
                                                s.International__c, s.Grand_Total_Revenue__c, 
                                                s.Grand_Total_Costs__c, s.FK_CB_USER_LOGIN_ID__c, 
                                                s.FK_CB_BOOK_ID__c, s.Event_Description__c, s.Event_Budget__c, 
                                                s.Event_Auto_Number__c, s.Event_Agenda__c, s.EndDate__c, 
                                                s.Duration__c, s.Delegates_Needed__c, s.Delegate_Pack_Costs__c, 
                                                s.Delegate_Fees__c, s.Current_Profit__c, s.Current_Margin__c, 
                                                s.CurrencyIsoCode, 
                                                s.Course_Note_Costs__c, s.Courier_Costs__c, 
                                                s.Client_Provisional_Extension_Granted__c, 
                                                s.Client_Provisional_Expiry_Date__c, s.City__c, 
                                                s.Average_Variable_Revenue__c, s.Average_Variable_Costs__c, 
                                                s.Ad_Hoc_Variable_Costs__c, s.Ad_Hoc_Fixed_Costs__c 
                                                From Special_Event__c s Where Id = :target.Id Limit 1];*/
        if (originalEvent.size() == 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_NO_ORIGINAL_EVENT));
            return null;
        }
                        
        List<Special_Event__c> newEvent = new List<Special_Event__c>([
            SELECT
                Id,
                Transferred_From__c
            FROM
                Special_Event__c
            WHERE
                Id = :originalEvent.get(0).Transferred_To__c Limit 1]);

/*      Select s.Venue__c, s.Venue_Region__c, s.Venue_Flat_Rate__c, 
                                                s.Venue_Delegate_Day_Rate__c, s.Type__c, s.Transferred_To__c, 
                                                s.Transferred_From__c, s.Transfer_Cancellation_Fees__c, 
                                                s.Trainer_Sustenance__c, s.Trainer_Fees__c, 
                                                s.Trainer_Accommodation_Days__c, 
                                                s.Trainer_Accommodation_Day_Rate__c, 
                                                s.Total_Venue_Costs_Reporting__c, s.Total_Variable_Costs__c, 
                                                s.Total_Fixed_Costs__c, s.Template_Event__c, 
                                                s.Target_Contribution_Product__c, s.Target_Contribution_Event__c, 
                                                s.Status__c, s.StartDate__c, s.Stage__c, 
                                                s.Sales_Provisional_Extension_Granted__c, 
                                                s.Sales_Provisional_Expiry_Date__c, s.Sales_Notes__c, 
                                                s.Sales_Commission_rate__c, s.Required_Revenue__c, 
                                                s.RecordTypeId, s.Provisional_Bookings__c, s.Product__c, 
                                                s.PK_CB_COURSE_ID__c, s.OwnerId, s.Opportunity__c, 
                                                s.Opportunity_Revenue__c, s.No_of_Delegates_Booked__c, 
                                                s.Name, s.Minimum_Places__c, s.Migrated__c, 
                                                s.Maximum_Places__c, s.Latest_Start_Date__c, 
                                                s.IsActive__c, 
                                                s.International__c, s.Grand_Total_Revenue__c, 
                                                s.Grand_Total_Costs__c, s.FK_CB_USER_LOGIN_ID__c, 
                                                s.FK_CB_BOOK_ID__c, s.Event_Description__c, s.Event_Budget__c, 
                                                s.Event_Auto_Number__c, s.Event_Agenda__c, s.EndDate__c, 
                                                s.Duration__c, s.Delegates_Needed__c, s.Delegate_Pack_Costs__c, 
                                                s.Delegate_Fees__c, s.Current_Profit__c, s.Current_Margin__c, 
                                                s.CurrencyIsoCode, 
                                                s.Course_Note_Costs__c, s.Courier_Costs__c, 
                                                s.Client_Provisional_Extension_Granted__c, 
                                                s.Client_Provisional_Expiry_Date__c, s.City__c, 
                                                s.Average_Variable_Revenue__c, s.Average_Variable_Costs__c, 
                                                s.Ad_Hoc_Variable_Costs__c, s.Ad_Hoc_Fixed_Costs__c 
                                                From Special_Event__c s Where Id = :originalEvent.get(0).Transferred_To__c Limit 1];*/
        
        if (newEvent.size() == 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_NO_TRANSFERRED_TO_EVENT));
            return null;
        }
        
        List<Special_Event_Booking__c> deleteCurrentBooking = 
            new List<Special_Event_Booking__c>([Select id from Special_Event_Booking__c where Special_Event__c=:newEvent.get(0).Id ]);
            
            delete deleteCurrentBooking ;
        
        List<Special_Event_Booking__c> bookingsToClone = [
            SELECT
                Transferred_To__c,
                Transferred_From__c, 
                Transfer_Cancellation_Date__c,
                Status__c,
                OPL_ID__c,
                Primary_Booking__c,
                Type__c,
                Special_Event__c, 
                Special_Event__r.Product__c,
                PK_CB_ELEM_ID__c,
                Opportunity__c, 
                Opportunity_ID__c,
                Name,
                Fee_Date__c,
                FK_CB_COURSE_ID__c, 
                FK_CB_BOOK_ID__c,
                Event_end_Date__c,
                Event_Start_Date__c, 
                CurrencyIsoCode,
                Contact__c,
                Company__c,
                Booking_Fee__c 
            FROM
                Special_Event_Booking__c
            WHERE
                Special_Event__c = :target.Id];
        
        List<Special_Event_Booking__c> clonedBookings = bookingsToClone.deepClone(false);
        
        
        // Make sure the new event's transferred from field has been populated
        newEvent.get(0).Transferred_From__c = target.Id;
        update newEvent;
        
        
        // Set cloned booking Transferred_From__c to bookingsToClone ids;
        // Here's hoping the original and cloned lists are in the same order since there is no way to identify
        // which clone belongs to which original
        for (Integer x = 0; x < clonedBookings.size(); x++)
        {
            if(bookingsToClone.get(x).Primary_Booking__c)
                clonedBookings.get(x).Type__c = 'In-Company Primary';
            else{
                clonedBookings.get(x).Type__c = 'In-Company Additional';
            }
            clonedBookings.get(x).Transferred_From__c = bookingsToClone[x].Id;
            // link cloned bookings to cloned event
            clonedBookings.get(x).Special_Event__c = newEvent.get(0).Id;
        }
        // insert cloned bookings 
        insert clonedBookings;
        
        // Get the old opportunity
        List<Opportunity> opportunityQuery = [
            SELECT
                Id,
                OwnerId,
                Name,
                RecordTypeId,
                Type,
                AccountId,
                Pricebook2Id
            FROM
                Opportunity
            WHERE
                Id = :originalEvent.get(0).Opportunity__c];
        if (opportunityQuery.size() != 1)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_MULTIPLE_TRANSFER_EVENT));
            return null;
        }
        
        Opportunity oldOpp = opportunityQuery.get(0);
        
        // Create new opportunity
        Opportunity newOpp = new Opportunity(
            OwnerId = oldOpp.OwnerId,
            // brm - 19 July 2010 - added account id to new opp
            AccountId = oldOpp.AccountId,
            Name = oldOpp.Name + ' - Transfer Fee',
            // brm - 6 August 2010 - add pricebook id to new opp
            Pricebook2Id = oldOpp.Pricebook2Id,
            RecordTypeId = oldOpp.RecordTypeId,
            Type = oldOpp.Type,
            CloseDate = System.today(),
            StageName = 'Quote/Negotiation',
            Rollover_Opportunity__c = true,
            Original_Opportunity__c = oldOpp.Id);
        insert newOpp;
        
        
        // update original event
        // Case 00001404
        // originalEvent.get(0).Status__c = 'To be transferred';
        originalEvent.get(0).Status__c = 'Transferred';
        // End of Case 00001404
        // brm - 19 July 2010 - move old event from old opp to new opp
        originalEvent.get(0).Opportunity__c = newOpp.Id;
        update originalEvent.get(0);
        
        // Get in-company transfer fee product - brm - 6 August 2010 - now takes into account the pricebook
        Map<String, PricebookEntry> entries = BookingHelper.getPricebookEntries(
            newOpp.Pricebook2Id, new String[] { 'Transfer Fees (In-Company)' } );
        
        // Create a new line item for the new opp
        OpportunityLineItem oli = null;
        if (entries.containsKey('Transfer Fees (In-Company)'))
        {
            oli = new OpportunityLineItem();
            oli.PricebookEntryId = entries.get('Transfer Fees (In-Company)').Id;
            oli.OpportunityId = newOpp.Id;
            oli.Quantity = 1;
        }
        else
        {
            // brm - 6 August 2010 - if we can't find product, rollback database and add error
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_NO_PRODUCT_FOR_EVENT));
            return null;
        }
        
        // Get all product ids from original bookings
        Set<Id> productIds = new Set<Id>();
        for (Integer x = 0; x < bookingsToClone.size(); x++)
        {
            productIds.add(bookingsToClone.get(x).Special_Event__r.Product__c);
        }
        
        // Get all products related to original event bookings
        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT
                Id,
                Transfer_Charge_Day_1__c, 
                Transfer_Charge_Day_2__c, 
                Transfer_Charge_Day_3__c,
                Transfer_Charge_Fee_1__c, 
                Transfer_Charge_Fee_2__c,
                Transfer_Charge_Fee_3__c, 
                Transfer_Charge_Fee_Final__c
            FROM
                Product2
            WHERE
                Id in :productIds]);
        
        
        Double totalSalesPrice = 0;
        for (Integer x = 0; x < bookingsToClone.size(); x++)
        {
            //Need to be checked
            bookingsToClone.get(x).OPL_ID__c  = oli.Id;
            // Set old Booking Status__c to 'Transferred'
            bookingsToClone.get(x).Status__c = 'Transferred';
            // Set old Booking Transfer_Cancellation_Date__c to System.today();
            bookingsToClone.get(x).Transfer_Cancellation_Date__c = System.today();
            // Set Transferred_To__c = clonedBookings;
            bookingsToClone.get(x).Transferred_To__c = clonedBookings.get(x).Id;
            // Link original bookings to new opportunity
            bookingsToClone.get(x).Opportunity__c = newOpp.Id;
            
            // Calculate booking fee
            bookingsToClone.get(x).Booking_Fee__c = BookingHelper.calculateTransferCost(
                bookingsToClone.get(x), productMap.get(bookingsToClone.get(x).Special_Event__r.Product__c));
            totalSalesPrice += bookingsToClone.get(x).Booking_Fee__c;
            
            //Double currentSalesPrice = BookingHelper.calculateTransferCost(bookingsToClone.get(x), productMap.get(bookingsToClone.get(x).Special_Event__r.Product__c));
            //totalSalesPrice += currentSalesPrice;
        }
        update bookingsToClone;
        
        // Add total price of all bookings to opportunity product
        if (oli != null)
        {
            if (originalEvent.get(0).BSC_Transfer_Request__c)
            {
                oli.UnitPrice = 0.0;
                oli.T_C_Price__c = 0.0;
            }
            else
            {
                oli.UnitPrice = totalSalesPrice;
                oli.T_C_Price__c = totalSalesPrice;
            }
            insert oli;
            for (Integer x = 0; x < bookingsToClone.size(); x++)
            {
                bookingsToClone.get(x).OPL_ID__c  = oli.Id;
            }
            update bookingsToClone;
        }
        
        
        transferSuccess = true;
        return new PageReference('/' + newEvent.get(0).Id);
    }
    
    /*private PageReference old_doCompanyTransfer(Special_Event__c target)
    {
        List<Special_Event__c> eventsToClone = [Select s.Venue__c, s.Venue_Region__c, s.Venue_Flat_Rate__c, 
                                                s.Venue_Delegate_Day_Rate__c, s.Type__c, s.Transferred_To__c, 
                                                s.Transferred_From__c, s.Transfer_Cancellation_Fees__c, 
                                                s.Trainer_Sustenance__c, s.Trainer_Fees__c, 
                                                s.Trainer_Accommodation_Days__c, 
                                                s.Trainer_Accommodation_Day_Rate__c, 
                                                s.Total_Venue_Costs_Reporting__c, s.Total_Variable_Costs__c, 
                                                s.Total_Fixed_Costs__c, s.Template_Event__c, 
                                                s.Target_Contribution_Product__c, s.Target_Contribution_Event__c, 
                                                s.Status__c, s.StartDate__c, s.Stage__c, 
                                                s.Sales_Provisional_Extension_Granted__c, 
                                                s.Sales_Provisional_Expiry_Date__c, s.Sales_Notes__c, 
                                                s.Sales_Commission_rate__c, s.Required_Revenue__c, 
                                                s.RecordTypeId, s.Provisional_Bookings__c, s.Product__c, 
                                                s.PK_CB_COURSE_ID__c, s.OwnerId, s.Opportunity__c, 
                                                s.Opportunity_Revenue__c, s.No_of_Delegates_Booked__c, 
                                                s.Name, s.Minimum_Places__c, s.Migrated__c, 
                                                s.Maximum_Places__c, s.Latest_Start_Date__c, 
                                                s.IsActive__c, 
                                                s.International__c, s.Grand_Total_Revenue__c, 
                                                s.Grand_Total_Costs__c, s.FK_CB_USER_LOGIN_ID__c, 
                                                s.FK_CB_BOOK_ID__c, s.Event_Description__c, s.Event_Budget__c, 
                                                s.Event_Auto_Number__c, s.Event_Agenda__c, s.EndDate__c, 
                                                s.Duration__c, s.Delegates_Needed__c, s.Delegate_Pack_Costs__c, 
                                                s.Delegate_Fees__c, s.Current_Profit__c, s.Current_Margin__c, 
                                                s.CurrencyIsoCode, 
                                                s.Course_Note_Costs__c, s.Courier_Costs__c, 
                                                s.Client_Provisional_Extension_Granted__c, 
                                                s.Client_Provisional_Expiry_Date__c, s.City__c, 
                                                s.Average_Variable_Revenue__c, s.Average_Variable_Costs__c, 
                                                s.Ad_Hoc_Variable_Costs__c, s.Ad_Hoc_Fixed_Costs__c 
                                                From Special_Event__c s Where Id = :target.Id Limit 1];
        
        Special_Event__c clonedEvent = eventsToClone.get(0).clone(false, true);
        
        List<Special_Event_Unit__c> unitsToClone = [Select s.Venue__c, s.Unit_Start_Time__c, 
                                            s.Unit_Description__c, s.Special_Event__c, s.Name__c, s.Name, 
                                            s.Duration__c, s.CurrencyIsoCode, s.BSC_Event_Trainer__c 
                                            From Special_Event_Unit__c s Where Special_Event__c = :target.Id];
        
        List<Special_Event_Unit__c> clonedUnits = unitsToClone.deepClone(false);
        
        List<Special_Event_Booking__c> bookingsToClone = [Select s.Transferred_To__c, s.Transferred_From__c, 
                                        s.Transfer_Cancellation_Date__c, s.Status__c, s.Special_Event__c, 
                                        s.Special_Event__r.Product__c, s.PK_CB_ELEM_ID__c, s.Opportunity__c, 
                                        s.Opportunity_ID__c, s.Name, s.Fee_Date__c, s.FK_CB_COURSE_ID__c, 
                                        s.FK_CB_BOOK_ID__c, s.Event_end_Date__c, s.Event_Start_Date__c, 
                                        s.CurrencyIsoCode, s.Contact__c, s.Company__c, s.Booking_Fee__c 
                                        From Special_Event_Booking__c s Where Special_Event__c = :target.Id];
        
        List<Special_Event_Booking__c> clonedBookings = bookingsToClone.deepClone(false);
        
        /*List<Special_Event_Cost__c> costsToClone = [Select s.Type__c, s.Supplier__c, s.Purpose__c, s.Name, 
                                        s.E__c, s.Date_Due__c, s.CurrencyIsoCode, s.Bill_Date__c, 
                                        s.Bill_Amount__c, s.BSC_Event__c 
                                        From Special_Event_Cost__c s Where BSC_Event__c = :target.Id];*//*
        List<Special_Event_Cost__c> costsToClone = [Select BSC_Event__c, Amount__c, Category__c,
                                        Description__c, Details__c, Supplier__c
                                        From Special_Event_Cost__c Where BSC_Event__c = :target.Id];
        
        List<Special_Event_Cost__c> clonedCosts = costsToClone.deepClone(false);
        
        clonedEvent.Transferred_From__c = target.Id;
        
        // insert cloned event
        insert clonedEvent;
        
        // update original event
        target.Transferred_To__c = clonedEvent.Id;
        target.Status__c = 'To be transferred';
        update target;
        
        for (Integer x = 0; x < clonedUnits.size(); x++)
        {
            // link cloned units to cloned event
            clonedUnits.get(x).Special_Event__c = clonedEvent.Id;
        }
        // insert cloned units
        insert clonedUnits;
        
        // Set cloned booking Transferred_From__c to bookingsToClone ids;
        // Here's hoping the original and cloned lists are in the same order since there is no way to identify
        // which clone belongs to which original
        for (Integer x = 0; x < clonedBookings.size(); x++)
        {
            clonedBookings.get(x).Transferred_From__c = bookingsToClone[x].Id;
            // link cloned bookings to cloned event
            clonedBookings.get(x).Special_Event__c = clonedEvent.Id;
        }
        // insert cloned bookings
        insert clonedBookings;
        
        for (Integer x = 0; x < clonedCosts.size(); x++)
        {
            // link cloned costs to cloned event
            clonedCosts.get(x).BSC_Event__c = clonedEvent.Id;
        }
        // insert cloned costs
        insert clonedCosts;
        
        // Get the old opportunity
        List<Opportunity> opportunityQuery = [Select Id, OwnerId, Name, RecordTypeId, Type, AccountId From Opportunity Where Id = :eventsToClone.get(0).Opportunity__c];
        if (opportunityQuery.size() != 1)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Only one event can be selected when transferring a booking.'));
            return null;
        }
        
        Opportunity oldOpp = opportunityQuery.get(0);
        
        // Create new opportunity
        Opportunity newOpp = new Opportunity();
        newOpp.OwnerId = oldOpp.OwnerId;
        // brm - 19 July 2010 - added account id to new opp
        newOpp.AccountId = oldOpp.AccountId;
        newOpp.Name = oldOpp.Name + ' - Transfer Fee';
        newOpp.RecordTypeId = oldOpp.RecordTypeId;
        newOpp.Type = oldOpp.Type;
        newOpp.CloseDate = System.today();
        newOpp.StageName = 'Quote/Negotiation';
        newOpp.Rollover_Opportunity__c = true;
        newOpp.Original_Opportunity__c = oldOpp.Id;
        insert newOpp;
        
        // brm - 19 July 2010 - move old event from old opp to new opp
        eventsToClone.get(0).Opportunity__c = newOpp.Id;
        update eventsToClone;
        
        // Get in-company transfer fee product
        List<PricebookEntry> entries = [Select Id From PricebookEntry Where Product2.Name = 'Transfer Fees (In-Company)'];
        
        // Create a new line item for the new opp
        OpportunityLineItem oli = null;
        if (entries.size() == 1)
        {
            oli = new OpportunityLineItem();
            oli.PricebookEntryId = entries[0].Id;
            oli.OpportunityId = newOpp.Id;
            oli.Quantity = 1;
        }
        
        // Get all product ids from original bookings
        Set<Id> productIds = new Set<Id>();
        for (Integer x = 0; x < bookingsToClone.size(); x++)
        {
            productIds.add(bookingsToClone.get(x).Special_Event__r.Product__c);
        }
        
        // Get all products related to original event bookings
        Map<Id, Product2> productMap = new Map<Id, Product2>([Select Id, Transfer_Charge_Day_1__c, 
                                        Transfer_Charge_Day_2__c, 
                                        Transfer_Charge_Day_3__c, Transfer_Charge_Fee_1__c, 
                                        Transfer_Charge_Fee_2__c, Transfer_Charge_Fee_3__c, 
                                        Transfer_Charge_Fee_Final__c From Product2
                                        Where Id in :productIds]);
        
        
        Double totalSalesPrice = 0;
        for (Integer x = 0; x < bookingsToClone.size(); x++)
        {
            // Set old Booking Status__c to 'Transferred'
            bookingsToClone.get(x).Status__c = 'Transferred';
            // Set old Booking Transfer_Cancellation_Date__c to System.today();
            bookingsToClone.get(x).Transfer_Cancellation_Date__c = System.today();
            // Set Transferred_To__c = clonedBookings;
            bookingsToClone.get(x).Transferred_To__c = clonedBookings.get(x).Id;
            // Link original bookings to new opportunity
            bookingsToClone.get(x).Opportunity__c = newOpp.Id;
            
            // Calculate booking fee
            bookingsToClone.get(x).Booking_Fee__c = BookingHelper.calculateTransferCost(bookingsToClone.get(x), productMap.get(bookingsToClone.get(x).Special_Event__r.Product__c));
            totalSalesPrice += bookingsToClone.get(x).Booking_Fee__c;
            
            //Double currentSalesPrice = BookingHelper.calculateTransferCost(bookingsToClone.get(x), productMap.get(bookingsToClone.get(x).Special_Event__r.Product__c));
            //totalSalesPrice += currentSalesPrice;
        }
        update bookingsToClone;
        
        // Add total price of all bookings to opportunity product
        if (oli != null)
        {
            oli.UnitPrice = totalSalesPrice;
            oli.T_C_Price__c = totalSalesPrice;
            insert oli;
        }
        
        
        return new PageReference('/' + clonedEvent.Id);
    }*/
    
    @IsTest
    private static void test()
    {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Closed Won',
            CloseDate = System.today());
        insert opp;

		Product2 productExist = [Select p.ProductCode, p.Name, p.Length__c, p.Id 
		                    From Product2 p
                            where length__c = 1
                            limit 1 ][0];
                                    
        Special_Event__c event = new Special_Event__c(
            Product__c = productExist.Id,
            StartDate__c = System.today() + 10,
            Opportunity__c = opp.Id);
        insert event;
        
        Special_Event__c eventTo = new Special_Event__c(
            Product__c = productExist.Id,
            StartDate__c = System.today() + 10,
            Opportunity__c = opp.Id);
        insert eventTo;
        
        event.Transferred_To__c = eventTo.Id;
        update event;
        
        Special_Event_Unit__c eventunit = new Special_Event_Unit__c(
            Special_Event__c = event.Id);
        insert eventunit;
        
        Special_Event_Cost__c eventcost = new Special_Event_Cost__c(
            BSC_Event__c = event.Id);
        insert eventcost;
        
        Special_Event_Booking__c eventbooking = new Special_Event_Booking__c(
            Special_Event__c = event.Id);
        insert eventbooking;
        
        ApexPages.Standardcontroller standard = new ApexPages.Standardcontroller(event);
        InCompanyCourseTransferController controller = new InCompanyCourseTransferController(standard);
        controller.doAction();
    }

}