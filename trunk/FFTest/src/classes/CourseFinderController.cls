/*
    Created by Ben Mansfield 12 July 2010
    Modified by Ben Mansfield 6 August 2010
    
    Description:
         
        Event Bookings:
        bookingType - 'Booking';
        
        Allows a user to book BSC Events for contacts on an opportunity. This searches for events by
        getting users to enter search criteria, such as event location, event start date, etc.
        
        Event Transfer:
        bookingType - 'Transfer';
        
        This component also allows users to transfer a booking to a different event using a similar search
        facility as in the event bookings. Transfer fees are applied.
        
    Changes:
    
        19 July 2010
        * Now calculates booking fee when booking an event
        
        20 July 2010
        * Calculates transfer fee on old booking
        
        4 August 2010
        * Start date set to today's date
        * Product table now displays the following headers (Booking only): number of delegates, 
            maximum delegates, required delegates and removed product header
        * Event Name now a link in product table (Booking only)
        * When creating unknown delegate bookings, account id is added to the booking
        * When using transfer functionality, now moved most of the transfer logic to a 'confirm transfer' page
        
        6 August 2010
        * Now creates BSC Event Unit Bookings when booking events.
        * Added error if no contacts or unknown delegates have been selected
         
*/
public with sharing class CourseFinderController
{
    // Error messages   
    private static final String ERROR_MULTIPLE_EVENTS =         'Only one event can be selected when transferring a booking.';
    private static final String ERROR_SAME_EVENT_TRANSFER =     'You cannot transfer a booking to the same event.';
    private static final String ERROR_NO_EVENT_SELECTED =       'Please select at least one event.';
    private static final String ERROR_INVALID_UNK_DELEGATES =   'The Unknown Delegates field is not a valid number.';
    private static final String ERROR_NO_CONTACT_UNK_DELEGATE = 'Please select at least one contact or specify at least one unknown delegate.';
    
    private Boolean requiresInit;
    
    // Used for booking
    public Opportunity opportunity                  { get; set { this.opportunity = value; if (requiresInit) initialise(); } }
    
    // Used for transfer
    public Special_Event_Booking__c booking         { get; set { this.booking = value; if (requiresInit) initialise(); } }
    
    public String bookingType                       { get; set { this.bookingType = value; if (requiresInit) initialise(); } }
    
    // Page 1
    public Special_Event__c eventCriteria           { get; set; }
    public String[] locationCriteria                { get; set; }
    
    public List<Product> productSelections          { get; set; }
    // transfer only
    public Boolean customerTransferRequest          { get; set; }
    
    // Page 2
    // booking
    public List<Product> eventSelectionsByProduct   { get; set; }
    // transfer
    public List<BSCEvent> eventSelections           { get; set; }
    
    // Page 3
    public List<BSCEvent> eventUnitSelections       { get; set; }
    
    // Page 4 - booking only
    public List<OpportunityContact> linkedContacts  { get; private set; }
    public String numberUnknownDelegates            { get; set; }
    
    
    public Integer pageNum                          { get; private set; }
    private final Integer maxPages = 4;
    
    public CourseFinderController()
    {
        requiresInit = true;
        locationCriteria = new String[] {};
        // Select all locations as default
        for (SelectOption so : getEventCityPicklistOptions())
        {
            locationCriteria.add(so.getValue());
        }
    }
    
    public void initialise()
    {
        // If the booking type is null, don't initialise yet
        if (bookingType == null)
            return;
        // If both opportunity and booking are null, don't initialise yet
        if (opportunity == null && booking == null)
            return;
        
        eventCriteria = new Special_Event__c(StartDate__c = System.today());
        if (bookingType == 'Booking')
        {
            productSelections = generateProductList(opportunity);       
            linkedContacts = new List<OpportunityContact>();
            for (OpportunityContactRole ocr : [
                SELECT
                    Id,
                    Contact.Name,
                    Contact.Title,
                    Contact.AccountId
                FROM
                    OpportunityContactRole 
                WHERE
                    Role = 'Potential Delegate'
                AND
                    OpportunityId = :opportunity.Id])
            {
                linkedContacts.add(new OpportunityContact(ocr));
            }
        }
        else if (bookingType == 'Transfer')
        {
            productSelections = null;
            linkedContacts = null;
            customerTransferRequest = true;
        }
        
        pageNum = 1;
        requiresInit = false;
    }
    
    private List<Product> generateProductList(Opportunity target)
    {
        List<Product> prods = new List<Product>();
        if (target != null)
        {
            for (OpportunityLineItem oli : target.OpportunityLineItems)
            {
                if (oli.PricebookEntry.Product2.Allows_Provisional_Bookings__c)
                    prods.add(new Product(oli));
            }
        }
        
        return prods;
    }
    
    private void generateBSCEvents()
    {
        Set<Id> productIds = new Set<Id>();
        if (bookingType == 'Booking')
        {
            for (Product p : productSelections)
            {
                if (p.selected == true)
                {
                    productIds.add(p.record.PricebookEntry.Product2Id);
                }
            }
        }
        else if (bookingType == 'Transfer')
            productIds.add(booking.Special_Event__r.Product__c);
        
        List<Special_Event__c> selectedEvents = [
            SELECT
                Id,
                Name,
                Product__c,
                StartDate__c,
                EndDate__c,
                City__c,
                Maximum_Places__c,
                No_of_Delegates_Booked__c,
                Minimum_Places__c
            FROM
                Special_Event__c
            WHERE
                City__c in :locationCriteria
            AND
                Status__c ='Confirmed' 
            AND
                StartDate__c >= :eventCriteria.StartDate__c
            AND
                EndDate__c <= :eventCriteria.EndDate__c
            AND
                Product__c in :productIds];
        
        // Group events by products for bookings
        if (bookingType == 'Booking')
        {
            eventSelectionsByProduct = new List<Product>();
            for (Product p : productSelections)
            {
                if (p.selected == true)
                {
                    Product selected = new Product(p.record);
                    selected.events = new List<BSCEvent>();
                    for (Special_Event__c bscEvent : selectedEvents)
                    {
                        if (bscEvent.Product__c == selected.record.PricebookEntry.Product2Id &&
                            (eventCriteria.Maximum_Places__c == null ||
                            bscEvent.Maximum_Places__c == null ||
                            (bscEvent.Maximum_Places__c - bscEvent.No_of_Delegates_Booked__c) >= eventCriteria.Maximum_Places__c))
                        {
                            selected.events.add(new BSCEvent(bscEvent));
                        }
                    }
                    eventSelectionsByProduct.add(selected);
                }
            }
        }
        // Show all events for transfer
        else if (bookingType == 'Transfer')
        {
            eventSelections = new List<BSCEvent>();
            for (Special_Event__c bscEvent : selectedEvents)
            {
                if (eventCriteria.Maximum_Places__c == null ||
                    bscEvent.Maximum_Places__c == null ||
                    (bscEvent.Maximum_Places__c - bscEvent.No_of_Delegates_Booked__c) >= eventCriteria.Maximum_Places__c)
                {
                    eventSelections.add(new BSCEvent(bscEvent));
                }
            }
        }
    }
    
    private Boolean generateBSCEventUnits()
    {
        Set<Id> eventIds = new Set<Id>();
        
        if (bookingType == 'Booking')
        {
            for (Product p : eventSelectionsByProduct)
            {
                for (BSCEvent e : p.events)
                {
                    if (e.selected == true)
                    {
                        eventIds.add(e.record.Id);
                    }
                }
            }
        }
        else if (bookingType == 'Transfer')
        {
            for (BSCEvent e : eventSelections)
            {
                if (e.selected == true)
                    eventIds.add(e.record.Id);
            }
            if (eventIds.size() > 1)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_MULTIPLE_EVENTS));
                return false;
            }
            if (eventIds.contains(booking.Special_Event__c))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_SAME_EVENT_TRANSFER));
                return false;
            }
        }
        if (eventIds.size() == 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_NO_EVENT_SELECTED));
            return false;
        }
        
        List<Special_Event_Unit__c> selectedEventUnits = [
            SELECT
                Id,
                Name,
                Unit_Description__c,
                Venue__c,
                Unit_Start_Time__c,
                Duration__c,
                Special_Event__c
            FROM
                Special_Event_Unit__c
            WHERE
                Special_Event__c in :eventIds
            AND
                Mandatory__c = true];
        
        eventUnitSelections = new List<BSCEvent>();
        if (bookingType == 'Booking')
        {
            for (Product p : eventSelectionsByProduct)
            {
                for (BSCEvent e : p.events)
                {
                    if (e.selected == true)
                    {
                        BSCEvent selected = new BSCEvent(e.record);
                        selected.units = new List<BSCEventUnit>();
                        for (Special_Event_Unit__c bscEventUnit : selectedEventUnits)
                        {
                            if (bscEventUnit.Special_Event__c == e.record.Id)
                            {
                                selected.units.add(new BSCEventUnit(bscEventUnit));
                            }
                        }
                        eventUnitSelections.add(selected);
                    }
                }
            }
        }
        else if (bookingType == 'Transfer')
        {
            for (BSCEvent e : eventSelections)
            {
                if (e.selected == true)
                {
                    BSCEvent selected = new BSCEvent(e.record);
                    selected.units = new List<BSCEventUnit>();
                    for (Special_Event_Unit__c bscEventUnit : selectedEventUnits)
                    {
                        if (bscEventUnit.Special_Event__c == e.record.Id)
                        {
                            selected.units.add(new BSCEventUnit(bscEventUnit));
                        }
                    }
                    eventUnitSelections.add(selected);
                }
            }
        }
        
        return true;
    }
    
    public SelectOption[] getEventCityPicklistOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
        for (Schema.Picklistentry pe : Schema.SObjectType.Special_Event__c.fields.City__c.getPicklistValues())
        {
            if (pe.isActive())
                options.add(new SelectOption(pe.getValue(), pe.getLabel()));
        }
        return options;
    }
    
    public void next()
    {
        if (pageNum < maxPages) pageNum++;
        
        if (pageNum == 2)
        {
            generateBSCEvents();
        }
        else if (pageNum == 3)
        {
            Boolean success = generateBSCEventUnits();
            if (!success)
                pageNum--;
        }
    }
    
    public void prev()
    {
        if (pageNum > 1)
            pageNum--;
    }
    
    public PageReference save()
    {
        if (bookingType == 'Booking')
        {
            return saveBooking();
        }
        else if (bookingType == 'Transfer')
        {
            return transferBooking();
        }
        
        return cancel();
    }
    
    public PageReference saveBooking()
    {
        // Currently saves only for Bookings, not transfer
        Integer unknownCount = -1;
        if (numberUnknownDelegates != null && numberUnknownDelegates != '')
        {
            try
            {
                unknownCount = Integer.valueOf(numberUnknownDelegates);
            }
            catch (Exception e)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_INVALID_UNK_DELEGATES));
                return null;
            }
        }
        
        List<Special_Event_Booking__c> bookings = new List<Special_Event_Booking__c>();
        
        for (Product product : eventSelectionsByProduct)
        {
            // for every selected event
            for (BSCEvent event : product.events)
            {
                if (event.selected)
                {
                    // Sort out unknown delegate bookings first
                    if (unknownCount > 0)
                    {
                        for (Integer x = 0; x < unknownCount; x++)
                        {
                            Special_Event_Booking__c record = new Special_Event_Booking__c(
                                Opportunity__c = opportunity.Id,
                                Special_Event__c = event.record.Id,
                                Booking_Fee__c = product.record.UnitPrice,
                                OPL_ID__c = product.record.Id,
                                Status__c = 'Provisional',
                                Contact__c = null,
                                Type__c = 'Public',
                                Company__c = opportunity.AccountId);                            
                            bookings.add(record);
                        }
                    }
                    
                    // Sort out known delegates if available
                    if (linkedContacts != null && linkedContacts.size() > 0)
                    {
                        for (OpportunityContact oc : linkedContacts)
                        {
                            if (oc.selected)
                            {
                                Special_Event_Booking__c record = new Special_Event_Booking__c(
                                    Opportunity__c = opportunity.Id,
                                    Special_Event__c = event.record.Id,
                                    Booking_Fee__c = product.record.UnitPrice,
                                    OPL_ID__c = product.record.Id,
                                    Status__c = 'Provisional',
                                    Type__c = 'Public',
                                    Contact__c = oc.record.ContactId,
                                    Company__c = oc.record.Contact.AccountId);                              
                                bookings.add(record);
                            }
                        }
                    }
                }
            }
        }
        // brm - 6 August 2010 - if no contacts (or unknown delegates) have been selected, show error
        if (bookings.size() == 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ERROR_NO_CONTACT_UNK_DELEGATE));
            return null;
        }
        
        insert bookings;
        
        // brm - 6 August 2010 - added creation of unit bookings
        List<Special_Event_Unit_Booking__c> unitBookings = new List<Special_Event_Unit_Booking__c>();
        for (Special_Event_Booking__c booking : bookings)
        {
            for (BSCEvent event : eventUnitSelections)
            {
                if (booking.Special_Event__c == event.record.Id)
                {
                    for (BSCEventUnit unit : event.units)
                    {
                        if (unit.selected)
                        {
                            Special_Event_Unit_Booking__c unitBooking = new Special_Event_Unit_Booking__c(
                                Event_Booking__c = booking.Id,
                                Event_Unit__c = unit.record.Id,
                                Contact__c = booking.Contact__c);                           
                            unitBookings.add(unitBooking);
                        }
                    }
                }
            }
        }
        insert unitBookings;
        
        return cancel();
    }
    
    public PageReference transferBooking()
    {
        // brm - 4 August 2010 - Populate Transfer To field on booking.  Transfer confirmation is done in a seperate process
        booking.Transfer_To__c = eventUnitSelections[0].record.Id;
        booking.Customer_Requested_Transfer__c = customerTransferRequest;
        // ab - 6 October 2010 - Set status to 'To Be Transferred' for pending transfers.
        booking.Status__c = 'To Be Transferred';
        update booking;
        
        // brm - 4 August 2010 - Old way of transferring bookings.  Now moved to seperate 'confirm transfer' button
        // Get the old opportunity
        /*List<Opportunity> opps = [Select Id, Name, OwnerId, AccountId From Opportunity Where Id = :booking.Opportunity__c];
        if (opps.size() != 1)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Cannot find original Opportunity for this booking.'));
            return null;
        }
        Opportunity oldOpp = opps.get(0);
        
        List<RecordType> recordTypes = [Select Id From RecordType Where SObjectType = 'Opportunity' and Name = 'Public Event'];
        
        // Create a new opportunity
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = oldOpp.AccountId;
        newOpp.OwnerId = oldOpp.OwnerId;
        newOpp.Name = oldOpp.Name + ' - Transfer Fee';
        if (recordTypes.size() == 1) newOpp.RecordTypeId = recordTypes.get(0).Id;
        newOpp.Type = 'Public Course';
        newOpp.CloseDate = System.today();
        newOpp.StageName = 'Quote/Negotiation';
        newOpp.Rollover_Opportunity__c = true;
        newOpp.Original_Opportunity__c = oldOpp.Id;
        insert newOpp;
        
        // Get public transfer fee product
        List<PricebookEntry> entries = [Select Id From PricebookEntry Where Product2.Name = 'Transfer Fees (Public)'];
        
        // Create a new line item for the new opp
        OpportunityLineItem oli = null;
        if (entries.size() == 1)
        {
            oli = new OpportunityLineItem();
            oli.PricebookEntryId = entries[0].Id;
            oli.OpportunityId = newOpp.Id;
            oli.Quantity = 1;
            oli.UnitPrice = 0;
            oli.T_C_Price__c = 0;
        }
        
        Double transferCost = 0;
        if (customerTransferRequest)
        {
            // Get currently booked product
            List<Product2> products = [Select Id, Transfer_Charge_Day_1__c, Transfer_Charge_Day_2__c, 
                                        Transfer_Charge_Day_3__c, Transfer_Charge_Fee_1__c, 
                                        Transfer_Charge_Fee_2__c, Transfer_Charge_Fee_3__c, 
                                        Transfer_Charge_Fee_Final__c From Product2 
                                        Where Id = :booking.Special_Event__r.Product__c];
            if (products.size() != 1)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Cannot find original Product for this booking.'));
                return null;
            }
            
            // Calculate transfer fees
            transferCost = BookingHelper.calculateTransferCost(booking, products.get(0));
            
            // Set a transfer fee on opportunity product
            if (oli != null)
            {
                oli.UnitPrice = transferCost;
                oli.T_C_Price__c = transferCost;
            }
        }
        if (oli != null) insert oli;
        
        // Create a new BSC Event booking
        Special_Event_Booking__c newBooking = new Special_Event_Booking__c();
        newBooking.Opportunity__c = oldOpp.Id;
        newBooking.Special_Event__c = eventUnitSelections[0].record.Id;
        newBooking.Status__c = 'Provisional';
        newBooking.Contact__c = booking.Contact__c;
        newBooking.Company__c = booking.Company__c;
        newBooking.Transferred_From__c = booking.Id;
        newBooking.Booking_Fee__c = booking.Booking_Fee__c;
        insert newBooking;
        
        // Modify existing event booking
        booking.Status__c = 'Transferred';
        booking.Opportunity__c = newOpp.Id;
        booking.Transferred_To__c = newBooking.Id;
        booking.Booking_Fee__c = transferCost;
        booking.Transfer_Cancellation_Date__c = System.today();
        update booking;*/
        
        return cancel();
    }
    
    public PageReference cancel()
    {
        if (opportunity != null)
            return new PageReference('/' + opportunity.Id);
        if (booking != null)
            return new PageReference('/' + booking.Id);
        
        return new PageReference('/home/home.jsp');
    }
    
    public class Product
    {
        public OpportunityLineItem record       { get; private set; }
        public Boolean selected                 { get; set; }
        
        public List<BSCEvent> events            { get; set; }
        
        public Product(OpportunityLineItem target)
        {
            this.record = target;
            this.selected = true;
        }
    }
    
    public class BSCEvent
    {
        public Special_Event__c record          { get; private set; }
        public Boolean selected                 { get; set; }
        
        public List<BSCEventUnit> units         { get; set; }
        
        public BSCEvent(Special_Event__c target)
        {
            this.record = target;
            this.selected = false;
        }
    }
    
    public class BSCEventUnit
    {
        public Special_Event_Unit__c record     { get; private set; }
        public Boolean selected                 { get; set; }
        
        public BSCEventUnit(Special_Event_Unit__c target)
        {
            this.record = target;
            this.selected = true;
        }
    }
    
    public class OpportunityContact
    {
        public OpportunityContactRole record    { get; private set; }
        public Boolean selected                 { get; set; }
        
        public OpportunityContact(OpportunityContactRole target)
        {
            this.record = target;
            this.selected = false;
        }
    }
    
    
    @IsTest
    private static void testBooking()
    {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualifying',
            IC_Price_Variation_Approved__c = true,
            CloseDate = System.today());
        insert opp;
        
        Product2 prod = new Product2(
            Name = 'Test Event Product',
            Allows_Provisional_Bookings__c = true);
        insert prod;
        
        Pricebook2 stdPricebook = [
            SELECT
                Id
            FROM
                Pricebook2
            WHERE
                IsStandard = true Limit 1];
        
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            UnitPrice = 300,
            Pricebook2Id = stdPricebook.Id,
            IsActive = true);
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Pricing_Exception__c = true,
            Quantity = 3,
            UnitPrice = 320);
        insert oli;
        
        
        Special_Event__c event = new Special_Event__c(
            Product__c = prod.Id,
            City__c = 'London',
            StartDate__c = System.today().addDays(3));
        insert event;
        
        CourseFinderController controller = new CourseFinderController();
        controller.bookingType = 'Booking';
        
        List<Opportunity> oppQuery = [
            SELECT
                Id,
                Name,
                IsWon,
                IsClosed,
                StageName,
                AccountId,
               (SELECT
                    Id,
                    PricebookEntry.Product2.Name,
                    PricebookEntry.Product2.Allows_Provisional_Bookings__c, Quantity,
                    UnitPrice From OpportunityLineItems)
            FROM
                Opportunity
            WHERE
                Id = :opp.id];
                                        
        if (oppQuery.size() == 1)
            opp = oppQuery.get(0);
        
        controller.opportunity = opp;
        controller.locationCriteria.add('London');
        // Select the products
        for (Product p : controller.productSelections)
        {
            p.selected = true;
        }
        
        // Go to event select page
        controller.next();
        System.assertEquals(new List<ApexPages.Message>(), ApexPages.getMessages());
        
        // Select the event we created above
        for (Product p : controller.eventSelectionsByProduct)
        {
            if (p.selected)
            {
                for (BSCEvent e : p.events)
                {
                    e.selected = true;
                }
            }
        }
        
        controller.next();
        //System.assertEquals(new List<ApexPages.Message>(), ApexPages.getMessages());
        
        controller.next();
        //System.assertEquals(new List<ApexPages.Message>(), ApexPages.getMessages());
        
        controller.numberUnknownDelegates = '3';
        controller.save();
        //System.assertEquals(new List<ApexPages.Message>(), ApexPages.getMessages());
        
        // Test Helper functions in controller not part of main wizard flow
        controller.getEventCityPicklistOptions();
    }
    
    @IsTest
    private static void testTransfer()
    {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualifying',
            IC_Price_Variation_Approved__c = true,
            CloseDate = System.today());
        insert opp;
        
        Product2 prod = new Product2(
            Name = 'Test Event Product',
            Allows_Provisional_Bookings__c = true,
            Transfer_Charge_Day_1__c = 10,
            Transfer_Charge_Day_2__c = 5,
            Transfer_Charge_Day_3__c = 2,
            Transfer_Charge_Fee_1__c = 120,
            Transfer_Charge_Fee_2__c = 60,
            Transfer_Charge_Fee_3__c = 40,
            Transfer_Charge_Fee_Final__c = 10);
        insert prod;
        
        Pricebook2 stdPricebook = [
            SELECT
                Id
            FROM
                Pricebook2
            WHERE
                IsStandard = true Limit 1];
        
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            UnitPrice = 300,
            Pricebook2Id = stdPricebook.Id,
            IsActive = true);
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Pricing_Exception__c = true,
            Quantity = 3,
            UnitPrice = 320);
        insert oli;
        
        Special_Event__c event = new Special_Event__c(
            Product__c = prod.Id,
            City__c = 'London',
            StartDate__c = System.today().addDays(3));
        insert event;
        
        Special_Event_Booking__c eventBooking = new Special_Event_Booking__c(
            Opportunity__c = opp.Id,
            Special_Event__c = event.Id);
        insert eventBooking;
        
        // Event to transfer
        Special_Event__c transferevent = new Special_Event__c(
            Product__c = prod.Id,
            City__c = 'London',
            Status__c= 'Confirmed',
            StartDate__c = System.today().addDays(30));
        insert transferevent;
        
        CourseFinderController controller = new CourseFinderController();
        controller.bookingType = 'Transfer';
        
        List<Special_Event_Booking__c> bookingQuery = [
            SELECT
                Id,
                Name,
                Special_Event__r.Product__c,
                Booking_Fee__c,
                Opportunity__c,
                Event_Start_Date__c
            FROM
                Special_Event_Booking__c
            WHERE
                Id = :eventBooking.id];
        
        if (bookingQuery.size() == 1)
            eventBooking = bookingQuery.get(0);
        
        controller.booking = [
            SELECT
                Id,
                Name,
                Special_Event__r.Product__c,
                Contact__c,
                Company__c,
                Booking_Fee__c,
                Opportunity__c,
                Event_Start_Date__c 
            FROM
                Special_Event_Booking__c
            WHERE
                Id = :eventBooking.Id];
        
        controller.locationCriteria.add('London');
        
        controller.next();
        //System.assertEquals(new List<ApexPages.Message>(), ApexPages.getMessages());
        
        // Select the event we created above
        for (BSCEvent ev : controller.eventSelections)
        {
            if (ev.record.Id == transferevent.Id) ev.selected = true;
        }
        
        controller.next();
        //System.assertEquals(new List<ApexPages.Message>(), ApexPages.getMessages());
        
        controller.save();
        //System.assertEquals(new List<ApexPages.Message>(), ApexPages.getMessages());
    }
}