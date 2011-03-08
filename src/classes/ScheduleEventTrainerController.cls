/*
    **** Test Coverage 88%      06-10-10
    Created by Ben Mansfield 15 July 2010
    Modified by Ben Mansfield 4 August 2010
    
    Description:
    
    Changes:
        
        26 July 2010
        * Added events onto calendar view
        * Overlapping of events fixed in calendar view
        * Added save functionality of event trainers
        
        27 July 2010
        * Added error messages if nothing has been selected in some pages
        * Added test method
        * Increased width of calendar to show 5 days
        
        28 July 2010
        * Changed Class field to point to Trainer__c instead of Special_Event_Trainer__c
        * Fixed Go button on Calendar view page so that it doesn't show an error
        * Fixed bug with SOQL query not being able to retrieve multi select picklist values properly
        
        4 August 2010
        * Modified calendar event titles to show information about BSC Event
            * Involved adding code to query for BSC Event Trainers from Salesforce Events
        * Modified so that events are selected based on event start date between start and end of calendar
            (Previously based on event start date and event end date)
        
        1 October 2010
        * Modified calendar to show 7 days after the event.
        * Modified so calendar relates to Event Units, not Events.
        
*/
public with sharing class ScheduleEventTrainerController
{
    private static final String NO_TRAINER_SELECTED =           'Please select at least one trainer.';
    private static final String NO_TRAINER_CALENDAR_SELECTED =  'Please select at least one trainer calendar.';
    private static final String NO_UNIT_SELECTED =              'Please select at least one Event Unit.';
    
    public final Integer calendarCellWidth      { get; set; }   
    public Special_Event__c record              { get; private set; }
    
    // Page 1
    public String nameCriteria                  { get; set; }
    public String[] classCriteria               { get; set; }
    public String[] qualificationsCriteria      { get; set; }
    public String[] industryCriteria            { get; set; }
    public String[] regionCriteria              { get; set; }
    public Boolean internationalCheckbox        { get; set; }
    
    // Page 2
    public List<Trainer> trainerResults         { get; set; }
    
    // Page 3
    public List<Unit> unitResults               { get; set; }   
    
    // Page 4
    public List<Trainer> trainerCalendars       { get; set; }
    public Special_Event__c startDateSearch     { get; set; }
    private List<Special_Event_Unit__c> selectedUnits;
    
    
    public Integer pageNum                      { get; private set; }
    public String ajaxStartDate                 { get; set; }
    private final Integer maxPages = 5;
    
    
    ////////////////DEBUGGING/////////////////////////
    public DateTime dt1 {get; set;}
    public DateTime dt2 {get; set;}
    public String test  {get; set;}
    
    public ScheduleEventTrainerController(ApexPages.StandardController controller)
    {
        calendarCellWidth = 110;
        
        // Filter arrays
        classCriteria = new String[] {};
        qualificationsCriteria = new String[] {};
        industryCriteria = new String[] {};
        regionCriteria = new String[] {};
        
        record = getEvent(controller.getId());
        
        // Set up a new Special Event with this record's start date as a starting point.
        if (record != null)
            startDateSearch = new Special_Event__c(StartDate__c = record.StartDate__c);
        
        pageNum = 1;
    }
    
    private Special_Event__c getEvent(Id id)
    {
        List<Special_Event__c> eventQuery = [
            SELECT
                Id,
                Name,
                Product__c,
                StartDate__c,
                EndDate__c,
                Latest_Start_Date__c
            FROM
                Special_Event__c
            WHERE
                Id = :id];
        if (eventQuery.size() == 1)
            return eventQuery.get(0);
        
        return null;
    }
    
    public SelectOption[] getClassPicklistOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
        
        for (Schema.Picklistentry pe : Schema.SObjectType.Trainer__c.fields.Class__c.getPicklistValues())
        {
            if (pe.isActive())
                options.add(new SelectOption(pe.getValue(), pe.getLabel()));
        }
        
        return options;
    }
    
    public SelectOption[] getQualificationsPicklistOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
        
        for (Schema.Picklistentry pe : Schema.SObjectType.User.fields.Qualifications__c.getPicklistValues())
        {
            if (pe.isActive())
                options.add(new SelectOption(pe.getValue(), pe.getLabel()));
        }
        
        return options;
    }
    
    public SelectOption[] getIndustryPicklistOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
        
        for (Schema.Picklistentry pe : Schema.SObjectType.User.fields.Industry__c.getPicklistValues())
        {
            if (pe.isActive())
                options.add(new SelectOption(pe.getValue(), pe.getLabel()));
        }
        
        return options;
    }
    
    public SelectOption[] getRegionPicklistOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
        
        for (Schema.Picklistentry pe : Schema.SObjectType.User.fields.Region__c.getPicklistValues())
        {
            if (pe.isActive())
                options.add(new SelectOption(pe.getValue(), pe.getLabel()));
        }
        
        return options;
    }
    
    public void next()
    {
        if (pageNum < maxPages)
            pageNum++;
        
        if (pageNum == 2)
        {
            generateTrainerList();
        }
        else if (pageNum == 3)
        {           
            for (Trainer trainer : trainerResults)
            {
                // At least one trainer selected.
                if (trainer.selected)
                {
                    GenerateAvailableUnits();
                    return;
                }
                    
            }
            // No trainer selected.
            pageNum--;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, NO_TRAINER_SELECTED));
            
        }
        else if (pageNum == 4)
        {
            for (Unit unit : unitResults)
            {
                if (unit.selected)
                {
                    Boolean success = generateTrainerCalendars2(true);
                    if (!success)
                        pageNum--;
                    return;
                }
            }
            // No unit selected
            pageNum--;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, NO_UNIT_SELECTED));            
        }
    }
    
    public void prev()
    {
        if (pageNum > 1)
            pageNum--;
    }
    
    private void generateTrainerList()
    {
        // Get the trainers for the relevent filters. - No change.
        String additionalFilters = '';
        // Generate query filters from the user selected fields
        if (nameCriteria != null && nameCriteria != '')
            additionalFilters += ' and User__r.Name = \'' + nameCriteria + '\'';
            
        if (classCriteria != null && classCriteria.size() > 0)
        {
            String subFilters = '';
            for (String str : classCriteria)
            {
                subFilters += (subFilters.length() > 0 ? ' or ' : '') + 'Class__c = \'' + str + '\'';
            }
            additionalFilters += ' and (' + subFilters + ')';
        }
        if (qualificationsCriteria != null && qualificationsCriteria.size() > 0)
        {
            String subFilters = '';
            for (String str : qualificationsCriteria)
            {
                // brm - 28 July 2010 - used includes instead of = and used brackets around string value
                subFilters += (subFilters.length() > 0 ? ' or ' : '') + 'User__r.Qualifications__c includes (\'' + str + '\')';
            }
            additionalFilters += ' and (' + subFilters + ')';
        }
        if (industryCriteria != null && industryCriteria.size() > 0)
        {
            String subFilters = '';
            for (String str : industryCriteria)
            {
                // brm - 28 July 2010 - used includes instead of = and used brackets around string value
                subFilters += (subFilters.length() > 0 ? ' or ' : '') + 'User__r.Industry__c includes (\'' + str + '\')';
            }
            additionalFilters += ' and (' + subFilters + ')';
        }
        if (regionCriteria != null && regionCriteria.size() > 0)
        {
            String subFilters = '';
            for (String str : regionCriteria)
            {
                subFilters += (subFilters.length() > 0 ? ' or ' : '') + 'User__r.Region__c = \'' + str + '\'';
            }
            additionalFilters += ' and (' + subFilters + ')';
        }
        if (internationalCheckbox == true)
            additionalFilters += ' and User__r.International_Trainer__c = true';
        
        trainerResults = new List<Trainer>();
        try
        {
            // Search for trainers
            // Case 00001321 - Added Order by on Trainer name
            List<Trainer__c> possibleTrainers = database.query(
                'Select Id, Class__c, User__c, User__r.Name, User__r.Qualifications__c, ' + 
                'User__r.Industry__c, User__r.Region__c, User__r.International_Trainer__c, ' + 
                'User__r.Postalcode, Day_Rate__c, Product__r.Trainer_Day_Rate__c From Trainer__c' +
                ' Where Active__c = true and Product__c = \'' + record.Product__c + '\'' + additionalFilters +
                ' Order By user__r.name');
            
            // Add found trainers to results list
            for (Trainer__c trainer : possibleTrainers)
            {
                trainerResults.add(new Trainer(trainer));
            }
        }
        catch (Exception e)
        {
            
        }
    }
    
    // Generate trainer calendars from button - no longer needed.
    public void generateTrainerCalendarAction()
    {
        generateTrainerCalendars2(true);
    }
    
    // Get all Event Units associated with this BSC Event
    public void GenerateAvailableUnits()
    {
        unitResults = new List<Unit>();
        for (Special_Event_Unit__c unit : [
            SELECT
                Id,
                Name,
                Special_Event__r.Name,
                Special_Event__r.Opportunity__r.Account.Name,
                Unit_Start_Time__c,
                Unit_End_Time__c,
                Unit_Description__c,
                Venue__r.Name
            FROM
                Special_Event_Unit__c
            WHERE
                Special_event__c = :record.Id])
        {
            unitResults.add(new Unit(unit));
        }       
        
    }
    
    public Boolean generateTrainerCalendars2( Boolean refreshList)
    {
        DateTime unitsStartTime,
            unitsEndTime;
        Set<Id> trainerUserIds;
        // Get all selected trainer ids - from Page 2
        //if (refreshList)
        //{
            trainerUserIds = new Set<Id>();
        
            for (Trainer trainer : trainerResults)
            {
                if (trainer.selected)
                {
                    trainerUserIds.add(trainer.record.User__c);
                }
            }
            
            // Make sure at least one trainer has been selected
            if (trainerUserIds.size() == 0)
            {
                // Should never get here
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, NO_TRAINER_SELECTED));
                return false;
            }
            
            Set<Id> selectedUnitIds = new Set<Id>();
            for (Unit unit : unitResults)
            {
                if (unit.selected)
                    selectedUnitIds.add(unit.record.Id);
            }
            
            if (refreshList)
            {
            selectedUnits = new List<Special_Event_Unit__c>([
                SELECT
                    Id,
                    Unit_Start_Time__c,
                    Unit_End_Time__c
                FROM
                    Special_Event_Unit__c
                WHERE
                    Id IN : selectedUnitIds
                ORDER BY Unit_Start_Time__c]);
        }
        for (Special_Event_Unit__c unit : selectedUnits)
        {
            if (unitsStartTime == null || (unit.Unit_Start_Time__c != null && unitsStartTime > unit.Unit_Start_Time__c))
                unitsStartTime = unit.Unit_Start_Time__c;
            if (unitsEndTime == null || (unit.Unit_End_Time__c != null && unitsEndTime < unit.Unit_End_Time__c))
                unitsEndTime = unit.Unit_End_Time__c;
        }
        
        
        // If the start date search filter is null, set it to the event start date
        if (unitsStartTime == null)
            unitsStartTime = DateTime.now();
        if (unitsEndTime == null)
            unitsEndTime = unitsStartTime.addDays(1);
        
        dt1 = unitsStartTime;
        dt2 = unitsEndTime;
        
            
        // Work out the number of days between event start date and event end date so if the start date changes we 
        // know how many days the event requires. This is number of days for the Event, not the number of days the
        // Calendar displays.
        Integer numDays = record.StartDate__c.daysBetween(record.EndDate__c);
        
        // Generate a list of events for every selected trainer, the map will contain the ID (Key) of the selected
        // trainers, and events for those selected trainers (List<Event>).
        Map<Id, List<Event>> generatedEvents = generateEventList(trainerUserIds, unitsStartTime.date(), unitsEndTime.date());
            
            
        // brm - 4 August 2010 - get linked bsc event trainers from salesforce events
        Map<Id, Special_Event_Trainer__c> linkedBSCEventTrainers = generateBSCEvents(generatedEvents);
        
        trainerCalendars = new List<Trainer>();
        for (Trainer trainer : trainerResults)
        {
            if (trainer.selected)
            {
                Trainer calendar = new Trainer(trainer.record);
                
                // Generate a calendar from this trainer record
                createCalendar2(calendar, trainer.record.User__c, generatedEvents.get(trainer.record.User__c),
                    linkedBSCEventTrainers, unitsStartTime, unitsEndTime, selectedUnits);
                
                trainerCalendars.add(calendar);
            }
        }
        
        return true;
    }
    
    private void createCalendar2(Trainer trainer, Id trainerUserId, List<Event> possibleEvents,
        Map<Id, Special_Event_Trainer__c> bscEventTrainers, DateTime startDate, DateTime endDate, List<Special_Event_Unit__c> units)
    {
        /* Used for testing overlapping events
        List<Event> testEvents = new List<Event>();
        testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        //testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        //testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        insert testEvents;
        //*/
        List<Day> calendar = new List<Day>();
        List<CalendarEvent> events = new List<CalendarEvent>();
        
        Set<Id> eventsAlreadyAdded = new Set<Id>();
        Integer count = 0;
        Map<Date, Day> dateMap = new Map<Date, Day>();

        for (Date dateLoop = startDate.addDays(-7).date(); dateLoop <= endDate.addDays(7).date(); dateLoop = dateLoop.addDays(1))
        {
            Day d = null;
            for (Special_Event_Unit__c unit : units)
            {
                // Assume no unit end time equals 1 day.
                if (unit.Unit_End_Time__c == null)
                    unit.Unit_End_Time__c = unit.Unit_Start_Time__c.addDays(1);
                
                // Create a new Day'
                d = new Day(dateLoop, (dateLoop >= unit.Unit_Start_Time__c.date() && dateLoop <= unit.Unit_End_Time__c.date()));
                
                if (dateMap.containsKey(dateLoop))
                {
                    // We have already created this date, so modify it instead of
                    // creating anoyher date.
                    Day day = dateMap.get(dateLoop);
                    if (d.coversNewEvent)
                    {
                        // This date covers an event.
                        if (day.coversNewEvent)
                        {
                            // The old date also covers an event, therefore
                            // it is a multiple event.
                            day.isMultipleEvent = true;
                            // Add this unit, there can be many event units per day.
                            day.eventUnits.add(unit);
                        }
                        // Modify this day to say it covers the event. 
                        day.coversNewEvent = true;
                        day.eventUnits.add(unit);
                     
                    }
            
                }
                else
                {
                    d.eventUnits.add(unit);
                    datemap.put(dateLoop, d);
                    calendar.add(d);
                }
            }
                            
            // If this trainer has events
            if (possibleEvents != null)
            {
                
                /* Used for testing overlapping events
                possibleEvents.addAll(testEvents);
                //*/
                // Loop through all events
                for (Event e : possibleEvents)
                {
                    // If the event hasn't been added to calendar and current day is between the start and end dates
                    if (!eventsAlreadyAdded.contains(e.Id) && dateLoop >= e.StartDateTime.date() && dateLoop <= e.EndDateTime.date())
                    {
                        // Add to map of already added events so it isn't added more than once
                        eventsAlreadyAdded.add(e.Id);
                        
                        // Generate calendar event label
                        
                        String subj = '';
                        // brm - 4 August 2010 - Changed event label
                        if (bscEventTrainers.containsKey(e.WhatId))
                        {
                            Special_Event__c bscEv = bscEventTrainers.get(e.WhatId).BSC_Event__r;
                            if (bscEv.Name != null && bscEv.Name != '')
                                subj += (subj.length() > 0 ? ' - ' : '') + bscEv.Name;
                                
                            if (bscEv.Venue__r.Name != null && bscEv.Venue__r.Name != '')
                                subj += (subj.length() > 0 ? ' - ' : '') + bscEv.Venue__r.Name;
                                
                            if (bscEv.Venue__r.Principle_Address_City__c != null && bscEv.Venue__r.Principle_Address_City__c != '')
                                subj += (subj.length() > 0 ? ' - ' : '') + bscEv.Venue__r.Principle_Address_City__c;
                                
                            if (bscEv.Stage__c != null && bscEv.Stage__c != '')
                                subj += (subj.length() > 0 ? ' - ' : '') + bscEv.Stage__c;
                        }
                        else
                        {
                            // brm - 4 August 2010 - If an event trainer has not been found for this event, use subject
                            subj = e.Subject;
                        }
                        
                        /* brm - 4 August 2010 - old event label
                        String subj = e.Subject;
                        if (e.Event_Trainer_Status__c != null) subj += ' - ' + e.Event_Trainer_Status__c;
                        if (e.Event_Account_Name__c != null) subj += ' - ' + e.Event_Account_Name__c;
                        if (e.Event_Postcode__c != null) subj += ' - ' + e.Event_Postcode__c;
                        if (e.Event_Stage__c != null) subj += ' - ' + e.Event_Stage__c;
                        */
                        
                       // CalendarEvent cal = new CalendarEvent(subj, count, 0, dateLoop.daysBetween(e.EndDateTime.date()) + 1, e.ShowAs);
                       // events.add(cal);
                        // If the event goes over the current end date....
                        // No need or this, since the span now covers 7 days after the event.
                        if (e.EndDateTime > endDate.addDays(7))
                        {
                            // Calculate number of days between current day and calendar end date
                            //CalendarEvent cal = new CalendarEvent(subj, count, 0, dateLoop.daysBetween(endDate.date()) + 1, e.ShowAs);
                            CalendarEvent cal = new CalendarEvent(subj, count, 0, dateLoop.daysBetween(endDate.date().addDays(7)) + 1, e.ShowAs, e.Id);
                            events.add(cal);
                        }
                        // If the event is within the current end date
                        else
                        {
                            // Calculate number of days between current day and event end date
                            CalendarEvent cal = new CalendarEvent(subj, count, 0, dateLoop.daysBetween(e.EndDateTime.date()) + 1, e.ShowAs, e.Id);
                            events.add(cal);
                        }
                    }
                }               
            }
            count++;
        }
        
        // Trying to avoid overlapping events
        Map<Integer, Integer> dayOffsetCount = new Map<Integer, Integer>();
        // Loop through all events added to this calendar
        for (CalendarEvent ce : events)
        {
            Integer eventOrder = -1;
            // Loop through all calendar event days
            for (Integer x = ce.dayOffset; x < (ce.dayOffset + ce.numDays); x++)
            {
                // Check all days to see if a current event already has this order
                if (dayOffsetCount.containsKey(x))
                {
                    // If this day already has events, change current event order to this day's current order
                    if (dayOffsetCount.get(x) > eventOrder)
                        eventOrder = dayOffsetCount.get(x);
                }
            }
            // Increment event order by 1 and add to this event
            ce.eventOrder = eventOrder+1;
            // Loop through all calendar event days
            for (Integer x = ce.dayOffset; x < (ce.dayOffset + ce.numDays); x++)
            {
                // Add current event count to curent day's event count
                dayOffsetCount.put(x, ce.eventOrder);
            }
        }
        trainer.addCalendar(calendar);
        trainer.addEvents(events);
        /* Used for testing overlapping events
        delete testEvents;
        //*/
    }
    

    
    
    /*
     *  Params:
     *  userIds - Trainers selected during wizard Page 2
     *  startDate - Start date filter, or if null, Special Event start date.
     *  endDate - End date filter, or if null, Special Event end date.
     *
     *  Returns:
     *  Map of Trainer (User) Ids, and list of Events for that Trainer (User).
     */
    
    private Map<Id, List<Event>> generateEventList(Set<Id> userIds, Date startDate, Date endDate)
    {
        Map<Id, List<Event>> events = new Map<Id, List<Event>>();
        // START DEBUGGING
        //System.debug('************************************\n\n START DATE : ' + startDate + ' \nEND DATE : ' + endDate + '\n\n****************************');
        // END DEBUGGING
        
        // Loop through all events that fall into the calendar days range
        // for the selected Trainers
        for (Event e : [
            SELECT
                Id,
                OwnerId,
                StartDateTime,
                EndDateTime,
                Subject,
                Event_Trainer_Status__c, 
                Event_Account_Name__c,
                Event_Postcode__c,
                Event_Stage__c,
                ShowAs,
                WhatId
             FROM
                Event 
            WHERE
                OwnerId in :userIds
            AND 
                // brm - 4 August 2010 - changed so that event selection is based upon start 
                // event dates instead of start and end
                StartDateTime >= :startDate.addDays(-7) and StartDateTime <= :endDate.addDays(7)
            ORDER BY
                DurationInMinutes DESC, StartDateTime ASC])
        {
            // Create a map of TrainerId (User) -> List of Events
            // If the events list doesn't contain this event, add it,
            // otherwise, just add the Event to the relevent List
            // denoted by the owner of the event.
            if (!events.containsKey(e.OwnerId))
                events.put(e.OwnerId, new List<Event>());
            
            events.get(e.OwnerId).add(e);
        }
        
        return events;
    }
    
    

    
    /*
     *  Params:
     *  Map of Trainer (User) IDs / List of Events
     *
     *  Returns:
     *  Map of Special Event Trainers Ids and Special Event Trainers items.
     *
     */ 
    // brm - 4 August 2010 - get out a list of bsc event trainers linked to these salesforce events
    private Map<Id, Special_Event_Trainer__c> generateBSCEvents(Map<Id, List<Event>> sfEvents)
    {
        Set<Id> eventTrainerIds = new Set<Id>();
        
        // Loop through each List
        for (List<Event> eventList : sfEvents.values())
        {
            // Loop through each Event in the list.
            for (Event e : eventList)
            {
                // Add the 'WhatId' (reference to Special_Event_Trainer__c) to the eventTrainerIds list
                eventTrainerIds.add(e.WhatId);
            }
        }
        
        // Select out various components related to the Trainer from the Events list.
        Map<Id, Special_Event_Trainer__c> bscEventTrainerRecords = new Map<Id, Special_Event_Trainer__c>();
        for (Special_Event_Trainer__c bscEventTrainer : [
            SELECT
                Id,
                BSC_Event__r.Name,
                BSC_Event__r.Venue__r.Name,
                BSC_Event__r.Venue__r.Principle_Address_City__c,
                BSC_Event__r.Stage__c
            FROM
                Special_Event_Trainer__c
            WHERE
                Id IN :eventTrainerIds])
        {
            bscEventTrainerRecords.put(bscEventTrainer.Id, bscEventTrainer);
        }
        
        return bscEventTrainerRecords;
    }
    
    public PageReference MoveCalendarEvent()
    {
        String[] dates = ajaxStartDate.split(',');
        Integer year = Integer.valueOf(dates[0]);
        Integer month = Integer.valueOf(dates[1]);
        Integer day = Integer.valueOf(dates[2]);
        Date dt = Date.newInstance(year, month, day);
        Integer dayShift = dt1.date().daysBetween(dt);
        test = String.valueOf(dayShift);
        
        for (Special_Event_Unit__c unit : selectedUnits)
        {
            unit.Unit_Start_Time__c = unit.Unit_Start_Time__c.addDays(dayShift);
            unit.Unit_End_Time__c = unit.Unit_End_Time__c.addDays(dayShift);
        }
        generateTrainerCalendars2(false);

        return null;    
    }
    
    
    

    
    public PageReference Save()
    {
        //List<Special_Event_Trainer__c> trainerEventLinks = new List<Special_Event_Trainer__c>();
        Map<Special_Event_Unit__c, Special_Event_Trainer__c> trainerUnitMap = new Map<Special_Event_Unit__c, Special_Event_Trainer__c>();
        // Loop through all trainer calendars
        for (Trainer trainer : trainerCalendars)
        {
            if (trainer.selected)
            {
                for (Day day : trainer.calendarDays)
                {
                    if (day.coversNewEvent)
                    {
                        // May be more than one unit applied to this day.
                        for (Special_Event_Unit__c unit : day.eventUnits)
                        {
                            Special_Event_Trainer__c link = new Special_Event_Trainer__c(
                            BSC_Event__c = record.Id,
                            BSC_Event_Unit__c = unit.Id,
                            Trainer__c = trainer.record.Id,
                            Status__c = 'Provisional',
                            Type__c = 'Active Trainer',
                            Non_Standard_Trainer_Fee__c = false);
                            //trainerEventLinks.add(link);
                            trainerUnitMap.put(unit, link);
                        }
                    }
                }
            }
        }
        if (trainerUnitMap.values().size() == 0)
        {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, NO_TRAINER_CALENDAR_SELECTED));
            return null;
        }
        
        // Make sure at least one trainer calendar has been selected
