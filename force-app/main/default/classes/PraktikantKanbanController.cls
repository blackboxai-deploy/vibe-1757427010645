/**
 * Apex controller for Praktikant Kanban Lightning Web Component
 * Handles data retrieval and status updates for Stundenerfassung_Praktikant__c records
 */
public with sharing class PraktikantKanbanController {
    
    /**
     * Retrieves all Praktikant records with required fields
     * @return List<Stundenerfassung_Praktikant__c> List of praktikant records
     */
    @AuraEnabled(cacheable=true)
    public static List<Stundenerfassung_Praktikant__c> getPraktikantRecords() {
        try {
            // Check field-level security before querying
            if (!Schema.sObjectType.Stundenerfassung_Praktikant__c.isAccessible()) {
                throw new AuraHandledException('You do not have permission to view Praktikant records.');
            }
            
            // Verify field access
            Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Stundenerfassung_Praktikant__c.fields.getMap();
            List<String> fieldsToCheck = new List<String>{
                'Name_Anzeige__c', 
                'Name_Link__c', 
                'Taetigkeit__c', 
                'AnwesendheitStatus__c'
            };
            
            for (String fieldName : fieldsToCheck) {
                if (fieldMap.containsKey(fieldName) && !fieldMap.get(fieldName).getDescribe().isAccessible()) {
                    throw new AuraHandledException('You do not have permission to access field: ' + fieldName);
                }
            }
            
            // Query praktikant records
            List<Stundenerfassung_Praktikant__c> records = [
                SELECT Id, 
                       Name, 
                       Name_Anzeige__c, 
                       Name_Link__c, 
                       Taetigkeit__c, 
                       AnwesendheitStatus__c,
                       CreatedDate,
                       LastModifiedDate
                FROM Stundenerfassung_Praktikant__c
                ORDER BY Name_Anzeige__c ASC NULLS LAST
            ];
            
            return records;
            
        } catch (Exception e) {
            System.debug('Error in getPraktikantRecords: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving Praktikant records: ' + e.getMessage());
        }
    }
    
    /**
     * Updates the attendance status of a Praktikant record
     * @param recordId The ID of the record to update
     * @param newStatus The new attendance status
     * @param reason The reason for the status change (required for Entschuldigt)
     * @return String Success message
     */
    @AuraEnabled
    public static String updatePraktikantStatus(String recordId, String newStatus, String reason) {
        try {
            // Validate input parameters
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID cannot be empty.');
            }
            
            if (String.isBlank(newStatus)) {
                throw new AuraHandledException('New status cannot be empty.');
            }
            
            // Validate status values
            List<String> validStatuses = new List<String>{'Unentschuldigt', 'Anwesend', 'Entschuldigt'};
            if (!validStatuses.contains(newStatus)) {
                throw new AuraHandledException('Invalid status value: ' + newStatus);
            }
            
            // If status is Entschuldigt, reason is required
            if (newStatus == 'Entschuldigt' && String.isBlank(reason)) {
                throw new AuraHandledException('Reason is required when marking as Entschuldigt.');
            }
            
            // Check object and field permissions
            if (!Schema.sObjectType.Stundenerfassung_Praktikant__c.isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update Praktikant records.');
            }
            
            Schema.SObjectField statusField = Schema.sObjectType.Stundenerfassung_Praktikant__c.fields.AnwesendheitStatus__c;
            if (!statusField.getDescribe().isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update the attendance status field.');
            }
            
            // Query the record to update
            List<Stundenerfassung_Praktikant__c> recordsToUpdate = [
                SELECT Id, AnwesendheitStatus__c, Name_Anzeige__c
                FROM Stundenerfassung_Praktikant__c 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            
            if (recordsToUpdate.isEmpty()) {
                throw new AuraHandledException('Praktikant record not found with ID: ' + recordId);
            }
            
            Stundenerfassung_Praktikant__c recordToUpdate = recordsToUpdate[0];
            String oldStatus = recordToUpdate.AnwesendheitStatus__c;
            
            // Update the status
            recordToUpdate.AnwesendheitStatus__c = newStatus;
            
            // If there's a custom field for storing reason, update it here
            // Note: You may need to create a custom field like 'Entschuldigt_Grund__c' if it doesn't exist
            // recordToUpdate.Entschuldigt_Grund__c = (newStatus == 'Entschuldigt') ? reason : null;
            
            // Perform the update
            update recordToUpdate;
            
            // Log the status change for audit purposes
            System.debug('Status updated for ' + recordToUpdate.Name_Anzeige__c + 
                        ' from ' + oldStatus + ' to ' + newStatus + 
                        (String.isNotBlank(reason) ? ' with reason: ' + reason : ''));
            
            // Create a success message
            String successMessage = 'Status successfully updated to ' + newStatus;
            if (String.isNotBlank(reason)) {
                successMessage += ' with reason: ' + reason;
            }
            
            return successMessage;
            
        } catch (DmlException e) {
            System.debug('DML Error in updatePraktikantStatus: ' + e.getMessage());
            throw new AuraHandledException('Database error while updating status: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            System.debug('Error in updatePraktikantStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating Praktikant status: ' + e.getMessage());
        }
    }
    
    /**
     * Retrieves picklist values for AnwesendheitStatus__c field
     * @return List<String> List of picklist values
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAnwesendheitStatusOptions() {
        try {
            List<String> picklistValues = new List<String>();
            
            Schema.DescribeFieldResult fieldDescribe = Schema.sObjectType.Stundenerfassung_Praktikant__c.fields.AnwesendheitStatus__c.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.isActive()) {
                    picklistValues.add(entry.getValue());
                }
            }
            
            return picklistValues;
            
        } catch (Exception e) {
            System.debug('Error in getAnwesendheitStatusOptions: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving status options: ' + e.getMessage());
        }
    }
    
    /**
     * Bulk update method for multiple records (optional enhancement)
     * @param updates List of records to update with their new status
     * @return String Success message with count of updated records
     */
    @AuraEnabled
    public static String bulkUpdatePraktikantStatus(List<PraktikantStatusUpdate> updates) {
        try {
            if (updates == null || updates.isEmpty()) {
                throw new AuraHandledException('No updates provided.');
            }
            
            List<Stundenerfassung_Praktikant__c> recordsToUpdate = new List<Stundenerfassung_Praktikant__c>();
            Set<Id> recordIds = new Set<Id>();
            
            // Collect record IDs
            for (PraktikantStatusUpdate update : updates) {
                recordIds.add(update.recordId);
            }
            
            // Query existing records
            Map<Id, Stundenerfassung_Praktikant__c> existingRecords = new Map<Id, Stundenerfassung_Praktikant__c>([
                SELECT Id, AnwesendheitStatus__c
                FROM Stundenerfassung_Praktikant__c
                WHERE Id IN :recordIds
            ]);
            
            // Prepare updates
            for (PraktikantStatusUpdate update : updates) {
                if (existingRecords.containsKey(update.recordId)) {
                    Stundenerfassung_Praktikant__c record = existingRecords.get(update.recordId);
                    record.AnwesendheitStatus__c = update.newStatus;
                    recordsToUpdate.add(record);
                }
            }
            
            // Perform bulk update
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
            
            return 'Successfully updated ' + recordsToUpdate.size() + ' records.';
            
        } catch (Exception e) {
            System.debug('Error in bulkUpdatePraktikantStatus: ' + e.getMessage());
            throw new AuraHandledException('Error in bulk update: ' + e.getMessage());
        }
    }
    
    /**
     * Wrapper class for bulk update operations
     */
    public class PraktikantStatusUpdate {
        @AuraEnabled
        public Id recordId { get; set; }
        
        @AuraEnabled
        public String newStatus { get; set; }
        
        @AuraEnabled
        public String reason { get; set; }
    }
}