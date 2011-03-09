/*
    Created by Ben Mansfield 27 July 2010
    Modified by Ben Mansfield 4 August 2010
    
    Description:
        Note: Cannot set events to private whilst setting the WhatId
                Cannot create an event over 14 days (SF Event limit)
        
    Changes:
    
        4 August 2010
        * Modified so event is linked to event trainer, not event
        
        28 September 2010
        * AB
        * Modified to work with BSC Event Units instead of BSC Events.
        
        
*/
public class EventTrainerHelper
{
    private static final String INVALID_EVENT_LENGTH = 'An Event can be no longer than 14 days.';
    

    public static void createSharingRule(List<Special_Event_Trainer__c> eventTrainerList)
    {
    
        Set<Id> trainerId = new Set<Id>();
        Set<Id> bscEventId = new Set<Id>();
        Set<Id> userId = new Set<Id>();
        Map<Id,Id> trainerMap = new Map<Id,Id>();
        Set<String> eventSharingKey = new Set<String>();
        List<Special_Event__Share> insertSharingRule = new List<Special_Event__Share>();
        
        for(Special_Event_Trainer__c eventTrainer:eventTrainerList)
        {
            //List of trainer ids
            trainerId.add(eventTrainer.Trainer__c);
            //List of event ids
            bscEventId.add(eventTrainer.BSC_Event__c);
        }
        
        for(Trainer__c trainer:[Select Id,User__c from Trainer__c where Id IN:trainerId])
        {
            //Map of trainer records
            trainerMap.put(trainer.Id,trainer.User__c);
            //List of user ids
            userId.add(trainer.User__c);
        
        }
        //Check if there is an existing sharing record against the user
        for(Special_Event__Share eventShare:[Select s.UserOrGroupId, 
                                                    s.ParentId 
                                                    From Special_Event__Share s 
                                                    where s.UserOrGroupId IN:userId
                                                    and s.ParentId IN:bscEventId])
        {
            eventSharingKey.add(eventShare.ParentId+';'+eventShare.UserOrGroupId);
        }
        
        for(Special_Event_Trainer__c eventTrainer:eventTrainerList)
        {
            if(trainerMap.containsKey(eventTrainer.Trainer__c))
            {
            
                Id userTrainerId = trainerMap.get(eventTrainer.Trainer__c);
                if(!eventSharingKey.isEmpty())
                {

                    if(!eventSharingKey.contains(eventTrainer.BSC_Event__c+';'+userTrainerId))
                    {
                        Special_Event__Share sharingRecord = new Special_Event__Share(ParentId =eventTrainer.BSC_Event__c,
                                                                                     UserOrGroupId=userTrainerId,
                                                                                     AccessLevel = 'Read');
                                   
                        insertSharingRule.add(sharingRecord); 
                        
                    }
            
                }else{
                
                    Special_Event__Share sharingRecord = new Special_Event__Share(ParentId =eventTrainer.BSC_Event__c,
                                                                                  UserOrGroupId=userTrainerId,
                                                                                  AccessLevel = 'Read');
                                   
                    insertSharingRule.add(sharingRecord); 
                }    
                
            }
            
        }
        if(!insertSharingRule.isEmpty())
            insert insertSharingRule;
    
    }
    
    
    
    
    public static void generateEvents(List<Special_Event_Trainer__c> newEventTrainerRecords,
        Map<Id, Special_Event_Trainer__c> oldEventTrainerRecords)
    {
        Map<Id, Event> events = new Map<Id, Event>();
        
        // If this is executing in an insert trigger
        if (!Trigger.isInsert)
        { 
            // If events already exist for the event trainer records, get them
            for (Event e : [
                SELECT
                    Id,
                    BSC_Event_Trainer__c
                FROM
                    Event
                WHERE
                    BSC_Event_Trainer__c IN :oldEventTrainerRecords.keySet()])
            {
                events.put(e.BSC_Event_Trainer__c, e);
            }
        }
        
        // If this is executing in a delete trigger, delete the associated Events
        if (Trigger.isDelete)
            delete events.values();
        else
        {
            // Update / Insert records.
            
            // Get trainer booking record type.
            List<RecordType> trainerBookingRecordType = [
                SELECT
                    Id
                FROM
                    RecordType
                WHERE
                    SObjectType = 'Event'
                AND
                    Name = 'Trainer Booking' Limit 1];
            
            
            Set<Id> eventTrainerIds = new Set<Id>();
            Set<Id> trainerIds = new Set<Id>();
            Set<Id> unitIds = new Set<Id>();
            
            // Get a list of Event Trainer ids being Updated / Inserted
            for (Special_Event_Trainer__c et : newEventTrainerRecords)
            {
                eventTrainerIds.add(et.Id);
                trainerIds.add(et.Trainer__c);
                unitIds.add(et.BSC_Event_Unit__c);
            }
            Map<Id,Special_Event_Trainer__c> currentEventTrainer = new Map<Id,Special_Event_Trainer__c>([Select Id,
            																   									BSC_Event__r.Venue__r.Principle_Address_Zip_Postal_Code__c,
            																   									BSC_Event__r.Opportunity__r.Account.Name
            																   									from Special_Event_Trainer__c
            																   									where Id IN:eventTrainerIds	]);
            // Get trainers
            Map<Id, Trainer__c> trainers = new Map<Id, Trainer__c>([
                SELECT
                    Id,
                    User__c
                FROM
                    Trainer__c
                WHERE
                    Id in :trainerIds]);
                    
            // Get BSC Event Units for this BSC Event Trainer.
            List<Special_Event_Unit__c> trainerUnits = new List<Special_Event_Unit__c>([
                SELECT
                    Id,
                    Duration__c,
                    Unit_Start_Time__c,
                    Unit_End_Time__c,
                    Special_Event__c,
                    Special_Event__r.Name,
                    Special_Event__r.Stage__c,
                    BSC_Event_Trainer__c
                FROM
                    Special_Event_Unit__c
                WHERE
                    Id IN :unitIds
                ORDER BY
                    Special_Event__c]);
            

            // Trainers can have multiple BSC Event Units, so get all Event Units for these Trainers.
//          List<Special_Event_Unit__c> trainerUnits = new List<Special_Event_Unit__c>([
//              SELECT
//                  Id,
//                  Duration__c,
//                  Unit_Start_Time__c,
//                  Unit_End_Time__c,
//                  Special_Event__c,
//                  Special_Event__r.Stage__c,
//                  BSC_Event_Trainer__c
//              FROM
//                  Special_Event_Unit__c
//              WHERE
//                  BSC_Event_Trainer__c IN :eventTrainerIds
//              ORDER BY
//                  Special_Event__c]);
    
            // Create a trainer list, so we can calculate the total time for the event
            // from the Unit Start Time and Duration - if the trainer has no units, the list will not contain him.          
            
            
            // Can't do this, trainer units do not contain a reference to the Special_Event_Trainer__c until after this method has returned.
            List<TrainerUnitsEx> trainerUnitsEx = new List<TrainerUnitsEx>();
            for (Special_Event_Trainer__c et : newEventTrainerRecords)
            {
                trainerUnitsEx.add(new TrainerUnitsEx(et, trainerUnits));
            }
            
            System.debug('*****************************\n\n TRAINERUNITS SIZE: ' + trainerUnitsEx.size() + '\n\n***********************************');
            
            for (TrainerUnitsEx trainerUnitEx : TrainerUnitsEx)
            {
                if (events.containsKey(trainerUnitEx.trainer.Id))
                {
                    trainerUnitEx.UpdateEventForEventUnit(
                        trainerBookingRecordType.get(0).Id, trainers, events.get(trainerUnitEx.trainer.Id));
                }
                else
                {
                    Event event = trainerUnitEx.CreateEventForEventUnit(trainerBookingRecordType.get(0).Id, trainers);
                    if (event != null)
                    {
                        if(currentEventTrainer.containsKey(event.WhatId))
                		{	
                			event.Event_Postcode__c = currentEventTrainer.get(event.WhatId).BSC_Event__r.Venue__r.Principle_Address_Zip_Postal_Code__c;
                			event.Event_Account_Name__c = currentEventTrainer.get(event.WhatId).BSC_Event__r.Opportunity__r.Account.Name;
                		}	
                        
                        events.put(trainerUnitEx.trainer.Id, event);
                    }
                }
            }
            system.debug('EventList'+events.values());
            upsert events.values();
            System.debug('****************************************\n\nEVENTS TO UPDATE: ' + events.size() + '\n\n******************************');
        }
    }
    