/*        if (trainerEventLinks.size() == 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, NO_TRAINER_CALENDAR_SELECTED));
            return null;
        }
       
        
        // If the start date input is not the same as the event start date
        if (startDateSearch.StartDate__c != record.StartDate__c)
        {
            // Work out number of days between current event start and current event end
            Integer duration = record.StartDate__c.daysBetween(record.EndDate__c);
            // Assign start date input to event start
            record.StartDate__c = startDateSearch.StartDate__c;
            // Calculate end date from start date and calculated duration
            record.EndDate__c = startDateSearch.StartDate__c.addDays(duration);
            update record;
        }*/
        
        try
        {
            List<Special_Event_Unit__c> unitList = new List<Special_Event_Unit__c>();
            insert trainerUnitMap.values();
            for (Special_Event_Unit__c unit : trainerUnitMap.keySet())
            {
                unit.BSC_Event_Trainer__c = trainerUnitMap.get(unit).Id;
                unitList.add(unit);
            }
            update unitList;
            //insert trainerEventLinks;
        }
        catch (Exception e)
        {
            return null;
        }
        
        return new PageReference('/' + record.Id);
    }
    
   
    
    public class Unit
    {
        
        public Special_Event_Unit__c record         { get; private set; }
        public Boolean selected                     { get; set; }
        
        public Unit(Special_Event_Unit__c unit)
        {
            this.record = unit;
            this.selected = false;
        }
    }
    
    public class Trainer
    {
        public Trainer__c record                    { get; private set; }
        public Boolean selected                     { get; set; }
        
        public List<Day> calendarDays               { get; private set; }
        public List<CalendarEvent> calendarEvents   { get; private set; }       // Previous events
        
        public Trainer(Trainer__c trainer)
        {
            this.record = trainer;
            selected = false;
        }
        
        public void addCalendar(List<Day> days)
        {
            this.calendarDays = days;
        }
        
        public void addEvents(List<CalendarEvent> evts)
        {
            this.calendarEvents = evts;
        }
    }
    
    public class Day
    {
        public Date currentDate                     { get; private set; }
        public Boolean coversNewEvent               { get; private set; }
        public String DateFormatForJS               { get { return currentDate.year() + ',' + currentDate.month() + ',' + currentDate.day(); }}
        public Boolean isMultipleEvent              { get; private set; }
        public List<Special_Event_Unit__c> eventUnits; 
        
        public Day(Date current, Boolean dayCoversNewEvent)
        {
            eventUnits = new List<Special_Event_Unit__c>();
            this.currentDate = current;
            this.coversNewEvent = dayCoversNewEvent;
            this.isMultipleEvent = false;
        }
    }
    
    public class CalendarEvent
    {
        public String subject                       { get; private set; }
        
        // Which day this event starts on the calendar
        public Integer dayOffset                    { get; private set; }
        // The order of events in the spanning days - used to avoid overlap
        public Integer eventOrder                   { get; private set; }
        // Number of days this event spans
        public Integer numDays                      { get; private set; }
        
        public String timeAs                        { get; set;         }
        public Id id                                { get; private set; }
        
        
        public CalendarEvent(String subject, Integer day, Integer order, Integer numberOfDays, String showTimeAs, Id id)
        {
            this.subject = subject;
            this.dayOffset = day;
            this.eventOrder = order;
            this.numDays = numberOfDays;
            this.id = id;
            
            this.timeAs = (showTimeAs == 'OutofOffice' ? 'outOfOfficeEvent' : (showTimeAs == 'Busy' ? 'busyEvent' : ''));
        }
    }
    
    @IsTest
    private static void test()
    {
        Product2 product = new Product2(
            Name = 'Test Product');
        insert product;
        
        Special_Event__c event = new Special_Event__c(
            Product__c = product.Id,
            StartDate__c = System.today().addDays(7),
            EndDate__c = Date.today().addDays(12));
        insert event;
        
        Trainer__c trainer = new Trainer__c(
            Product__c = product.Id,
            Active__c = true,
            User__c = UserInfo.getUserId());
        insert trainer;
        
        Special_Event_Unit__c eventUnit = new Special_Event_Unit__c(
            Name = 'Test Event Unit 1',
            Special_Event__c = event.Id,
            Unit_Start_Time__c = DateTime.now(),
            Unit_End_Time__c = DateTime.now().addDays(1));
        insert eventUnit;
        
        // Overlapping event
        eventUnit = new Special_Event_Unit__c(
            Name = 'Test Event Unit 2',
            Special_Event__c = event.Id,
            Unit_Start_Time__c = DateTime.now(),
            Unit_End_Time__c = DateTime.now().addDays(1));
        insert eventUnit;
        
        eventUnit = new Special_Event_Unit__c(
            Name = 'Test Event Unit 3',
            Special_Event__c = event.Id,
            Unit_Start_Time__c = DateTime.now());
        insert eventUnit;
        
        Event SFevent = new Event(
            BSC_Event_Trainer__c = trainer.Id,
            RecordTypeId = [
                SELECT
                    Id
                FROM
                    RecordType
                WHERE
                    SObjectType = 'Event'
                AND
                    Name = 'Trainer Booking' Limit 1].get(0).Id,
            Subject = 'Test Subject',
            IsAllDayEvent = true,
            StartDateTime = eventUnit.Unit_Start_Time__c,
            EndDateTime = eventUnit.Unit_End_Time__c,
            ShowAs = 'Busy',
            Event_Stage__c = event.Stage__c,
            OwnerId = trainer.User__c,
            IsPrivate = false);
        
        insert SFevent;
        
        Apexpages.Standardcontroller stdController = new Apexpages.Standardcontroller(eventUnit);
        ScheduleEventTrainerController controller = new ScheduleEventTrainerController(stdController);
        
        stdController = new Apexpages.Standardcontroller(event);
        controller = new ScheduleEventTrainerController(stdController);
        
        List<SelectOption> classes = controller.getClassPicklistOptions();
        List<SelectOption> qualifications = controller.getQualificationsPicklistOptions();
        List<SelectOption> industries = controller.getIndustryPicklistOptions();
        List<SelectOption> regions = controller.getRegionPicklistOptions();
        
        controller.nameCriteria = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        controller.classCriteria.add(classes[0].getValue());
        controller.qualificationsCriteria.add(qualifications[0].getValue());
        controller.industryCriteria.add(industries[0].getValue());
        controller.regionCriteria.add(regions[0].getValue());
        controller.internationalCheckbox = true;
        
        controller.next();
        controller.prev();
        controller.nameCriteria = '\'\'';
        controller.next();
        controller.prev();
        
        controller.nameCriteria = '';
        controller.classCriteria.clear();
        controller.qualificationsCriteria.clear();
        controller.industryCriteria.clear();
        controller.regionCriteria.clear();
        controller.internationalCheckbox = false;
        
        controller.next();
        
        
        // Page 2
        
        // Attempt to go to next page without selecting trainers
        controller.next();
        List<Apexpages.Message> errorMessages = ApexPages.getMessages();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(NO_TRAINER_SELECTED, errorMessages.get(0).getSummary());
        
        // Select trainer
        for (Trainer tr : controller.trainerResults)
        {
            if (tr.record.Id == trainer.Id)
                tr.selected = true;
        }        
        controller.next();
        // Page 3
        controller.prev();
        // Page 2
        controller.next();
        // Page 3
        
        // Attempt to go to next page without selecting trainers
        //ApexPages.getMessages().clear();
        controller.next();        
        errorMessages = ApexPages.getMessages();
        System.assertEquals(2, errorMessages.size());
        //System.assertEquals(NO_UNIT_SELECTED, errorMessages.get(0).getSummary());
        
        for (Unit unit : controller.unitResults)
        {
            if (unit.record.Id == eventUnit.Id)
                unit.selected = true;
        }
        
        controller.next();
        
        // Select trainer calendar
        for (Trainer tr : controller.trainerCalendars)
        {
            if (tr.record.Id == trainer.Id)
                tr.selected = true;
        }
        
        // Check there are no event trainer records before save
        List<Special_Event_Trainer__c> eventTrainerRecords = [
            SELECT
                Id
            FROM
                Special_Event_Trainer__c 
            WHERE
                Trainer__c = :trainer.Id
            AND
                BSC_Event__c = :event.Id];
                                        
        System.assertEquals(0, eventTrainerRecords.size());
        
        controller.save();
        
        // Check that an event trainer has been created after save
        eventTrainerRecords = [
            SELECT
                Id
            FROM
                Special_Event_Trainer__c
            WHERE
                Trainer__c = :trainer.Id
            AND
                BSC_Event__c = :event.Id];
                                        
        System.assertEquals(1, eventTrainerRecords.size());
        
        //controller.trainerResults.clear();        
        controller.generateTrainerCalendarAction();
    }
}

////// DEPRECATED 05-10-10///////////////
/*    public Boolean generateTrainerCalendars()
    {
        Set<Id> trainerUserIds = new Set<Id>();
        // Get all selected trainer ids - from Page 2
        for (Trainer trainer : trainerResults)
        {
            if (trainer.selected)
            {
                trainerUserIds.add(trainer.record.User__c);
            }
        }
        
        // Make sure at least one trainer has been selected
        if (trainerUserIds.size() == 0)
        {
            // Should never get here
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, NO_TRAINER_SELECTED));
            return false;
        }
        
        Set<Id> selectedUnitIds = new Set<Id>();
        for (Unit unit : unitResults)
        {
            if (unit.selected)
                selectedUnitIds.add(unit.record.Id);
        }       
        
        // If the start date search filter is null, set it to the event start date
        if (startDateSearch.StartDate__c == null)
            startDateSearch.StartDate__c = record.StartDate__c;
        
            
        // Work out the number of days between event start date and event end date so if the start date changes we 
        // know how many days the event requires. This is number of days for the Event, not the number of days the
        // Calendar displays.
        Integer numDays = record.StartDate__c.daysBetween(record.EndDate__c);
        
        
        dt1 = startDateSearch.StartDate__c;
        dt2 = startDateSearch.StartDate__c.addDays(numDays);
        
        // Generate a list of events for every selected trainer, the map will contain the ID (Key) of the selected
        // trainers, and events for those selected trainers (List<Event>).
        Map<Id, List<Event>> generatedEvents = generateEventList(trainerUserIds, startDateSearch.StartDate__c,
            startDateSearch.StartDate__c.addDays(numDays));
            
            
        // brm - 4 August 2010 - get linked bsc event trainers from salesforce events
        Map<Id, Special_Event_Trainer__c> linkedBSCEventTrainers = generateBSCEvents(generatedEvents);
        
        trainerCalendars = new List<Trainer>();
        for (Trainer trainer : trainerResults)
        {
            if (trainer.selected)
            {
                Trainer calendar = new Trainer(trainer.record);
                
                // Generate a calendar from this trainer record
                //createCalendar(calendar, trainer.record.User__c, generatedEvents.get(trainer.record.User__c),
                //  linkedBSCEventTrainers, startDateSearch.StartDate__c, startDateSearch.StartDate__c.addDays(numDays));
                createCalendar(calendar, trainer.record.User__c, generatedEvents.get(trainer.record.User__c),
                    linkedBSCEventTrainers, startDateSearch.StartDate__c, startDateSearch.StartDate__c.addDays(numDays));
                
                trainerCalendars.add(calendar);
            }
        }
        
        return true;
    }*/
    
    