    public class TrainerUnitsEx
    {
        private Special_Event_Trainer__c trainer;
        private Special_Event_Unit__c unit;
        
        
        public TrainerUnitsEx(Special_Event_Trainer__c trainer, List<Special_Event_Unit__c> units)
        {
            this.trainer = trainer;
            for (Special_Event_Unit__c unit : units)
            {
                if (trainer.BSC_Event_Unit__c == unit.Id)
                {
                    this.unit = unit;
                    return;
                }
//              if (unit.BSC_Event_Trainer__c == trainer.Id)
//              {
//                  this.unit = unit;
//                  return;
//              }           
            }           
        }
        
        public Event CreateEventForEventUnit(Id recordTypeId, Map<Id, Trainer__c> trainers)
        {
            if (this.unit != null)
            {
                Event event = new Event();
                return UpdateEventForEventUnit(recordTypeId, trainers, event);
            }
            return null;
        }
        
        public Event UpdateEventForEventUnit(Id recordTypeId, Map<Id, Trainer__c> trainers, Event event)
        {
            if (this.unit != null)
            {
                event.BSC_Event_Trainer__c = this.trainer.Id;
                event.RecordTypeId = recordTypeId;
                /*event.Subject = this.unit.Special_Event__r.Name + ' - ' +
                    this.trainer.BSC_Event__r.Stage__c + ' - ' +
                    this.trainer.Status__c + ' - ' +
                    this.trainer.BSC_Event__r.Venue__r.Principle_Address_Country__c;*/
                event.Subject = this.unit.Special_Event__r.Name;    
                event.IsAllDayEvent = true;
                event.StartDateTime = this.unit.Unit_Start_Time__c;
                event.EndDateTime = this.unit.Unit_End_Time__c;
                event.ShowAs = 'Busy';
                event.Event_Trainer_Status__c = this.trainer.Status__c;
                event.Event_Stage__c = this.unit.Special_Event__r.Stage__c;
                event.OwnerId = trainers.get(this.trainer.trainer__c).User__c;
                event.WhatId = this.trainer.Id;
                event.IsPrivate = false;
                
            }
            return event;
        }
    }
}