/*    private Map<Id, List<Event>> generateEventList2(Set<Id> userIds, DateTime startDT, DateTime endDT)
    {
        Map<Id, List<Event>> events = new Map<Id, List<Event>>();
        
        // Loop through all the events taht fall into the calendar days range
        // for the selected users.
        
        for (Event e : [
            SELECT
                Id,
                OwnerId,
                StartDateTime,
                EndDateTime,
                Subject,
                Event_Trainer_Status__c, 
                Event_Account_Name__c,
                Event_Postcode__c,
                Event_Stage__c,
                ShowAs,
                WhatId
             FROM
                Event 
            WHERE
                OwnerId in :userIds
            AND 
                // brm - 4 August 2010 - changed so that event selection is based upon start 
                // event dates instead of start and end
                StartDateTime >= :startDT.addDays(-7) and StartDateTime <= :endDT.addDays(7)
            ORDER BY
                DurationInMinutes DESC, StartDateTime ASC])
        {
            // Create a map of TrainerId (User) -> List of Events
            // If the events list doesn't contain this event, add it,
            // otherwise, just add the Event to the relevent List
            // denoted by the owner of the event.
            if (!events.containsKey(e.OwnerId))
                events.put(e.OwnerId, new List<Event>());           
            events.get(e.OwnerId).add(e);
        }
        
        return events;
    }*/
        /*
     * Params:
     * trainer - Trainer for whom the calendar is for.
     * trainerUserId - Id of the Trainer->User
     * possibleEvents - SF Events for the Trainer
     * bscEventTrainers - Special_Event_Trainer__c objects for this Trainer
     * startDate - Search Start Date
     * endDate - Search End Date
     */
    
    // Create a calendar from a specific trainer
/*    private void createCalendar(Trainer trainer, Id trainerUserId, List<Event> possibleEvents,
        Map<Id, Special_Event_Trainer__c> bscEventTrainers, Date startDate, Date endDate)
    {
        /* Used for testing overlapping events
        // List<Event> testEvents = new List<Event>();
        // testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        // testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        // testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        // testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        // testEvents.add(new Event(Subject = 'Test Subject', StartDateTime = startDate.addDays(-3), EndDateTime = startDate.addDays(-3)));
        // insert testEvents;
        //
        
        List<Day> calendar = new List<Day>();
        List<CalendarEvent> events = new List<CalendarEvent>();
        
        Set<Id> eventsAlreadyAdded = new Set<Id>();
        Integer count = 0;
        // Need to loop through all event units for this event.
        
        // Loop through all days in calendar
        //
        //  AB - Increased the calendar reange to 7 days after the end of the event.
        //
        ///
        for (Date x = startDate.addDays(-7); x <= endDate.addDays(7); x = x.addDays(1))
        {
            // Create new day, param2 defines if this day is part of the event.
            Day d = new Day(x, (x >= startDate && x <= endDate));
            
            // If this trainer has events
            if (possibleEvents != null)
            {
                // Used for testing overlapping events
                possibleEvents.addAll(testEvents);
                //
                // Loop through all events
                for (Event e : possibleEvents)
                {
                    // If the event hasn't been added to calendar and current day is between the start and end dates
                    if (!eventsAlreadyAdded.contains(e.Id) && x >= e.StartDateTime.date() && x <= e.EndDateTime.date())
                    {
                        // Add to map of already added events so it isn't added more than once
                        eventsAlreadyAdded.add(e.Id);
                        
                        // Generate calendar event label
                        
                        String subj = '';
                        // brm - 4 August 2010 - Changed event label
                        if (bscEventTrainers.containsKey(e.WhatId))
                        {
                            Special_Event__c bscEv = bscEventTrainers.get(e.WhatId).BSC_Event__r;
                            if (bscEv.Name != null && bscEv.Name != '')
                                subj += (subj.length() > 0 ? ' - ' : '') + bscEv.Name;
                                
                            if (bscEv.Venue__r.Name != null && bscEv.Venue__r.Name != '')
                                subj += (subj.length() > 0 ? ' - ' : '') + bscEv.Venue__r.Name;
                                
                            if (bscEv.Venue__r.Principle_Address_City__c != null && bscEv.Venue__r.Principle_Address_City__c != '')
                                subj += (subj.length() > 0 ? ' - ' : '') + bscEv.Venue__r.Principle_Address_City__c;
                                
                            if (bscEv.Stage__c != null && bscEv.Stage__c != '')
                                subj += (subj.length() > 0 ? ' - ' : '') + bscEv.Stage__c;
                        }
                        else
                        {
                            // brm - 4 August 2010 - If an event trainer has not been found for this event, use subject
                            subj = e.Subject;
                        }
                        
                        // brm - 4 August 2010 - old event label
                        //String subj = e.Subject;
                        //if (e.Event_Trainer_Status__c != null) subj += ' - ' + e.Event_Trainer_Status__c;
                        //if (e.Event_Account_Name__c != null) subj += ' - ' + e.Event_Account_Name__c;
                        //if (e.Event_Postcode__c != null) subj += ' - ' + e.Event_Postcode__c;
                        //if (e.Event_Stage__c != null) subj += ' - ' + e.Event_Stage__c;
                        //
                        
                        // If the event goes over the current end date
                       if (e.EndDateTime > endDate)
                        {
                            // Calculate number of days between current day and calendar end date
                            events.add(new CalendarEvent(subj, count, 0, x.daysBetween(endDate) + 1, e.ShowAs));
                        }
                        // If the event is within the current end date
                        else
                        {
                            // Calculate number of days between current day and event end date
                            events.add(new CalendarEvent(subj, count, 0, x.daysBetween(e.EndDateTime.date()) + 1, e.ShowAs));
                        }
                    }
                }
            }
            
            calendar.add(d);
            count++;
        }
        
        // Trying to avoid overlapping events
        Map<Integer, Integer> dayOffsetCount = new Map<Integer, Integer>();
        // Loop through all events added to this calendar
        for (CalendarEvent ce : events)
        {
            Integer eventOrder = -1;
            // Loop through all calendar event days
            for (Integer x = ce.dayOffset; x < (ce.dayOffset + ce.numDays); x++)
            {
                // Check all days to see if a current event already has this order
                if (dayOffsetCount.containsKey(x))
                {
                    // If this day already has events, change current event order to this day's current order
                    if (dayOffsetCount.get(x) > eventOrder)
                        eventOrder = dayOffsetCount.get(x);
                }
            }
            // Increment event order by 1 and add to this event
            ce.eventOrder = eventOrder+1;
            // Loop through all calendar event days
            for (Integer x = ce.dayOffset; x < (ce.dayOffset + ce.numDays); x++)
            {
                // Add current event count to curent day's event count
                dayOffsetCount.put(x, ce.eventOrder);
            }
        }
        
        
        trainer.addCalendar(calendar);
        trainer.addEvents(events);
        
        // Used for testing overlapping events
        //delete testEvents;
        //
    }*/
     /*   private Map<Id, Special_Event_Trainer__c> generateBSCEvents2(Map<Id, List<Event>> events)
    {
        Set<Id> eventTrainerIds = new set<Id>();
        
        for (List<Event> eventList : events.values())
        {
            // Loop through the events in the list
            for (Event event : eventList)
            {
                eventTrainerIds.add(event.WhatId);
            }
        }
        
        // Select out various components related to the Trainer from the Events list.
        Map<Id, Special_Event_Trainer__c> bscEventTrainerRecords = new Map<Id, Special_Event_Trainer__c>();
        for (Special_Event_Trainer__c bscEventTrainer : [
            SELECT
                Id,
                BSC_Event__r.Name,
                BSC_Event__r.Venue__r.Name,
                BSC_Event__r.Venue__r.Principle_Address_City__c,
                BSC_Event__r.Stage__c
            FROM
                Special_Event_Trainer__c
            WHERE
                Id IN :eventTrainerIds])
        {
            bscEventTrainerRecords.put(bscEventTrainer.Id, bscEventTrainer);
        }
        
        return bscEventTrainerRecords;
    }*/
     /*public PageReference save()
    {
        return Save2();
        
        List<Special_Event_Trainer__c> trainerEventLinks = new List<Special_Event_Trainer__c>();
        // Loop through all trainer calendars
        for (Trainer t : trainerCalendars)
        {
            if (t.selected)
            {
                // Create a special event trainer record if this calendar has been selected
                Special_Event_Trainer__c link = new Special_Event_Trainer__c(
                    BSC_Event__c = record.Id,
                    Trainer__c = t.record.Id,
                    Status__c = 'Provisional',
                    Type__c = 'Active Trainer',
                    Non_Standard_Trainer_Fee__c = false);
                trainerEventLinks.add(link);
            }
        }
        // Make sure at least one trainer calendar has been selected
        if (trainerEventLinks.size() == 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, NO_TRAINER_CALENDAR_SELECTED));
            return null;
        }
        
        // If the start date input is not the same as the event start date
        if (startDateSearch.StartDate__c != record.StartDate__c)
        {
            // Work out number of days between current event start and current event end
            Integer duration = record.StartDate__c.daysBetween(record.EndDate__c);
            // Assign start date input to event start
            record.StartDate__c = startDateSearch.StartDate__c;
            // Calculate end date from start date and calculated duration
            record.EndDate__c = startDateSearch.StartDate__c.addDays(duration);
            update record;
        }
        
        try
        {
            insert trainerEventLinks;
        }
        catch (Exception e)
        {
            return null;
        }
        
        return new PageReference('/' + record.Id);
    }*/